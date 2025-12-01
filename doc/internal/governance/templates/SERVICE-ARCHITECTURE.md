# {Service Name} Architecture

**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Template Version**: 1.0

---

**Instructions**: Copy this template to service repository `docs/SERVICE-ARCHITECTURE.md`. This document provides detailed architectural design, patterns, and implementation guidance. This is more detailed than SERVICE-CANVAS.md.

---

## Overview

{Brief summary of service architecture - 2-3 paragraphs}

## Architectural Patterns

### Primary Patterns

**Pattern**: {Pattern name (e.g., CQRS Level 2, Event Sourcing, Actor Model)}  
**Rationale**: {Why this pattern chosen}  
**Implementation**: {How pattern applied}

**Example**:
**Pattern**: CQRS Level 2 (Standard CQRS)  
**Rationale**: High read-to-write ratio for tenant queries; separate read models optimize for common query patterns  
**Implementation**: Write model uses event-sourced actors, read models project from event streams to PostgreSQL views

### Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     {Service Name}                       │
├─────────────────────────────────────────────────────────┤
│ API Layer                                               │
│  - REST API (http4s / ZIO HTTP)                        │
│  - GraphQL API (optional)                               │
│  - gRPC API (optional)                                  │
├─────────────────────────────────────────────────────────┤
│ Application Layer                                        │
│  - Command Handlers (write path)                        │
│  - Query Handlers (read path)                           │
│  - Event Publishers                                      │
├─────────────────────────────────────────────────────────┤
│ Domain Layer                                             │
│  - Aggregate Actors ({Entity}Actor, {Entity}Actor)     │
│  - Domain Events                                         │
│  - Business Rules                                        │
├─────────────────────────────────────────────────────────┤
│ Infrastructure Layer                                     │
│  - Event Store (Akka/Pekko Persistence)                │
│  - Read Model Storage (PostgreSQL)                      │
│  - Message Broker (Kafka)                               │
└─────────────────────────────────────────────────────────┘
```

## Actor Model Design

### Aggregate Actors

**{Entity}Actor** (e.g., TenantActor, UserActor):
```scala
object {Entity}Actor {
  sealed trait Command
  case class {Command1}(...) extends Command
  case class {Command2}(...) extends Command
  
  sealed trait Event
  case class {Event1}(...) extends Event
  case class {Event2}(...) extends Event
  
  case class State(...)
  
  def apply(id: {Entity}Id): EventSourcedBehavior[Command, Event, State] = {
    EventSourcedBehavior[Command, Event, State](
      persistenceId = PersistenceId.of("{Entity}Actor", id.toString),
      emptyState = State.empty(id),
      commandHandler = handleCommand,
      eventHandler = handleEvent
    )
  }
  
  def handleCommand(state: State, cmd: Command): Effect[Event, State] = ???
  def handleEvent(state: State, event: Event): State = ???
}
```

**Supervision Strategy**:
- {Strategy description - OneForOne, AllForOne, etc.}
- {Restart conditions}
- {Escalation conditions}

### Message Protocols

**Command Messages** (imperative, request action):
```scala
// Examples
case class CreateTenant(entityId: EntityId, plan: SubscriptionPlan, replyTo: ActorRef[Response])
case class AssignUser(userId: UserId, roleName: String, replyTo: ActorRef[Response])
case class UpdatePermissions(permissions: Set[Permission], replyTo: ActorRef[Response])
```

**Event Messages** (past tense, facts):
```scala
// Examples
case class TenantCreated(tenantId: TenantId, entityId: EntityId, plan: SubscriptionPlan)
case class UserAssigned(tenantId: TenantId, userId: UserId, roleName: String)
case class PermissionsUpdated(tenantId: TenantId, permissions: Set[Permission])
```

**Query Messages** (read-only):
```scala
// Examples
case class GetTenant(tenantId: TenantId, replyTo: ActorRef[Option[Tenant]])
case class ListUsers(tenantId: TenantId, replyTo: ActorRef[Seq[User]])
```

## CQRS Implementation

### Write Path (Command Side)

1. API receives command
2. Validates tenant context (X-Tenant-ID + JWT)
3. Routes to appropriate aggregate actor
4. Actor validates business rules
5. Generates event if valid
6. Persists event to event store
7. Applies event to actor state
8. Publishes integration event to Kafka
9. Returns response to API

**Code Example**:
```scala
def handleCreateCommand(state: State, cmd: Create...): Effect[Event, State] = {
  // Validation
  if (!state.isValidFor(cmd)) {
    Effect.reply(cmd.replyTo)(ValidationFailed("..."))
  } else {
    // Generate and persist event
    Effect
      .persist(Created(...))
      .thenRun { _ =>
        // Publish integration event
        eventBus.publish(CreatedEvent(...))
      }
      .thenReply(cmd.replyTo)(_ => Success(...))
  }
}
```

### Read Path (Query Side)

1. API receives query
2. Validates tenant context
3. Queries read model (PostgreSQL view)
4. Returns response

**Read Model Projections**:
```sql
-- Example: Tenant view optimized for queries
CREATE MATERIALIZED VIEW tenant_view AS
SELECT 
  t.tenant_id,
  t.entity_id,
  t.subscription_plan,
  t.status,
  COUNT(DISTINCT u.user_id) as user_count,
  COUNT(DISTINCT s.service_name) as active_services_count
