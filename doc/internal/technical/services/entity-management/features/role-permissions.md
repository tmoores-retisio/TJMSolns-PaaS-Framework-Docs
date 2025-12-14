# Feature: Role-Based Permissions

**Feature ID**: EMS-F004  
**Status**: Planned  
**Priority**: High (P1)  
**Seam Levels**: Seam 4 (Tenant-Service-Role)

## Overview

Role-Based Permissions enables tenant administrators to define custom roles with specific permission sets, assign roles to users, and enforce fine-grained access control throughout the system.

## Business Context

**Problem**: Default roles (tenant-owner, tenant-admin, tenant-user) are too coarse-grained for many organizations' access control needs.

**Solution**: Custom role creation with granular permissions following the pattern `service:action:scope`, enabling flexible RBAC tailored to organizational needs.

**Value**: Provides flexible access control; reduces over-privileged users; supports compliance requirements.

## User Stories

**US-011**: As a tenant admin, I want to create custom roles so that I can implement organization-specific access control.

**US-012**: As a tenant admin, I want to assign granular permissions to roles so that users have exactly the access they need.

**US-013**: As a system, I want to enforce permissions at runtime so that unauthorized actions are prevented.

## Functional Requirements

### Command: CreateRole

**Input**:
```json
{
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Project Manager",
  "description": "Manages projects and teams",
  "permissions": [
    "entity-management:read:*",
    "entity-management:write:own",
    "entity-management:approve:projects"
  ],
  "inherits_from": null
}
```

**Output** (Success):
```json
{
  "role_id": "990e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Project Manager",
  "description": "Manages projects and teams",
  "permissions": [
    "entity-management:read:*",
    "entity-management:write:own",
    "entity-management:approve:projects"
  ],
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Business Rules**:
- BR-016: Role name must be unique within tenant
- BR-017: Permissions must follow format: `service:action:scope`
- BR-018: Permission service must be valid (e.g., entity-management)
- BR-019: Permission action must be valid (read, write, delete, approve, admin)
- BR-020: Permission scope must be: `*`, `own`, or specific resource type

### Permission Format

**Structure**: `service:action:scope`

**Examples**:
- `entity-management:read:*` - Read any entity
- `entity-management:write:own` - Write entities owned by user
- `entity-management:delete:tenants` - Delete tenant entities specifically
- `entity-management:admin:*` - Full admin access

**Scope Semantics**:
- `*`: All resources of this type
- `own`: Resources owned/created by the user
- `{resource_type}`: Specific resource type (tenants, organizations, users)

### Command: AssignRoleToUser

**Input**:
```json
{
  "user_id": "880e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "role_id": "990e8400-e29b-41d4-a716-446655440000"
}
```

**Effect**: User inherits all permissions from role

### Permission Enforcement (Runtime)

**Check Algorithm**:
```scala
def hasPermission(user: User, requiredPermission: Permission): Boolean = {
  val userPermissions = user.roles.flatMap(_.permissions)
  
  userPermissions.exists { userPerm =>
    matchesPermission(userPerm, requiredPermission)
  }
}

def matchesPermission(userPerm: Permission, required: Permission): Boolean = {
  val userParts = userPerm.split(":")
  val reqParts = required.split(":")
  
  // Service must match
  if (userParts(0) != reqParts(0)) return false
  
  // Action must match
  if (userParts(1) != reqParts(1) && userParts(1) != "*") return false
  
  // Scope: * matches all, specific must match
  userParts(2) == "*" || userParts(2) == reqParts(2)
}
```

**Example Enforcement**:
```scala
// In API route
path("entities" / JavaUUID) { entityId =>
  delete {
    requirePermission("entity-management:delete:*") { authContext =>
      // Check ownership if scope is "own"
      if (needsOwnershipCheck(authContext)) {
        checkOwnership(entityId, authContext.userId) match {
          case true => complete(deleteEntity(entityId))
          case false => complete(StatusCodes.Forbidden)
        }
      } else {
        complete(deleteEntity(entityId))
      }
    }
  }
}
```

### Events Published

**RoleCreated**:
```json
{
  "event_type": "role.created",
  "tenant_id": "550e8400...",
  "data": {
    "role_id": "990e8400...",
    "name": "Project Manager",
    "permissions": ["entity-management:read:*", ...]
  }
}
```

**UserRoleAssigned**:
```json
{
  "event_type": "user.role_assigned",
  "tenant_id": "550e8400...",
  "data": {
    "user_id": "880e8400...",
    "role_id": "990e8400..."
  }
}
```

## Multi-Tenant Considerations

**Seam Level 4 (Tenant-Service-Role)**:
- All roles scoped to tenant_id
- Cross-tenant queries blocked
- Permissions only apply within tenant boundary

**Isolation**:
- Roles cannot grant cross-tenant permissions
- Permission checks include tenant_id validation
- Custom roles only visible within tenant

## Non-Functional Requirements

- **Performance**: Permission check <1ms (in-memory)
- **Scalability**: Support 1,000+ custom roles per tenant
- **Security**: Permission validation before every protected operation
- **Audit**: All role changes and assignments logged

## Architecture

**Actor Design**:
```scala
object RoleActor {
  sealed trait Command
  case class CreateRole(
    tenantId: UUID,
    name: String,
    permissions: Set[Permission],
    replyTo: ActorRef[Response]
  ) extends Command
  
  sealed trait Event
  case class RoleCreated(
    roleId: UUID,
    tenantId: UUID,
    name: String,
    permissions: Set[Permission]
  ) extends Event
  
  case class State(
    roleId: UUID,
    tenantId: UUID,
    name: String,
    permissions: Set[Permission],
    assignedUserCount: Int
  )
}
```

**Permission Caching**:
```scala
// Cache user permissions in memory for fast checks
class PermissionCache {
  private val cache: Cache[UUID, Set[Permission]] = 
    CacheBuilder.newBuilder()
      .expireAfterWrite(5, TimeUnit.MINUTES)
      .build()
  
  def getUserPermissions(userId: UUID): Set[Permission] = {
    cache.get(userId, () => loadUserPermissions(userId))
  }
}
```

## Testing Strategy

See companion `role-permissions.feature` file for BDD scenarios.

**Test Coverage**:
- ✅ Create custom roles with permissions
- ✅ Assign roles to users
- ✅ Permission enforcement (allow/deny)
- ✅ Scope validation (*, own, specific)
- ✅ Cross-tenant isolation
- ✅ Role deletion with user checks

## Dependencies

- PostgreSQL: Role and permission storage
- Kafka: Event publishing
- Redis: Permission caching (optional)

## Metrics

- `roles_created_total` (counter, label: tenant_id)
- `permission_checks_total` (counter, labels: tenant_id, result=[allowed|denied])
- `permission_check_duration_seconds` (histogram)

## Acceptance Criteria

- [ ] Custom roles can be created via POST /api/v1/roles
- [ ] Permissions follow service:action:scope format
- [ ] Role assignment via POST /api/v1/users/{id}/roles
- [ ] Permission checks enforced at runtime (<1ms)
- [ ] Cross-tenant isolation maintained
- [ ] RoleCreated and UserRoleAssigned events published
- [ ] All BDD scenarios passing
