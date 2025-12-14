# Entity Management Service Architecture

**Status**: Active  
**Version**: 1.0.0  
**Last Updated**: 2025-11-29  
**Template**: [SERVICE-ARCHITECTURE.md](../../governance/templates/SERVICE-ARCHITECTURE.md)

---

## Architecture Overview

Entity Management Service implements CQRS Level 3 (Full Event Sourcing) with actor-based command processing, event-sourced aggregates, and optimized read models for queries.

### System Context

```
┌─────────────────────────────────────────────────────────────┐
│                    External Systems                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐             │
│  │   Auth   │  │Provision-│  │ Notification │             │
│  │ Service  │  │  ing     │  │   Service    │             │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘             │
└───────┼─────────────┼────────────────┼──────────────────────┘
        │             │                │
        │ JWT         │ Tenant         │ Email
        │ Validation  │ Creation       │ Invitations
        │             │                │
┌───────▼─────────────▼────────────────▼──────────────────────┐
│          Entity Management Service                           │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐    │
│  │  REST API  │  │ Actor System │  │  Read Models    │    │
│  │ (ZIO HTTP) │  │   (Pekko)    │  │  (PostgreSQL)   │    │
│  └──────┬─────┘  └───────┬──────┘  └────────┬────────┘    │
│         │                 │                  │              │
│         └────────┬────────┴─────────┬────────┘              │
│                  │                  │                       │
│          ┌───────▼──────┐  ┌────────▼────────┐            │
│          │ Event Store  │  │ Kafka Publisher │            │
│          │ (PostgreSQL) │  │  (entity-events)│            │
│          └──────────────┘  └────────┬────────┘            │
└───────────────────────────────────────┼──────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────┐
│                   Consumer Services                          │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐               │
│  │   Cart   │  │  Order   │  │ Analytics │               │
│  │ Service  │  │ Service  │  │  Service  │               │
│  └──────────┘  └──────────┘  └───────────┘               │
└─────────────────────────────────────────────────────────────┘
```

### Technology Decisions

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| API | ZIO HTTP | Pure functional, ZIO-native, excellent performance |
| Actors | Pekko | Apache 2.0, Akka-compatible, community-driven (ADR-0006) |
| Effects | ZIO 2.x | Comprehensive effect system, excellent error handling (ADR-0004) |
| Persistence | Pekko Persistence | Event sourcing for actors, audit trail (ADR-0007) |
| Database | PostgreSQL 15 | ACID compliance, JSONB support, proven scalability |
| Events | Apache Kafka | High-throughput, durable, partitioned by tenant_id |
| Serialization | circe (JSON) + Protobuf | circe for API, Protobuf for events (performance) |

---

## Component Architecture

### Command Side (Write Path)

**Flow**: `API Request → Command → Actor → Event → Event Store → Kafka`

**Actors** (Event-Sourced Aggregates):

```scala
// Tenant Actor
object TenantActor {
  sealed trait Command
  case class CreateTenant(id: UUID, name: String, plan: String, replyTo: ActorRef[Response]) extends Command
  case class UpdateTenant(name: Option[String], plan: Option[String], replyTo: ActorRef[Response]) extends Command
  
  sealed trait Event
  case class TenantCreated(id: UUID, name: String, plan: String, timestamp: Instant) extends Event
  case class TenantUpdated(name: Option[String], plan: Option[String], timestamp: Instant) extends Event
  
  def apply(tenantId: UUID): EventSourcedBehavior[Command, Event, State] =
    EventSourcedBehavior(
      persistenceId = PersistenceId.ofUniqueId(s"tenant-$tenantId"),
      emptyState = State.empty,
      commandHandler = handleCommand,
      eventHandler = handleEvent
    )
}
```

**Sharding Strategy**: Actors sharded by `tenant_id` hash for horizontal scaling.

**Supervision**: OneForOne - failed actor restarted independently (ADR-0006).

### Query Side (Read Path)

