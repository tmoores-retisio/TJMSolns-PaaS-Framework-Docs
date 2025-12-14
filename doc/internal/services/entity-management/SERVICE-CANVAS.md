# Entity Management Service Canvas

**Status**: Active  
**Version**: 1.0.0  
**Last Updated**: 2025-11-29  
**Governance**: [PDR-0006: Service Canvas Documentation Standard](../../governance/PDRs/PDR-0006-service-canvas-standard.md)

---

## Service Identity

**Service Name**: Entity Management Service  
**Service ID**: `entity-management-service`  
**Repository**: `TJMSolns-EntityManagementService`  
**Owner**: Platform Team  
**Status**: Design Phase  
**Target Go-Live**: Q2 2026

### Mission

Enable tenants to organize and manage their hierarchical business entities (organizations, teams, users) with flexible role-based access control.

### Value Proposition

**For Tenants**: Self-service organization management with flexible RBAC.  
**For Platform**: DRY principle - single entity/role implementation for all services.  
**For Developers**: Standard API + events for entity information.

### Technology Stack

- **Language**: Scala 3.3.x
- **Build**: Mill
- **Runtime**: OpenJDK 21
- **Actors**: Pekko (Apache 2.0)
- **Effects**: ZIO 2.x
- **HTTP**: ZIO HTTP
- **Persistence**: Pekko Persistence + PostgreSQL
- **Events**: Apache Kafka
- **Serialization**: JSON (circe) + Protobuf (events)

### Governance References

- [ADR-0004: Scala 3 Stack](../../governance/ADRs/ADR-0004-scala3-technology-stack.md)
- [ADR-0006: Actor Patterns](../../governance/ADRs/ADR-0006-agent-patterns.md)
- [ADR-0007: CQRS/Event-Driven](../../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md)
- [POL-cross-service-consistency](../../governance/POLs/POL-cross-service-consistency.md)

---

## Dependencies

### Service Dependencies

| Service | Purpose | Criticality | Fallback |
|---------|---------|-------------|----------|
| Provisioning Service | Tenant creation, initial setup | High | Fail tenant creation |
| Auth Service | JWT validation | Critical | Circuit breaker, cached keys |
| Notification Service | User invitation emails | Medium | Retry queue, async |

### External Dependencies

| System | Purpose | Criticality | Fallback |
|--------|---------|-------------|----------|
| PostgreSQL 15 | Event store + read models | Critical | Read-replica failover |
| Apache Kafka | Event publishing | High | Local queue, retry |
| Redis | Rate limiting, caching | Medium | Degraded (no caching) |

### Framework Dependencies

| Framework | Version | License | Purpose |
|-----------|---------|---------|---------|
| Pekko | 1.0.x | Apache 2.0 | Actor system, event sourcing |
| ZIO | 2.x | Apache 2.0 | Effect system, concurrency |
| ZIO HTTP | 3.x | Apache 2.0 | REST API server |
| Pekko Persistence | 1.0.x | Apache 2.0 | Event sourcing |
| circe | 0.14.x | Apache 2.0 | JSON serialization |
| Flyway | 9.x | Apache 2.0 | Database migrations |

---

## Architecture

### CQRS Level

**Level 3 (Full Event Sourcing)** - Complete audit trail required for compliance.

### Actors and Agents

| Actor | Responsibility | Sharding Key | Lifecycle |
|-------|---------------|--------------|-----------|
| TenantActor | Tenant state management | tenant_id | Persistent (event-sourced) |
| OrganizationActor | Organization state | org_id | Persistent (event-sourced) |
| TeamActor | Team state | team_id | Persistent (event-sourced) |
| UserActor | User state | user_id | Persistent (event-sourced) |

**Supervision Strategy**: OneForOne (entity actors independent).

### Message Protocols

**Command Messages** (API → Actor):
```scala
sealed trait Command
case class CreateTenant(id: UUID, name: String, plan: String) extends Command
case class CreateOrganization(id: UUID, tenantId: UUID, name: String) extends Command
case class InviteUser(userId: UUID, tenantId: UUID, email: String, role: String) extends Command
case class AssignRole(userId: UUID, role: String, scope: Scope) extends Command
```

**Event Messages** (Actor → Event Store → Kafka):
```scala
sealed trait Event
case class TenantCreated(id: UUID, name: String, plan: String, timestamp: Instant) extends Event
case class OrganizationCreated(id: UUID, tenantId: UUID, name: String, timestamp: Instant) extends Event
case class UserInvited(userId: UUID, tenantId: UUID, email: String, role: String, timestamp: Instant) extends Event
case class RoleAssigned(userId: UUID, role: String, scope: Scope, timestamp: Instant) extends Event
```

