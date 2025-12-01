# Entity Management Service Charter

**Status**: Active  
**Service Name**: Entity Management Service  
**Service ID**: entity-management-service  
**Version**: 1.0.0  
**Last Updated**: 2025-11-29

---

## Mission Statement

Enable tenants to organize and manage their hierarchical business entities (organizations, teams, users) with flexible role-based access control, providing the foundation for multi-tenant SaaS applications.

## Problem Statement

Multi-tenant SaaS platforms require a standardized way to:
- Model tenant organizational structures (organizations, departments, teams)
- Manage user membership and roles within tenant contexts
- Enforce tenant-scoped permissions across all services
- Support both simple (single organization) and complex (multi-org) tenant structures
- Provide audit trails for all entity changes

**Current State**: No centralized entity management - each service implements its own user/org logic (duplication, inconsistency).

**Desired State**: Unified entity management service providing tenant organization modeling, user membership, role assignment, and permission evaluation as a platform capability.

## Value Proposition

### For Tenants
- **Organizational Flexibility**: Model business structure (orgs → teams → users)
- **Access Control**: Role-based permissions at org/team level
- **User Management**: Invite users, assign roles, manage membership
- **Audit Trail**: Complete history of who did what when

### For Platform
- **DRY Principle**: Single implementation of entity/role logic
- **Consistency**: All services use same entity model
- **Scalability**: Horizontal scaling via actor sharding
- **Multi-Tenancy**: Built-in tenant isolation at all layers

### For Developers
- **Standard API**: REST endpoints + Kafka events for entity changes
- **Simple Integration**: Subscribe to entity events (UserInvited, RoleAssigned)
- **Well-Documented**: Complete API spec, examples, runbooks

## Scope

### In Scope

**Core Entities**:
- **Tenant**: Top-level isolation boundary (subscription, settings)
- **Organization**: Logical grouping within tenant (departments, business units)
- **Team**: Collaboration group within organization
- **User**: Individual user account (email, profile)
- **Role**: Named permission set (tenant-admin, org-admin, team-member)
- **Permission**: Granular capability (entity:action:scope)

**Core Operations**:
- Create/Read/Update/Delete for all entities
- User invitation and onboarding flow
- Role assignment (user-to-role mapping at tenant/org/team level)
- Permission evaluation (does user have permission?)
- Organization hierarchy management (parent-child relationships)
- Membership management (add/remove users from orgs/teams)

**Events Published**:
- TenantCreated, TenantUpdated, TenantDeleted
- OrganizationCreated, OrganizationUpdated, OrganizationDeleted
- TeamCreated, TeamUpdated, TeamDeleted
- UserInvited, UserActivated, UserDeactivated
- RoleAssigned, RoleRevoked
- MembershipAdded, MembershipRemoved

### Out of Scope

- Authentication (delegated to Identity Provider / Auth Service)
- Authorization enforcement in other services (they consume our events/API)
- Billing/subscription management (Provisioning Service responsibility)
- Feature flags (separate Feature Flag Service)
- User profile management beyond basic fields (separate Profile Service)

### Future Considerations

- Custom role builder (beyond predefined roles)
- Attribute-based access control (ABAC) beyond RBAC
- Organizational hierarchy limits (prevent infinite depth)
- Bulk operations (import 1000 users at once)
- Integration with SSO providers (SAML, OAuth)

## Strategic Alignment

### TJMPaaS Alignment

**Multi-Tenant Seam Architecture** (from MULTI-TENANT-SEAM-ARCHITECTURE.md):
- **Seam 1 (Tenant)**: Service enforces tenant isolation (all queries filtered by tenant_id)
- **Seam 2 (Tenant-Service)**: Service-level entitlements (organization features per tenant)
- **Seam 3 (Tenant-Service-Feature)**: Feature-level capabilities (team management enabled per tenant)
- **Seam 4 (Tenant-Service-Role)**: Role-based permissions (tenant-admin vs org-admin vs team-member)

