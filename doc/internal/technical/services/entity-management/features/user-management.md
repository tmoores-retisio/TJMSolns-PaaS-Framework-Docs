# Feature: User Management

**Feature ID**: EMS-F003  
**Status**: Planned  
**Priority**: Critical (P0)  
**Seam Levels**: Seam 1 (Tenant), Seam 4 (Tenant-Service-Role)

## Overview

User Management enables tenant administrators to create, update, and deactivate users within their tenant, assign them to organizations, and manage their roles for access control.

## Business Context

**Problem**: Tenants need to control which individuals can access the system and what permissions they have.

**Solution**: Comprehensive user lifecycle management with tenant isolation, role-based access control, and organization assignment.

**Value**: Provides fine-grained access control; supports organizational structure; maintains security through proper permissions.

## User Stories

**US-007**: As a tenant admin, I want to create users in my tenant so that team members can access the system.

**US-008**: As a tenant admin, I want to assign users to organizations so that permissions align with company structure.

**US-009**: As a tenant admin, I want to manage user roles so that I can control access levels.

**US-010**: As a user, I want to see only users from my tenant so that tenant isolation is maintained.

## Functional Requirements

### Command: CreateUser

**Input**:
```json
{
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "john.doe@acme.example.com",
  "name": "John Doe",
  "role": "tenant-user",
  "organization_id": "770e8400-e29b-41d4-a716-446655440000"
}
```

**Output** (Success):
```json
{
  "user_id": "880e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "john.doe@acme.example.com",
  "name": "John Doe",
  "role": "tenant-user",
  "organization_id": "770e8400-e29b-41d4-a716-446655440000",
  "status": "active",
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Business Rules**:
- BR-011: Email must be unique within tenant
- BR-012: Email must be valid format
- BR-013: Role must be one of: tenant-owner, tenant-admin, tenant-user, tenant-readonly
- BR-014: Organization must exist and belong to same tenant
- BR-015: User status defaults to "active"

### Command: UpdateUserRole

**Input**:
```json
{
  "user_id": "880e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "new_role": "tenant-admin"
}
```

**Authorization**: Requires tenant-admin or tenant-owner role

### Command: DeactivateUser

**Input**: user_id, tenant_id

**Effect**: Sets status to "inactive", revokes authentication

### Query: ListUsers

**Filters**:
- organization_id (optional)
- role (optional)
- status (optional)

**Output**: Paginated list of users (tenant-filtered)

### Events Published

**UserCreated**:
```json
{
  "event_type": "user.created",
  "tenant_id": "550e8400...",
  "data": {
    "user_id": "880e8400...",
    "email": "john.doe@acme.example.com",
    "role": "tenant-user",
    "organization_id": "770e8400..."
  }
}
```

**UserRoleChanged**:
```json
{
  "event_type": "user.role_changed",
  "tenant_id": "550e8400...",
  "data": {
    "user_id": "880e8400...",
    "old_role": "tenant-user",
    "new_role": "tenant-admin"
  }
}
```

**UserDeactivated**:
```json
{
  "event_type": "user.deactivated",
  "tenant_id": "550e8400...",
  "data": {
    "user_id": "880e8400...",
    "reason": "employee_departure"
  }
}
```

## Multi-Tenant Considerations

**Seam Level 1 (Tenant)**:
- All users scoped to tenant_id
- Cross-tenant queries blocked (return 404)
- Email uniqueness enforced per tenant (not globally)

**Seam Level 4 (Tenant-Service-Role)**:
- tenant-owner: Full user management
- tenant-admin: Create/update users (cannot modify owner)
- tenant-user: Read-only access to users in same organization
- tenant-readonly: Read-only access to all users

**Isolation**:
- Database queries filtered by tenant_id
- Actor validation checks tenant ownership
- JWT tenant_id must match X-Tenant-ID header

## Non-Functional Requirements

- **Performance**: User creation <100ms P95
- **Scalability**: Support 10,000+ users per tenant
- **Security**: Email validation, duplicate prevention
- **Audit**: All user changes logged

## Architecture

**Actor Design**:
```scala
object UserActor {
  sealed trait Command
  case class CreateUser(
    tenantId: UUID,
    email: String,
    name: String,
    role: UserRole,
    orgId: UUID,
    replyTo: ActorRef[Response]
  ) extends Command
  
  case class UpdateRole(
    tenantId: UUID,
    newRole: UserRole,
    replyTo: ActorRef[Response]
  ) extends Command
  
  sealed trait Event
  case class UserCreated(
    userId: UUID,
    tenantId: UUID,
    email: String,
    role: UserRole
  ) extends Event
  
  case class State(
    userId: UUID,
    tenantId: UUID,
    email: String,
    name: String,
    role: UserRole,
    organizationId: UUID,
    status: UserStatus
  )
}
```

**Role Hierarchy**:
```
tenant-owner    (highest)
  └─ tenant-admin
      └─ tenant-user
          └─ tenant-readonly  (lowest)
```

## Testing Strategy

See companion `user-management.feature` file for BDD scenarios.

**Test Coverage**:
- ✅ Create, update, deactivate users
- ✅ Role changes with authorization
- ✅ Cross-tenant isolation
- ✅ Duplicate email prevention
- ✅ Organization assignment
- ✅ Permission enforcement

## Dependencies

- Authentication Service: Credentials creation
- PostgreSQL: User storage
- Kafka: Event publishing

## Metrics

- `users_created_total` (counter, label: tenant_id) - Users created
- `user_role_changes_total` (counter, labels: tenant_id, old_role, new_role)
- `users_active_total` (gauge, label: tenant_id) - Active user count

## Acceptance Criteria

- [ ] Users can be created via POST /api/v1/users
- [ ] Email uniqueness enforced per tenant
- [ ] Roles validated against allowed values
- [ ] Cross-tenant queries blocked (404)
- [ ] Role changes require tenant-admin permission
- [ ] UserCreated events published to Kafka
- [ ] All BDD scenarios passing