### Multi-Tenant Seam Enforcement

**Seam 1 (Tenant)**: All queries filtered by `tenant_id`, X-Tenant-ID header required.  
**Seam 2 (Tenant-Service)**: Organization feature per subscription plan.  
**Seam 3 (Tenant-Service-Feature)**: User invitations limited by tier (10/100/unlimited).  
**Seam 4 (Tenant-Service-Role)**: tenant-owner / tenant-admin / org-admin / team-member roles.

---

## API Contract (CQRS)

### Commands (Write Operations)

**Tenant Management**:
- `POST /api/v1/tenants` - Create tenant
- `PUT /api/v1/tenants/{tenantId}` - Update tenant
- `DELETE /api/v1/tenants/{tenantId}` - Delete tenant

**Organization Management**:
- `POST /api/v1/tenants/{tenantId}/organizations` - Create organization
- `PUT /api/v1/organizations/{orgId}` - Update organization
- `DELETE /api/v1/organizations/{orgId}` - Delete organization

**User Management**:
- `POST /api/v1/tenants/{tenantId}/users/invite` - Invite user
- `POST /api/v1/users/{userId}/activate` - Activate user
- `PUT /api/v1/users/{userId}` - Update user
- `DELETE /api/v1/users/{userId}` - Deactivate user

**Role Management**:
- `POST /api/v1/users/{userId}/roles` - Assign role
- `DELETE /api/v1/users/{userId}/roles/{roleId}` - Revoke role

### Queries (Read Operations)

**Tenant Queries**:
- `GET /api/v1/tenants/{tenantId}` - Get tenant details
- `GET /api/v1/tenants/{tenantId}/organizations` - List organizations
- `GET /api/v1/tenants/{tenantId}/users` - List users

**Organization Queries**:
- `GET /api/v1/organizations/{orgId}` - Get organization
- `GET /api/v1/organizations/{orgId}/teams` - List teams
- `GET /api/v1/organizations/{orgId}/members` - List members

**User Queries**:
- `GET /api/v1/users/{userId}` - Get user profile
- `GET /api/v1/users/{userId}/roles` - Get user roles
- `GET /api/v1/users/{userId}/permissions` - Get effective permissions

### Events (Integration)

**Published Events** (Kafka topic: `entity-events`):
- `com.tjmpaas.entity.TenantCreated.v1`
- `com.tjmpaas.entity.TenantUpdated.v1`
- `com.tjmpaas.entity.TenantDeleted.v1`
- `com.tjmpaas.entity.OrganizationCreated.v1`
- `com.tjmpaas.entity.OrganizationUpdated.v1`
- `com.tjmpaas.entity.OrganizationDeleted.v1`
- `com.tjmpaas.entity.UserInvited.v1`
- `com.tjmpaas.entity.UserActivated.v1`
- `com.tjmpaas.entity.UserDeactivated.v1`
- `com.tjmpaas.entity.RoleAssigned.v1`
- `com.tjmpaas.entity.RoleRevoked.v1`

**Event Schema**: CloudEvents format with tenant_id in metadata.

---

## Non-Functional Requirements

### Reactive Manifesto Alignment

- **Responsive**: Query P95 <200ms, Command P95 <500ms
- **Resilient**: Circuit breakers on external deps, actor supervision
- **Elastic**: Horizontal scaling via actor sharding by tenant_id
- **Message-Driven**: Actor commands, Kafka events, async boundaries

### SLOs by Tenant Tier

| Tier | Query Latency (P95) | Command Latency (P95) | Uptime |
|------|-------------------|---------------------|--------|
| Bronze | <500ms | <1s | 99% |
| Silver | <200ms | <500ms | 99.5% |
| Gold | <100ms | <300ms | 99.9% |

### Resource Limits

| Resource | Limit | Monitoring |
|----------|-------|------------|
| CPU | 2 cores per pod | Kubernetes metrics |
| Memory | 4 GB per pod | Heap usage alerts |
| Database Connections | 50 per pod | Connection pool gauge |
| Kafka Producers | 10 per pod | Producer metrics |

### Scaling Thresholds

- **Horizontal Pod Autoscaler**: CPU >70% → add pod (max 10 pods)
- **Actor Sharding**: Rebalance every 100 new actors
- **Database Read Replicas**: Query latency >200ms → add replica

---

## Observability

### Health Checks

- `GET /health/live` - Liveness (200 if process alive)
- `GET /health/ready` - Readiness (200 if accepting traffic, checks DB/Kafka)

### Metrics (Prometheus)