FROM tenants t
LEFT JOIN tenant_users u ON t.tenant_id = u.tenant_id
LEFT JOIN tenant_services s ON t.tenant_id = s.tenant_id AND s.status = 'active'
GROUP BY t.tenant_id, t.entity_id, t.subscription_plan, t.status;

CREATE INDEX idx_tenant_view_entity ON tenant_view(entity_id);
CREATE INDEX idx_tenant_view_status ON tenant_view(status);
```

**Projection Updates**:
```scala
// Event handler updates read model
class TenantProjection extends EventHandler[TenantEvent] {
  def process(event: TenantEvent): Future[Unit] = event match {
    case TenantCreated(tenantId, entityId, plan) =>
      db.run(sqlu"""
        INSERT INTO tenant_view (tenant_id, entity_id, subscription_plan, status)
        VALUES ($tenantId, $entityId, $plan, 'active')
      """)
    
    case UserAssigned(tenantId, userId, _) =>
      db.run(sqlu"""
        REFRESH MATERIALIZED VIEW tenant_view
        WHERE tenant_id = $tenantId
      """)
  }
}
```

## Event-Driven Integration

### Published Events

| Event Type | Topic | Purpose | Consumers |
|------------|-------|---------|-----------|
| {EventName} | {topic-name} | {Why published} | {Which services consume} |

**Example**:
| Event Type | Topic | Purpose | Consumers |
|------------|-------|---------|-----------|
| TenantCreated | entity-events | Notify services tenant ready | CartService, OrderService |
| UserAssignedToTenant | entity-events | Initialize user resources | All services |

### Consumed Events

| Event Type | Source Topic | Purpose | Action Taken |
|------------|--------------|---------|--------------|
| {EventName} | {topic-name} | {Why consumed} | {What service does} |

## Data Model

### Event Store Schema

```sql
-- Example using Akka Persistence journal
CREATE TABLE event_journal (
  ordering BIGSERIAL PRIMARY KEY,
  persistence_id VARCHAR(255) NOT NULL,
  sequence_number BIGINT NOT NULL,
  deleted BOOLEAN DEFAULT FALSE,
  tags VARCHAR(255),
  message BYTEA NOT NULL,
  CONSTRAINT event_journal_pk UNIQUE (persistence_id, sequence_number)
);