**Provisioning Service Pattern** (from PROVISIONING-SERVICE-PATTERN.md):
- Entity Management is provisioned as a "Service Entitlement" for each tenant
- Provisioning Service creates initial tenant + default organization + admin user
- Entity Management maintains entity state, publishes events

**Reactive Manifesto** (ADR-0005):
- **Responsive**: <200ms P95 for queries, <500ms P95 for commands
- **Resilient**: Actor supervision, circuit breakers for external dependencies
- **Elastic**: Horizontal scaling via actor sharding by tenant_id
- **Message-Driven**: Commands processed by actors, events published to Kafka

### Business Goals

1. **Reduce Development Time**: 50% reduction in time to add new service (no entity logic duplication)
2. **Improve Consistency**: 100% of services use standard entity model
3. **Enable Self-Service**: Tenants manage own org structure without support tickets
4. **Support Growth**: Handle 10,000+ tenants with sub-second query latency

## Success Metrics

### Functional Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| API Response Time (P95) | <200ms | Prometheus histogram |
| Command Processing (P95) | <500ms | Prometheus histogram |
| Event Publishing Latency | <100ms | Kafka lag metric |
| Multi-Tenant Isolation | 100% (zero leaks) | Automated tests |
| Uptime | 99.9% | Health check monitoring |

### Business Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Tenant Adoption | 90% of tenants create ≥1 org | Usage tracking |
| User Invitations | 80% accepted within 7 days | Invitation funnel |
| Support Tickets (entity mgmt) | <5 per month | Ticket system |
| Developer Satisfaction | 8/10 rating | Survey |

### Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Actor Restart Rate | <1 per hour | Pekko metrics |
| Database Query Performance | <50ms P95 | Query logs |
| Event Delivery Success | >99.9% | Kafka metrics |
| Code Coverage | >80% | CI pipeline |

## Technology Stack

**Language**: Scala 3.3.x  
**Build Tool**: Mill  
**Runtime**: OpenJDK 21 (LTS)  
**Actor System**: Pekko (Apache 2.0)  
**Effect System**: ZIO 2.x  
**HTTP Framework**: ZIO HTTP  
**Event Sourcing**: Pekko Persistence  
**Database**: PostgreSQL 15 (event journal + read models)  
**Message Broker**: Apache Kafka  
**Serialization**: JSON (circe) + Protobuf (events)

**Rationale**: Aligns with ADR-0004 (Scala 3 stack), ADR-0006 (Pekko actors), ADR-0007 (CQRS/Event Sourcing).

## Architecture Principles

### CQRS Level 3 (Full Event Sourcing)

**Why Level 3**: Entity management requires complete audit trail for compliance.

**Command Side**:
- Actors process commands (CreateTenant, InviteUser, AssignRole)
- Events persisted to event store (TenantCreated, UserInvited, RoleAssigned)
- Actor state rebuilt from event replay

**Query Side**:
- Read models projected from event streams
- Optimized for queries (denormalized views)
- Eventually consistent (typically <1 second lag)

### Multi-Tenant Isolation

**All 4 Seam Levels Enforced**:

1. **Seam 1 (Tenant)**: 
   - X-Tenant-ID header required
   - JWT tenant_id claim validated
   - All queries filtered: `WHERE tenant_id = ?`

2. **Seam 2 (Tenant-Service)**:
   - Organization feature enabled per tenant subscription plan
   - Team feature enabled for Silver/Gold tiers only

3. **Seam 3 (Tenant-Service-Feature)**:
   - User invitations: 10/month (Bronze), 100/month (Silver), unlimited (Gold)
   - Organization count: 1 (Bronze), 10 (Silver), unlimited (Gold)

4. **Seam 4 (Tenant-Service-Role)**:
   - tenant-owner: Full tenant access
   - tenant-admin: Manage users/orgs (not billing)
   - org-admin: Manage teams/users within organization
   - team-member: Read-only access to team

### Actor Model