**Business Metrics**:
- `entity_tenants_total{tenant_id}` - Total tenants
- `entity_organizations_total{tenant_id}` - Organizations per tenant
- `entity_users_total{tenant_id}` - Users per tenant
- `entity_invitations_sent_total{tenant_id}` - User invitations sent

**Technical Metrics**:
- `http_request_duration_seconds{tenant_id, method, endpoint, status}`
- `http_requests_total{tenant_id, method, endpoint, status}`
- `entity_commands_processed_total{tenant_id, command_type, result}`
- `entity_events_published_total{tenant_id, event_type}`

**Actor Metrics**:
- `pekko_actor_mailbox_size{tenant_id, actor_type}`
- `pekko_actor_message_processed_total{tenant_id, actor_type}`
- `pekko_actor_restarts_total{tenant_id, actor_type, reason}`

### Logging (Structured JSON)

**Log Levels**:
- **DEBUG**: Actor message processing details
- **INFO**: Command received, event published, API requests
- **WARN**: Rate limit exceeded, validation warnings
- **ERROR**: Command failures, event publish failures

**Required Fields**: timestamp, level, service, version, tenant_id, trace_id, message, context.

### Distributed Tracing

**Trace Spans**:
- `http_request` - HTTP API request handling
- `command_processing` - Actor command processing
- `event_persistence` - Event store write
- `event_publishing` - Kafka publish
- `database_query` - Read model query

**Trace Attributes**: tenant_id, user_id, operation, resource_id, actor_id.

### Dashboards

**Service Overview Dashboard**:
- Request rate (req/sec by endpoint)
- Latency (P50/P95/P99 by endpoint)
- Error rate (5xx errors percentage)
- Active tenants count

**Per-Tenant Dashboard**:
- Tenant-specific request rate
- Tenant-specific latency vs SLA target
- User/org/team counts
- Resource consumption

**Actor System Dashboard**:
- Actor count by type
- Message throughput (msg/sec)
- Mailbox depth distribution
- Supervision events (restarts)

### Alerting

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| HighErrorRate | >5% errors for 5min | Critical | Page on-call |
| HighLatency | P95 >500ms for 5min | Warning | Investigate |
| ServiceDown | Health check failing 3x | Critical | Page + auto-rollback |
| ActorRestartLoop | >10 restarts/min | Critical | Investigate supervision |
| DatabaseConnectionPoolExhausted | >90% pool usage | Warning | Scale database connections |
| TenantSLAViolation | Tenant-specific SLA breach | Warning | Notify account team |

---

## Operations

### Deployment

**Strategy**: Blue-Green deployment with seam validation.

**Steps**:
1. Deploy new version to "green" environment
2. Run health checks (`/health/ready`)
3. Run smoke tests (create tenant, invite user)
4. Validate all 4 seam levels (isolation tests)
5. Switch traffic to green (update Kubernetes service)
6. Monitor for 15 minutes
7. Decommission blue environment

### Configuration

**ConfigMap** (`entity-management-config`):
- Database connection string
- Kafka brokers
- Rate limit thresholds (by tenant tier)
- Feature flags (organization feature enabled)

**Secrets** (`entity-management-secrets`):
- Database password
- Kafka credentials
- JWT public key for validation

### Database Migrations

**Tool**: Flyway  
**Location**: `src/main/resources/db/migration/`  
**Pattern**: `V###__description.sql` (forward), `R###__description.sql` (rollback)

**Example**:
```sql
-- V001__initial_schema.sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    subscription_plan VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT tenant_isolation CHECK (id = tenant_id)
);
CREATE INDEX idx_tenants_tenant_id ON tenants(tenant_id);
```

### Runbooks

| Scenario | Runbook |
|----------|---------|
| Service deployment | [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) |
| High error rate | Check logs for failures, verify DB/Kafka health, rollback if needed |
| Slow queries | Review query logs, check indexes, add read replica |
| Actor restart loop | Check supervision logs, identify failing message, add validation |
| Cross-tenant access attempt | Alert security team, review audit logs, verify isolation |

---

## Documentation

### Service Documentation

- [SERVICE-CHARTER.md](./SERVICE-CHARTER.md) - Mission, scope, metrics
- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Technical architecture
- [API-SPECIFICATION.md](./API-SPECIFICATION.md) - Complete OpenAPI spec
- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) - Deployment procedures
- [TELEMETRY-SPECIFICATION.md](./TELEMETRY-SPECIFICATION.md) - Observability setup
- [SECURITY-REQUIREMENTS.md](./SECURITY-REQUIREMENTS.md) - Security baseline

### Feature Documentation

