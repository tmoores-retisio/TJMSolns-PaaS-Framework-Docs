# Feature: Organization Hierarchy Management

**Feature ID**: EMS-F002  
**Status**: Planned  
**Priority**: High (P1)  
**Seam Levels**: Seam 1 (Tenant), Seam 4 (Tenant-Service-Role)

## Overview

Organization Hierarchy Management allows tenants to model their company structure as a tree of organizations with parent-child relationships, enabling permission delegation and resource grouping.

## Business Context

**Problem**: Companies have hierarchical structures (departments, teams) that need to be modeled in the system for access control and resource organization.

**Solution**: Tree-based organization hierarchy within each tenant, supporting arbitrary depth with cycle prevention.

**Value**: Enables realistic modeling of company structure; supports delegated administration; provides flexible grouping for permissions and resources.

## User Stories

**US-004**: As a tenant admin, I want to create organizations in a hierarchy so that I can model my company structure.

**US-005**: As a tenant admin, I want to prevent circular hierarchies so that the organization tree remains valid.

**US-006**: As a user, I want to see only organizations from my tenant so that tenant isolation is maintained.

## Functional Requirements

### Command: CreateOrganization

**Input**:
```json
{
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Engineering Department",
  "description": "Technical team",
  "parent_id": "770e8400-e29b-41d4-a716-446655440000"
}
```

**Output** (Success):
```json
{
  "organization_id": "880e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Engineering Department",
  "description": "Technical team",
  "parent_id": "770e8400-e29b-41d4-a716-446655440000",
  "hierarchy_depth": 1,
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Business Rules**:
- BR-006: Organization name must be unique within tenant
- BR-007: Parent organization must exist and belong to same tenant
- BR-008: Hierarchy must remain acyclic (no circular references)
- BR-009: Maximum hierarchy depth is 10 levels
- BR-010: Root organizations have parent_id = null

### Query: GetOrganizationHierarchy

**Input**: Root organization_id

**Output**: Complete tree structure from root

### Command: DeleteOrganization

**Behavior**: Cascade deletion to all child organizations

### Events Published

**OrganizationCreated**:
```json
{
  "event_type": "organization.created",
  "tenant_id": "550e8400...",
  "data": {
    "organization_id": "880e8400...",
    "name": "Engineering Department",
    "parent_id": "770e8400..."
  }
}
```

**OrganizationDeleted**:
```json
{
  "event_type": "organization.deleted",
  "tenant_id": "550e8400...",
  "data": {
    "organization_id": "880e8400...",
    "cascade_deleted": ["990e8400...", "aa0e8400..."]
  }
}
```

## Multi-Tenant Considerations

**Seam Level 1 (Tenant)**:
- All organizations scoped to tenant_id
- Cross-tenant queries blocked (return 404)
- Organization IDs globally unique but tenant-scoped access

**Seam Level 4 (Tenant-Service-Role)**:
- tenant-admin: Can manage all organizations in tenant
- org-admin: Can manage specific organization and children
- org-member: Read-only access to organization

**Isolation**:
- Database queries filtered by tenant_id
- Actor validation checks tenant ownership
- Events include tenant_id for filtering

## Non-Functional Requirements

- **Performance**: Organization creation <100ms P95
- **Scalability**: Support up to 10,000 organizations per tenant
- **Consistency**: Hierarchy validation atomic with creation
- **Availability**: 99.9% uptime

## Architecture

**Actor Design**:
```scala
object OrganizationActor {
  sealed trait Command
  case class CreateOrganization(
    tenantId: UUID,
    name: String,
    parentId: Option[UUID],
    replyTo: ActorRef[Response]
  ) extends Command
  
  sealed trait Event
  case class OrganizationCreated(
    orgId: UUID,
    tenantId: UUID,
    name: String,
    parentId: Option[UUID]
  ) extends Event
  
  // State includes hierarchy validation
  case class State(
    orgId: UUID,
    tenantId: UUID,
    name: String,
    parentId: Option[UUID],
    childIds: Set[UUID]
  )
}
```

**Hierarchy Validation**:
```scala
def validateHierarchy(
  newParentId: UUID,
  currentOrgId: UUID,
  repository: OrgRepository
): Either[ValidationError, Unit] = {
  // Walk up tree to ensure currentOrgId not in ancestors
  def isAncestor(candidateId: UUID, searchId: UUID): Boolean = {
    if (candidateId == searchId) true
    else {
      repository.getParent(candidateId) match {
        case Some(parentId) => isAncestor(parentId, searchId)
        case None => false
      }
    }
  }
  
  if (isAncestor(newParentId, currentOrgId)) {
    Left(CircularHierarchyError)
  } else {
    Right(())
  }
}
```

## Testing Strategy

See companion `organization-hierarchy.feature` file for BDD scenarios.

**Test Coverage**:
- ✅ Create root and child organizations
- ✅ Circular hierarchy prevention
- ✅ Cascade deletion
- ✅ Cross-tenant isolation
- ✅ Hierarchy traversal queries
- ✅ Max depth validation

## Dependencies

- PostgreSQL: Store organization tree
- Kafka: Event publishing

## Metrics

- `organizations_created_total` (counter) - Organizations created
- `organization_hierarchy_depth` (histogram) - Tree depth distribution
- `organization_query_duration_seconds` (histogram) - Query latency

## Acceptance Criteria

- [ ] Organizations can be created with parent-child relationships
- [ ] Circular hierarchies prevented
- [ ] Cascade deletion working
- [ ] Cross-tenant queries blocked (404 returned)
- [ ] Hierarchy queries perform well (<100ms P95)
- [ ] All BDD scenarios passing