CREATE INDEX idx_event_journal_persistence_id ON event_journal(persistence_id);
CREATE INDEX idx_event_journal_tags ON event_journal(tags);
```

### Read Model Schema

```sql
-- Example tables for read models
CREATE TABLE tenants (
  tenant_id UUID PRIMARY KEY,
  entity_id UUID NOT NULL,
  subscription_plan VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE tenant_users (
  tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
  user_id UUID NOT NULL,
  role_name VARCHAR(100) NOT NULL,
  permissions JSONB NOT NULL,
  assigned_at TIMESTAMP NOT NULL,
  PRIMARY KEY (tenant_id, user_id)
);

CREATE INDEX idx_tenant_users_user_id ON tenant_users(user_id);
CREATE INDEX idx_tenant_users_role ON tenant_users(role_name);
```

## Scalability

### Horizontal Scaling

- **Stateless API Layer**: Scale by adding pods
- **Actor Sharding**: Distribute actors across cluster nodes
- **Read Model Replicas**: PostgreSQL read replicas for queries

### Performance Targets

| Metric | Target | Rationale |
|--------|--------|-----------|
| Command latency (p95) | <50ms | Responsive user experience |
| Query latency (p95) | <100ms | Fast dashboard loads |
| Event persistence | <20ms | Low write latency |
| Throughput | {N} req/sec | Expected load |

## Resilience

### Failure Modes

| Failure | Impact | Mitigation |
|---------|--------|------------|
| Actor crash | Command fails | Supervision restarts actor, replay events |
| Event store down | Writes fail | Circuit breaker, retry with backoff |
| Read model stale | Queries return old data | Acceptable (eventual consistency) |
| Kafka down | Events not published | Buffer locally, publish when recovered |

### Circuit Breakers

```scala
// Example: Circuit breaker for event store
val circuitBreaker = CircuitBreaker(
  maxFailures = 5,
  callTimeout = 10.seconds,
  resetTimeout = 1.minute
)

def persistEvent(event: Event): Future[Unit] = {
  circuitBreaker.withCircuitBreaker {
    eventStore.persist(event)
  }.recoverWith {
    case _: CircuitBreakerOpenException =>
      // Fall back to local buffer
      localBuffer.store(event)
  }
}
```

## Security

### Multi-Tenant Isolation

- **API Layer**: Validates X-Tenant-ID matches JWT tenant_id claim
- **Actor Layer**: Commands include TenantId, actors validate ownership
- **Database Layer**: All queries filtered by tenant_id
- **Event Layer**: Events include tenant_id, consumers filter

### Authentication & Authorization

- **Authentication**: JWT tokens validated by API gateway
- **Authorization**: Role-based permissions checked before command processing
- **Audit**: All commands and events logged with user context

## Observability

### Metrics

```scala
// Example metrics
metrics.counter("commands.received").tag("command_type", cmd.getClass.getSimpleName).increment()
metrics.timer("commands.duration").tag("command_type", ...).record(duration)
metrics.gauge("actors.active").set(activeActorCount)
metrics.counter("events.published").tag("event_type", ...).increment()
```

### Logging

```scala
// Structured logging
logger.info(
  "Command processed",
  "tenant_id" -> tenantId,
  "command_type" -> cmd.getClass.getSimpleName,
  "user_id" -> userId,
  "duration_ms" -> duration.toMillis
)
```

### Tracing

- Distributed tracing with OpenTelemetry
- Trace context propagated through commands, events, HTTP calls
- Spans for: Command processing, Event persistence, Query execution

## Deployment

### Container Configuration

```dockerfile
FROM openjdk:21-slim
COPY target/service.jar /app/service.jar
EXPOSE 8080
CMD ["java", "-jar", "/app/service.jar"]
```

### Kubernetes Resources

**Deployment**:
- Replicas: 3 (HA)
- Resources: {CPU/memory requests and limits}
- Health checks: `/health` (liveness), `/ready` (readiness)

**Service**:
- Type: ClusterIP
- Port: 8080

## Testing Strategy

### Unit Tests

- Actor behavior tests (command → event → state)
- Domain logic tests (business rules)
- Projection tests (event → read model)

### Integration Tests

- API tests (REST endpoints with TestKit)
- Actor integration (multi-actor scenarios)
- Database tests (read model queries)

### End-to-End Tests

- Complete workflows (tenant provisioning, user assignment)
- Multi-service integration (with dependent services)

## Migration Strategy

{If applicable, describe migration from existing system or major version upgrades}

## Future Considerations

- {Future enhancement 1}
- {Future enhancement 2}
- {Technical debt items}

## Related Documentation

- [SERVICE-CHARTER.md](../SERVICE-CHARTER.md) - Mission and scope
- [SERVICE-CANVAS.md](../SERVICE-CANVAS.md) - Quick reference overview
- [API-SPECIFICATION.md](./API-SPECIFICATION.md) - API details
- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) - Operational procedures

## Revision History

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial architecture | {Name} |