- [features/tenant-management.md](./features/tenant-management.md)
- [features/organization-management.md](./features/organization-management.md)
- [features/user-invitation.md](./features/user-invitation.md)
- [features/role-assignment.md](./features/role-assignment.md)
- [features/permission-evaluation.md](./features/permission-evaluation.md)

### Governance References

- [MULTI-TENANT-SEAM-ARCHITECTURE.md](../../standards/MULTI-TENANT-SEAM-ARCHITECTURE.md)
- [API-DESIGN-STANDARDS.md](../../standards/API-DESIGN-STANDARDS.md)
- [EVENT-SCHEMA-STANDARDS.md](../../standards/EVENT-SCHEMA-STANDARDS.md)

---

## Release History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | TBD | Initial release (tenant, org, user, role management) |

---

## Security

**Security Standard**: [SECURITY-JWT-PERMISSIONS.md](../../technical/standards/SECURITY-JWT-PERMISSIONS.md)

### Authentication

- JWT (RS256) required on all endpoints (per SECURITY-JWT-PERMISSIONS standard)
- Token includes `tenant_id` claim (validated against X-Tenant-ID header)
- Token expiry: 1 hour (access), 30 days (refresh)

### Authorization

- RBAC model with tenant-scoped roles
- Permissions format: `entity-management:action:scope`
- Roles: tenant-owner, tenant-admin, org-admin, team-member

### Data Protection

- Email addresses encrypted at-rest (AES-256-GCM)
- All traffic over TLS 1.3
- Audit logging for all entity changes (7-year retention)

### Compliance

- GDPR: Right to erasure (soft delete + anonymization)
- SOC2: Access controls, audit logging, encryption

### Threat Mitigation

- Cross-tenant access: Multi-layer validation, automated tests
- SQL injection: Parameterized queries only
- XSS: Input sanitization, CSP headers
- DDoS: Rate limiting by tenant tier

---

## Testing

### Test Coverage

- **Unit Tests**: >80% line coverage (actor behavior, domain logic)
- **Integration Tests**: >70% (API, database, Kafka)
- **E2E Tests**: All critical user flows (invite user, assign role)
- **Multi-Tenant Isolation Tests**: 100% seam coverage

### Test Types

| Type | Count | Framework | Coverage |
|------|-------|-----------|----------|
| Unit (Actor) | 50+ | munit + Pekko TestKit | Actor behavior |
| Unit (Domain) | 30+ | munit | Business logic |
| Integration (API) | 25+ | munit + ZIO Test | REST endpoints |
| Integration (DB) | 15+ | munit + Testcontainers | Database queries |
| E2E | 10+ | Cucumber + RestAssured | User scenarios |
| Isolation | 8+ | munit | Cross-tenant protection |

### BDD Scenarios

All features have companion `.feature` files with Gherkin scenarios.

**Example**: `features/user-invitation.feature`
```gherkin
Feature: User Invitation
  Scenario: Tenant admin invites new user
    Given tenant "acme-corp" exists with plan "silver"
    And user "admin@acme.com" has role "tenant-admin"
    When admin invites "alice@acme.com" with role "org-admin"
    Then invitation email is sent to "alice@acme.com"
    And user "alice@acme.com" has status "pending"
```

---

## Disaster Recovery

### Backup Strategy

- **Event Store**: Continuous WAL archiving to S3 (15-minute RPO)
- **Read Models**: Daily full backup + hourly incremental (1-hour RPO)
- **Configuration**: Backed up with deployments (Git version control)

### Recovery Procedures

**Event Store Loss**:
1. Restore from latest WAL archive
2. Replay events to rebuild actor state
3. Verify data integrity (checksum validation)

**Read Model Corruption**:
1. Drop read model tables
2. Replay events from event store
3. Rebuild projections

### RTO/RPO Targets

| Component | RTO | RPO |
|-----------|-----|-----|
| Event Store | 15 minutes | 15 minutes (WAL) |
| Read Models | 30 minutes | 1 hour |
| Service Availability | 5 minutes | 0 (event-sourced) |

---

## Future Considerations

- **Custom Role Builder**: Allow tenants to define custom roles beyond predefined set
- **Attribute-Based Access Control (ABAC)**: Context-sensitive permissions (time, location, resource attributes)
- **Organization Hierarchy Limits**: Enforce max depth (5 levels), prevent cycles
- **Bulk Operations**: Import 1000+ users via CSV
- **SSO Integration**: SAML/OAuth for enterprise authentication
- **Multi-Region**: Active-active deployment across regions

---

## Canvas Changelog

| Date | Change | Author |
|------|--------|--------|
| 2025-11-29 | Initial canvas | Platform Team |