**Entity Actors** (one per entity instance):
- `TenantActor(tenantId)`: Manages tenant state
- `OrganizationActor(orgId)`: Manages organization state
- `TeamActor(teamId)`: Manages team state
- `UserActor(userId)`: Manages user state

**Sharding**: Actors sharded by `tenant_id` for horizontal scaling.

**Supervision**: AllForOne strategy at service level, OneForOne for entity actors.

### API Design

**REST API** (HATEOAS Level 2):
- OpenAPI 3.1 specification
- Hypermedia links in responses
- Standard error format
- Rate limiting by tenant SLA tier

**Events** (CloudEvents format):
- Published to Kafka `entity-events` topic
- Partitioned by `tenant_id`
- Consumed by other services for integration

## Governance References

**Architectural Decisions**:
- [ADR-0004: Scala 3 Technology Stack](../../governance/ADRs/ADR-0004-scala3-technology-stack.md)
- [ADR-0005: Reactive Manifesto Alignment](../../governance/ADRs/ADR-0005-reactive-manifesto-alignment.md)
- [ADR-0006: Agent-Based Service Patterns](../../governance/ADRs/ADR-0006-agent-patterns.md)
- [ADR-0007: CQRS and Event-Driven Architecture](../../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md)

**Process Decisions**:
- [PDR-0004: Repository Organization Strategy](../../governance/PDRs/PDR-0004-repository-organization.md)
- [PDR-0005: Framework Selection Policy](../../governance/PDRs/PDR-0005-framework-selection-policy.md)
- [PDR-0006: Service Canvas Documentation Standard](../../governance/PDRs/PDR-0006-service-canvas-standard.md)

**Standards**:
- [POL-cross-service-consistency](../../governance/POLs/POL-cross-service-consistency.md)
- [MULTI-TENANT-SEAM-ARCHITECTURE](../../standards/MULTI-TENANT-SEAM-ARCHITECTURE.md)
- [PROVISIONING-SERVICE-PATTERN](../../standards/PROVISIONING-SERVICE-PATTERN.md)
- [API-DESIGN-STANDARDS](../../standards/API-DESIGN-STANDARDS.md)
- [EVENT-SCHEMA-STANDARDS](../../standards/EVENT-SCHEMA-STANDARDS.md)

## Stakeholders

**Service Owner**: Platform Team  
**Primary Consumers**: All TJMPaaS services requiring entity/role information  
**Key Dependencies**: Provisioning Service (tenant creation), Auth Service (JWT validation)

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Cross-tenant data leakage | Critical | Low | Multi-layer validation, automated isolation tests |
| Actor mailbox overflow | High | Medium | Backpressure, rate limiting, mailbox monitoring |
| Event ordering issues | Medium | Low | Kafka partition by tenant_id, idempotent consumers |
| Database performance | High | Medium | Read model optimization, connection pooling, caching |
| Complex org hierarchies | Medium | Low | Depth limits (max 5 levels), cycle detection |

## Versioning and Compatibility

**API Versioning**: `/api/v1/entities/...`  
**Event Schema Versioning**: CloudEvents `datacontenttype` includes version  
**Backward Compatibility**: 1 major version overlap supported  
**Deprecation Policy**: 6-month notice for breaking changes

## Compliance and Security

**Data Protection**:
- Email addresses encrypted at rest (AES-256)
- All API calls require authentication (JWT)
- Audit logging for all entity changes (7-year retention)

**Regulatory**:
- GDPR: Right to erasure (soft delete with anonymization)
- SOC2: Access controls, audit logging, encryption

## Related Documentation

- [SERVICE-CANVAS.md](./SERVICE-CANVAS.md) - Comprehensive service overview
- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Detailed technical architecture
- [API-SPECIFICATION.md](./API-SPECIFICATION.md) - Complete API documentation
- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) - Deployment procedures
- [TELEMETRY-SPECIFICATION.md](./TELEMETRY-SPECIFICATION.md) - Observability setup

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-29 | Initial charter | Platform Team |