**Flow**: `API Request → Read Model Query → PostgreSQL → JSON Response`

**Read Models** (Denormalized Views):

```sql
-- Tenant View
CREATE TABLE tenant_view (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    subscription_plan VARCHAR(50) NOT NULL,
    org_count INT DEFAULT 0,
    user_count INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- Organization View
CREATE TABLE organization_view (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    parent_org_id UUID,
    team_count INT DEFAULT 0,
    member_count INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL
);

-- Indexes for tenant isolation
CREATE INDEX idx_tenant_view_tenant_id ON tenant_view(tenant_id);
CREATE INDEX idx_organization_view_tenant_id ON organization_view(tenant_id);
```

**Projection**: Event streams trigger read model updates (eventually consistent, <1 second lag).

---

## Multi-Tenant Isolation

### Seam 1: Tenant Boundary

**Enforcement Points**:
1. **API Layer**: Validate X-Tenant-ID header matches JWT tenant_id claim
2. **Actor Layer**: Actor sharding key includes tenant_id
3. **Database Layer**: All queries filtered: `WHERE tenant_id = ?`
4. **Event Layer**: Kafka partition key = tenant_id

**Validation**:
```scala
def validateTenantAccess(request: Request): ZIO[Any, SecurityError, TenantId] = {
  for {
    headerTenantId <- extractTenantIdFromHeader(request)
    jwtTenantId    <- extractTenantIdFromJWT(request)
    _              <- ZIO.when(headerTenantId != jwtTenantId)(ZIO.fail(TenantMismatch))
  } yield headerTenantId
}
```

### Seam 2: Tenant-Service Entitlement

**Feature Flags** (per tenant subscription plan):
```scala
case class ServiceEntitlement(
  organizationFeatureEnabled: Boolean,  // Bronze: false, Silver+: true
  teamFeatureEnabled: Boolean,          // Bronze/Silver: false, Gold: true
  maxOrganizations: Option[Int],        // Bronze: 1, Silver: 10, Gold: unlimited
  maxUsersPerOrg: Option[Int]           // Bronze: 10, Silver: 100, Gold: unlimited
)
```

### Seam 3: Tenant-Service-Feature Limits

**Rate Limiting** (per tenant tier):
- User invitations: 10/month (Bronze), 100/month (Silver), unlimited (Gold)
- API calls: 1000/hour (Bronze), 10000/hour (Silver), 100000/hour (Gold)

**Quota Enforcement**:
```scala
def checkInvitationQuota(tenantId: UUID): ZIO[Any, QuotaExceeded, Unit] = {
  for {
    plan <- getTenantPlan(tenantId)
    count <- getMonthlyInvitationCount(tenantId)
    limit = plan match {
      case "bronze" => Some(10)
      case "silver" => Some(100)
      case "gold" => None // unlimited
    }
    _ <- ZIO.when(limit.exists(count >= _))(ZIO.fail(QuotaExceeded))
  } yield ()
}
```

### Seam 4: Tenant-Service-Role Permissions

**Role Hierarchy**:
```
tenant-owner (all permissions)
  ├─ tenant-admin (manage users/orgs, not billing)
  │   ├─ org-admin (manage teams/users in org)
  │   │   └─ team-member (read-only)
```

**Permission Evaluation**:
```scala
def hasPermission(userId: UUID, permission: Permission, scope: Scope): ZIO[Any, Nothing, Boolean] = {
  for {
    roles <- getUserRoles(userId, scope.tenantId)
    perms <- roles.flatMap(role => getRolePermissions(role))
  } yield perms.contains(permission)
}
```

---

## Data Flow

### Command Processing

```
1. HTTP Request arrives at API
2. Extract tenant_id from X-Tenant-ID header
3. Validate JWT tenant_id matches header tenant_id
4. Route command to appropriate actor (via sharding)
5. Actor validates business rules
6. Actor persists event to event store
7. Actor updates in-memory state
8. Actor sends response to API
9. API returns HTTP 202 Accepted
10. Event published to Kafka asynchronously
```

### Event Publishing

```
1. Event persisted to PostgreSQL event journal
2. Pekko Persistence triggers event handler
3. Event serialized to Protobuf
4. Event wrapped in CloudEvents envelope
5. Event published to Kafka (partition by tenant_id)
6. Other services consume from Kafka
7. Services update their own read models
```

### Query Processing

```
1. HTTP GET request arrives at API
2. Validate tenant_id in JWT
3. Query read model: SELECT * FROM view WHERE tenant_id = ?
4. Transform DB rows to JSON
5. Add HATEOAS links to response
6. Return HTTP 200 OK with data
```

---

## Scalability

### Horizontal Scaling

**Pod Scaling** (Kubernetes HPA):
- Trigger: CPU >70%
- Min pods: 2
- Max pods: 10
- Scale-up: Add 1 pod if CPU >70% for 2 minutes
- Scale-down: Remove 1 pod if CPU <30% for 5 minutes

**Actor Sharding** (Pekko Cluster):
- Shard by tenant_id hash
- Rebalance on cluster membership changes
- Max 100 actors per shard
- Max 1000 shards per cluster

### Database Scaling

**Vertical**: PostgreSQL on 4 vCPU, 16 GB RAM baseline.

**Read Replicas**: Add replica when query latency >200ms.

**Connection Pooling**: HikariCP with 50 connections per pod.

### Kafka Scaling

**Topic Partitions**: `entity-events` topic with 10 partitions.

**Producer**: Async batching (100 messages or 10ms linger).

**Consumer**: Consumer group per consuming service.

---

## Failure Handling

### Circuit Breakers

**Database Circuit Breaker**:
- Failure threshold: 5 failures in 10 seconds
- Open state duration: 30 seconds
- Half-open state: Try 1 request
- Fallback: Return cached data or 503

**Kafka Circuit Breaker**:
- Failure threshold: 10 failures in 30 seconds
- Open state: Buffer events locally (max 1000)
- Half-open: Try publishing 1 event
- Fallback: Retry queue with exponential backoff

### Actor Supervision

**Strategy**: OneForOne - restart failed actor only.

**Restart Limits**:
- Max 10 restarts per minute
- If exceeded: Escalate to parent, log error, alert on-call

**Failure Recovery**:
- Actor restarted → state rebuilt from event replay
- Mailbox preserved → no message loss
- Stash pattern for commands during recovery

---

## Security Architecture

### Authentication Flow

```
1. Client obtains JWT from Auth Service (RS256 signed)
2. Client includes JWT in Authorization: Bearer <token>
3. Entity Management validates JWT signature (cached public key)
4. Extract tenant_id claim from JWT
5. Compare tenant_id claim to X-Tenant-ID header
6. If match: Allow request, else: Return 403 Forbidden
```

### Authorization Model

**RBAC** (Role-Based Access Control):
- Roles defined per tenant (tenant-owner, tenant-admin, org-admin, team-member)
- Permissions format: `entity-management:action:scope`
- Example: `entity-management:user:invite:org-123`

**Permission Evaluation** (cached for 5 minutes):
```scala
def authorize(userId: UUID, action: String, resourceId: UUID): ZIO[Any, SecurityError, Unit] = {
  for {
    roles <- getRolesForUser(userId)
    perms <- getPermissionsForRoles(roles)
    required = s"entity-management:$action:$resourceId"
    _ <- ZIO.when(!perms.contains(required))(ZIO.fail(Forbidden))
  } yield ()
}
```

### Data Protection

- **At-Rest**: Email addresses encrypted (AES-256-GCM)
- **In-Transit**: TLS 1.3 for all connections
- **Audit Log**: All entity changes logged (immutable, 7-year retention)

---

## Performance Optimization

### Caching Strategy

**Redis Cache** (5-minute TTL):
- Tenant configuration (plan, entitlements)
- User roles and permissions
- Organization hierarchy

**In-Memory Cache** (actor state):
- Actor state cached in-memory
- No DB reads for command validation
- Rebuilt from events on actor restart

### Database Optimization

**Indexes**:
```sql
CREATE INDEX idx_tenant_view_tenant_id ON tenant_view(tenant_id);
CREATE INDEX idx_org_view_tenant_id ON organization_view(tenant_id);
CREATE INDEX idx_user_view_tenant_id ON user_view(tenant_id);
CREATE INDEX idx_user_view_email ON user_view(email) WHERE tenant_id IS NOT NULL;
```

**Query Optimization**:
- All queries include `tenant_id` filter (index scan)
- Limit result sets (max 100 per page)
- Use `SELECT` with specific columns (avoid `SELECT *`)

### Event Processing

**Batching**: Events published to Kafka in batches (100 events or 10ms).

**Compression**: Protobuf serialization reduces event size by 70% vs JSON.

**Partitioning**: Kafka partitioned by tenant_id for parallel processing.

---

## Monitoring and Observability

See [TELEMETRY-SPECIFICATION.md](./TELEMETRY-SPECIFICATION.md) for complete details.

**Key Metrics**:
- `entity_command_duration_seconds{tenant_id, command_type}` - Command processing latency
- `entity_query_duration_seconds{tenant_id, query_type}` - Query latency
- `entity_events_published_total{tenant_id, event_type}` - Events published
- `pekko_actor_mailbox_size{tenant_id, actor_type}` - Mailbox depth

**Alerts**:
- Command latency P95 >500ms → Warning
- Query latency P95 >200ms → Warning
- Event publishing failure rate >1% → Critical
- Actor restart rate >10/minute → Critical

---

## Deployment Architecture

See [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) for deployment procedures.

**Kubernetes Resources**:
- Deployment: `entity-management-deployment` (2-10 replicas)
- Service: `entity-management-service` (ClusterIP)
- Ingress: `/api/v1/entities/...` routes
- ConfigMap: `entity-management-config`
- Secret: `entity-management-secrets`

**Database**:
- Cloud SQL (PostgreSQL 15)
- Connection pooling (50 per pod)
- Read replicas for scaling

**Kafka**:
- Managed Kafka (Confluent Cloud or self-hosted)
- Topic: `entity-events` (10 partitions)
- Replication factor: 3

---

## Testing Strategy

See [ACCEPTANCE-CRITERIA.md](./ACCEPTANCE-CRITERIA.md) for complete DoD.

**Test Pyramid**:
- Unit tests (80% coverage): Actor behavior, domain logic
- Integration tests (70% coverage): API, database, Kafka
- E2E tests: Critical user flows (invite user, assign role)
- Isolation tests: 100% seam coverage (all 4 seams)

**Performance Tests**:
- Load test: 1000 req/sec sustained
- Stress test: 5000 req/sec burst
- Soak test: 500 req/sec for 24 hours

---

## Disaster Recovery

**Event Store Backup**: Continuous WAL archiving (15-min RPO).

**Read Model Backup**: Daily full + hourly incremental (1-hour RPO).

**Recovery**: Rebuild read models from event replay (30-min RTO).

---

## Future Architecture Enhancements

- **Multi-Region**: Active-active deployment with CRDT-based conflict resolution
- **CQRS Optimization**: Separate write/read databases (PostgreSQL write, Elasticsearch read)
- **Event Replay**: Admin API to replay events for read model rebuilds
- **Schema Evolution**: Event upcasting for backward compatibility
- **GraphQL**: Add GraphQL API alongside REST for flexible querying

---

## Related Documentation

- [SERVICE-CHARTER.md](./SERVICE-CHARTER.md)
- [API-SPECIFICATION.md](./API-SPECIFICATION.md)
- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md)
- [TELEMETRY-SPECIFICATION.md](./TELEMETRY-SPECIFICATION.md)
- [SECURITY-REQUIREMENTS.md](./SECURITY-REQUIREMENTS.md)

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-29 | Initial architecture | Platform Team |
