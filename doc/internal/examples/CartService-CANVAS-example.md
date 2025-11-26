# CartService Canvas

**Version**: See Git history  
**Last Updated**: 2025-11-26  
**Owner**: Tony Moores  
**Status**: Example / Reference

---

## Service Identity

| Attribute | Value |
|-----------|-------|
| **Service Name** | CartService |
| **Repository** | [TJMSolns-CartService](https://github.com/TJMSolns/TJMSolns-CartService) |
| **Mission** | Manage shopping cart lifecycle for digital commerce platform |
| **Value Proposition** | Provides stateful shopping cart with concurrent updates, ACID guarantees, and event-driven integration |
| **Domain** | Commerce - Shopping Experience |
| **Language** | Scala 3.3.4 |
| **Build Tool** | Mill 0.11.x |
| **JVM** | OpenJDK 21 LTS |
| **Container Registry** | GCP Artifact Registry (us-central1) |
| **Governance** | [TJMPaaS](https://github.com/TJMSolns/TJMPaaS) |

---

## Dependencies

### Service Dependencies

| Service | Purpose | Interaction Pattern | SLA Dependency |
|---------|---------|---------------------|----------------|
| InventoryService | Check item availability | REST API | High (impacts add-to-cart) |
| PricingService | Get current item prices | REST API | High (impacts cart totals) |
| OrderService | Checkout integration | Events (CartCheckedOut) | Medium (async) |
| PromotionService | Apply discounts/promotions | REST API | Low (fallback to no promo) |

### External Dependencies

| Dependency | Purpose | Interaction Pattern | Failure Mode |
|------------|---------|---------------------|--------------|
| PostgreSQL | Event store (Pekko Persistence) | JDBC | Circuit breaker, service unavailable |
| Kafka | Event bus for integration events | Producer | Buffer locally, retry with backoff |
| Redis | Session association cache | Redis protocol | Degrade gracefully, fetch from database |

### Framework Selections

Per [PDR-0005: Framework Selection Policy](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/PDRs/PDR-0005-framework-selection-policy.md)

| Category | Framework | Version | Rationale |
|----------|-----------|---------|-----------|
| **Actor System** | Pekko | 1.0.2 | Apache 2.0 license, event sourcing support, mature actor model |
| **Effect System** | ZIO | 2.0.21 | Comprehensive effect system, excellent async support, type-safe |
| **HTTP** | ZIO HTTP | 3.0.0 | Native ZIO integration, simple API, good performance |
| **Persistence** | Pekko Persistence | 1.0.2 | Event sourcing for cart state, integrates with Pekko actors |
| **JSON** | zio-json | 0.6.2 | ZIO-native, fast serialization, type-safe codecs |
| **Testing** | munit | 0.7.29 | Fast, simple, good Scala 3 support |

**ADR Reference**: N/A (follows standard selections per PDR-0005)

---

## Architecture

### Agent/Actor Model

Per [ADR-0006: Agent-Based Service Patterns](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0006-agent-patterns.md)

| Actor/Agent | Purpose | State | Supervision |
|-------------|---------|-------|-------------|
| `ShoppingCartActor` | Manages individual cart state | Cart items, totals, customer ID, last modified | Restart on failure (state recovered from events) |
| `CartSupervisor` | Manages cart actor lifecycle | Child cart actor references | Restart failed children |
| `CartProjection` | Updates read model from events | N/A (stateless event handler) | Restart on failure, resume from last offset |

### Message Protocols

| Message Type | Direction | Purpose | Schema Version |
|--------------|-----------|---------|----------------|
| `AddItem` | In | Add item to cart | v1.0 |
| `RemoveItem` | In | Remove item from cart | v1.0 |
| `UpdateQuantity` | In | Change item quantity | v1.0 |
| `ApplyPromotion` | In | Apply promotion code | v1.0 |
| `Checkout` | In | Begin checkout process | v1.0 |
| `GetCart` | In | Query current cart state | v1.0 |
| `ItemAdded` | Out | Item added to cart event | v1.0 |
| `ItemRemoved` | Out | Item removed from cart event | v1.0 |
| `CartCheckedOut` | Out | Cart checked out event | v1.0 |

### System Diagram

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP (ZIO HTTP)
       ▼
┌─────────────────────┐
│  CartServiceAPI     │
│  (HTTP Routes)      │
└──────┬──────────────┘
       │
       ▼
┌──────────────────────┐      ┌───────────────┐
│  CartSupervisor      │─────▶│ PostgreSQL    │
│  (Manages Cart       │      │ (Event Store) │
│   Actors)            │      └───────────────┘
└──────┬───────────────┘
       │ Creates/Routes
       ▼
┌──────────────────────┐
│ ShoppingCartActor    │
│ (Per-cart instance)  │
│ - State: Cart Items  │      ┌───────────────┐
│ - Event Sourced      │─────▶│ Kafka         │
└──────────────────────┘      │ (cart-events) │
                              └───────────────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │ OrderService │
                              │ (Consumer)   │
                              └──────────────┘
```

---

## API Contract (CQRS)

Per [ADR-0007: CQRS and Event-Driven Architecture](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md)

### Commands (Write Operations)

| Command | Endpoint | Expected Use | SLO Threshold |
|---------|----------|--------------|---------------|
| AddItem | `POST /api/v1/carts/{cartId}/items` | 100 req/sec peak (flash sales) | p95 < 100ms, p99 < 200ms |
| RemoveItem | `DELETE /api/v1/carts/{cartId}/items/{itemId}` | 20 req/sec typical | p95 < 100ms |
| UpdateQuantity | `PATCH /api/v1/carts/{cartId}/items/{itemId}` | 30 req/sec typical | p95 < 100ms |
| ApplyPromotion | `POST /api/v1/carts/{cartId}/promotions` | 10 req/sec typical | p95 < 150ms |
| Checkout | `POST /api/v1/carts/{cartId}/checkout` | 50 req/sec peak | p95 < 200ms |

**AddItem Example**:
```scala
// Command message to actor
case class AddItem(
  cartId: CartId,
  item: Item,
  replyTo: ActorRef[Response]
) extends Command

// HTTP request
POST /api/v1/carts/abc-123/items
{
  "itemId": "SKU-12345",
  "quantity": 2,
  "customization": {
    "size": "M",
    "color": "blue"
  }
}
```

### Queries (Read Operations)

| Query | Endpoint | Expected Use | SLO Threshold |
|-------|----------|--------------|---------------|
| GetCart | `GET /api/v1/carts/{cartId}` | 500 req/sec typical | p95 < 50ms, p99 < 100ms |
| GetCartSummary | `GET /api/v1/carts/{cartId}/summary` | 200 req/sec typical | p95 < 30ms |
| ListActiveCarts | `GET /api/v1/customers/{customerId}/carts` | 50 req/sec typical | p95 < 100ms |

**GetCart Example**:
```scala
// Query message to actor
case class GetCart(
  cartId: CartId,
  replyTo: ActorRef[CartResponse]
) extends Query

// HTTP response
GET /api/v1/carts/abc-123
{
  "cartId": "abc-123",
  "customerId": "CUST-456",
  "items": [
    {
      "itemId": "SKU-12345",
      "name": "Blue T-Shirt",
      "quantity": 2,
      "unitPrice": 29.99,
      "subtotal": 59.98
    }
  ],
  "subtotal": 59.98,
  "tax": 5.40,
  "total": 65.38,
  "itemCount": 2,
  "lastModified": "2025-11-26T10:30:00Z"
}
```

### Events (Published)

| Event | Topic/Channel | Consumers | Retention |
|-------|---------------|-----------|-----------|
| ItemAdded | `cart-events` | AnalyticsService, RecommendationService | 30 days |
| ItemRemoved | `cart-events` | AnalyticsService | 30 days |
| CartCheckedOut | `cart-events` | OrderService, InventoryService, AnalyticsService | 90 days |
| CartAbandoned | `cart-events` | MarketingService (retargeting) | 30 days |

**CartCheckedOut Example**:
```scala
// Event published to Kafka
case class CartCheckedOut(
  cartId: CartId,
  customerId: CustomerId,
  items: Seq[CartItem],
  subtotal: Money,
  tax: Money,
  total: Money,
  timestamp: Instant
) extends Event

// Kafka message
Topic: cart-events
Key: abc-123
Value: {
  "eventType": "CartCheckedOut",
  "cartId": "abc-123",
  "customerId": "CUST-456",
  "items": [...],
  "total": 65.38,
  "timestamp": "2025-11-26T10:35:00Z"
}
```

### API Versioning

| Version | Status | Deprecation Date | Notes |
|---------|--------|------------------|-------|
| v1.0 | Current | - | Initial release |

---

## Non-Functional Requirements

### Reactive Manifesto Alignment

Per [ADR-0005: Reactive Manifesto Alignment](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0005-reactive-manifesto-alignment.md)

| Principle | Implementation |
|-----------|----------------|
| **Responsive** | p95 latency < 100ms for reads, < 200ms for writes; Circuit breakers prevent cascade delays |
| **Resilient** | Actor supervision restarts failed carts; Circuit breakers to inventory/pricing services; Read replica fallback |
| **Elastic** | Horizontal scaling via Kubernetes HPA (2-10 pods); Stateless HTTP layer; Cart actors sharded across pods |
| **Message-Driven** | Actor model for cart state; Async event publishing to Kafka; Non-blocking I/O throughout |

### Service Level Objectives (SLOs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Availability** | 99.9% (8.76 hours downtime/year) | Uptime monitoring, synthetic checks every 60s |
| **Latency (p95)** | Read < 50ms, Write < 100ms | Request duration histogram (HTTP and actor processing) |
| **Latency (p99)** | Read < 100ms, Write < 200ms | Request duration histogram |
| **Throughput** | 500 req/sec sustained, 1000 req/sec peak | Request rate counter |
| **Error Rate** | < 0.1% (999 success per 1000 requests) | Error ratio (HTTP 5xx + actor errors) |

### Resource Limits

| Resource | Request | Limit | Notes |
|----------|---------|-------|-------|
| **CPU** | 500m | 2000m | HPA scales at 70% CPU |
| **Memory** | 1Gi | 4Gi | JVM heap: 3Gi max (-Xmx3g) |
| **Storage** | 20Gi | 100Gi | PostgreSQL persistent volume |

### Scaling Characteristics

- **Horizontal Scaling**: Yes, 2 to 10 replicas
- **Auto-scaling Trigger**: CPU > 70% or request rate > 400/sec per pod
- **Statefulness**: Stateful (cart actors hold in-memory state, backed by event store)
- **Sharding**: Carts sharded by cartId hash across available pods

---

## Observability

### Health Checks

| Endpoint | Type | Check | Timeout |
|----------|------|-------|---------|
| `/health` | Liveness | Service process alive, actor system responsive | 5s |
| `/ready` | Readiness | Database connection OK, Kafka producer ready, actor system initialized | 10s |

### Metrics (Prometheus)

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `cart_requests_total` | Counter | `method`, `endpoint`, `status` | Total HTTP requests |
| `cart_request_duration_seconds` | Histogram | `method`, `endpoint` | HTTP request latency |
| `cart_actor_mailbox_size` | Gauge | `actor_type` | Actor mailbox depth (backpressure indicator) |
| `cart_events_published_total` | Counter | `event_type` | Events published to Kafka |
| `cart_active_carts_total` | Gauge | - | Number of active cart actors in memory |
| `cart_items_added_total` | Counter | - | Total items added across all carts |
| `cart_checkouts_total` | Counter | `status` (success/failure) | Total checkout attempts |

### Logging

| Level | Usage | Examples |
|-------|-------|----------|
| **ERROR** | Failures requiring attention | Event persistence failure, Kafka publish failure, database connection lost |
| **WARN** | Degraded but functional | Circuit breaker opened for inventory service, retry attempted, slow downstream service |
| **INFO** | Significant events | Service started, cart checked out, cart actor created, cart actor stopped |
| **DEBUG** | Detailed diagnostics | Message received by actor, state transition, event applied, HTTP request received |

**Structured Logging**: Yes (JSON format via zio-logging)  
**Log Aggregation**: GCP Cloud Logging  
**Correlation ID**: `X-Request-ID` header propagated through all operations

### Tracing

- **Framework**: OpenTelemetry
- **Sampling Rate**: 10% in production, 100% in development
- **Trace Context**: Propagated via HTTP headers (`traceparent`)
- **Spans**: HTTP request, actor message processing, database operations, Kafka publish

---

## Operations

### Deployment

| Attribute | Value |
|-----------|-------|
| **Container Image** | `us-central1-docker.pkg.dev/tjmsolns/services/cart-service:1.0.0` |
| **Orchestration** | Kubernetes (GKE) |
| **Deployment Strategy** | Rolling update (25% max unavailable, 25% max surge) |
| **Namespace** | `commerce` |
| **Helm Chart** | Yes, `charts/cart-service/` |

### Environment Variables

| Variable | Purpose | Required | Default |
|----------|---------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Yes | - |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker addresses | Yes | - |
| `REDIS_URL` | Redis connection string | Yes | - |
| `INVENTORY_SERVICE_URL` | Inventory service endpoint | Yes | - |
| `PRICING_SERVICE_URL` | Pricing service endpoint | Yes | - |
| `LOG_LEVEL` | Logging level | No | `INFO` |
| `ACTOR_PASSIVATION_TIMEOUT` | Idle cart actor timeout | No | `30m` |
| `MAX_CART_ITEMS` | Maximum items per cart | No | `100` |

### Secrets

| Secret | Purpose | Source |
|--------|---------|--------|
| `cart-db-credentials` | PostgreSQL username/password | GCP Secret Manager |
| `kafka-sasl-credentials` | Kafka authentication | GCP Secret Manager |
| `redis-password` | Redis authentication | GCP Secret Manager |

### Runbooks

| Scenario | Priority | Runbook Link |
|----------|----------|--------------|
| Service not starting | P1 | `docs/runbooks/service-startup-failure.md` |
| High latency (p95 > 200ms) | P2 | `docs/runbooks/high-latency.md` |
| Database connection failure | P1 | `docs/runbooks/database-connection-failure.md` |
| Kafka publish failures | P2 | `docs/runbooks/kafka-publish-failure.md` |
| Cart actor memory leak | P2 | `docs/runbooks/memory-leak-investigation.md` |
| Circuit breaker open | P3 | `docs/runbooks/circuit-breaker-open.md` |

### Maintenance Windows

- **Required**: No (zero-downtime deployments)
- **Frequency**: N/A
- **Duration**: N/A
- **Schedule**: N/A

---

## Documentation

### Service Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| **README** | Repo root | Service overview, quick start, local development |
| **API Specification** | `docs/API.md` | Detailed API documentation with examples |
| **Architecture** | `docs/ARCHITECTURE.md` | Detailed design, actor model, event sourcing patterns |
| **Deployment** | `docs/DEPLOYMENT.md` | Deployment procedures, Kubernetes configuration |
| **Configuration** | `docs/CONFIGURATION.md` | All configuration options and environment variables |
| **Runbooks** | `docs/runbooks/` | Operational procedures for common issues |

### External Governance References

| Document | Link |
|----------|------|
| **Project Charter** | [TJMPaaS CHARTER.md](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/CHARTER.md) |
| **Roadmap** | [TJMPaaS ROADMAP.md](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/ROADMAP.md) |
| **ADR-0005: Reactive Manifesto** | [Link](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0005-reactive-manifesto-alignment.md) |
| **ADR-0006: Agent Patterns** | [Link](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0006-agent-patterns.md) |
| **ADR-0007: CQRS/Event-Driven** | [Link](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) |
| **PDR-0005: Framework Selection** | [Link](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/PDRs/PDR-0005-framework-selection-policy.md) |
| **PDR-0006: Service Canvas** | [Link](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/PDRs/PDR-0006-service-canvas-standard.md) |
| **Service Registry** | [TJMPaaS Service Registry](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/services/REGISTRY.md) |

---

## Release History

| Version | Date | Changes | ADR/PDR |
|---------|------|---------|---------|
| 0.1.0 | 2025-11-26 | Initial release (example canvas) | - |

---

## Security

### Authentication & Authorization

- **Authentication**: OAuth 2.0 bearer tokens (validated via API Gateway)
- **Authorization**: Customer can only access own carts; admin role for operations
- **Service-to-Service Auth**: mTLS between services in cluster

### Data Protection

- **Encryption at Rest**: Yes, PostgreSQL encrypted volumes (GCP KMS)
- **Encryption in Transit**: TLS 1.3 for all external connections, mTLS for service-to-service
- **PII/Sensitive Data**: Customer ID (PII), payment info NOT stored (handled by OrderService)

### Security Scanning

- **Container Scanning**: Trivy, every build and weekly in production
- **Dependency Scanning**: Dependabot, daily
- **SAST**: SonarQube, every PR

### Compliance

- **Requirements**: PCI-DSS Level 1 (cart participates in payment flow), GDPR
- **Audit Logging**: All cart operations logged with customer ID and timestamp

---

## Testing

### Test Coverage

| Type | Target | Actual | Framework |
|------|--------|--------|-----------|
| **Unit** | > 80% | 85% | munit |
| **Integration** | > 70% | 72% | munit + Testcontainers |
| **Actor Tests** | > 90% | 93% | Pekko ActorTestKit |

### Test Types

| Type | Framework | CI Stage | Notes |
|------|-----------|----------|-------|
| **Unit** | munit | Build | Fast, isolated, no external dependencies |
| **Integration** | munit + Testcontainers | Build | PostgreSQL and Kafka via Testcontainers |
| **Contract** | Custom (event schema validation) | Build | Validate event schemas against published contracts |
| **End-to-End** | Custom (HTTP client + test harness) | Deploy (staging) | Full cart lifecycle with real services |
| **Load** | Gatling | Pre-Prod | 1000 req/sec sustained, verify SLOs |

### Test Data

- **Approach**: Factories via scalacheck for domain objects, fixtures for events
- **Test DB**: PostgreSQL Testcontainers (real database, not H2)
- **Test Events**: Sample events in `src/test/resources/events/`

---

## Disaster Recovery

### Backup Strategy

- **What**: PostgreSQL event store (complete event history)
- **Frequency**: Continuous (GCP automated backups), snapshots every 6 hours
- **Retention**: 30 days point-in-time recovery
- **Storage**: GCP Cloud Storage (multi-region)

### Recovery Objectives

- **RTO** (Recovery Time Objective): 1 hour (restore database + redeploy service)
- **RPO** (Recovery Point Objective): 5 minutes (max data loss with continuous backup)

### Failure Scenarios

| Scenario | Impact | Mitigation | Recovery |
|----------|--------|------------|----------|
| Pod failure | Single cart operations fail | Kubernetes auto-restart, cart state recovered from events | Automatic, < 30 seconds |
| Database failure | All cart writes fail, reads from stale cache | Read replicas for queries, circuit breaker prevents cascade | Manual failover, < 15 minutes |
| Kafka failure | Events not published, cart operations continue | Local buffer with retry, degraded mode (no integration events) | Automatic recovery when Kafka restored |
| Region outage (GCP) | Service unavailable in region | Multi-region deployment (future), disaster recovery to different region | Manual failover, < 2 hours |
| Data corruption | Incorrect cart state | Event replay from backup, rebuild state | Manual, < 4 hours |

---

## Future Considerations

### Planned Enhancements

- Multi-region deployment for disaster recovery
- Cart sharing functionality (collaborative carts)
- Wishlist / saved-for-later features
- Advanced promotions (BOGO, tiered discounts)
- Cart recommendations based on items

### Known Limitations

- Single region deployment currently (disaster recovery limited)
- No cart merging when anonymous cart converted to authenticated
- Promotion engine integration is basic (single code per cart)

### Deprecation Plans

- None currently

---

## Canvas Changelog

| Date | Change | Updated By |
|------|--------|------------|
| 2025-11-26 | Canvas created as example/reference | Tony Moores |

---

**Note**: This is an example canvas for reference. Actual CartService implementation may differ. This canvas demonstrates the structure and level of detail expected for all TJMPaaS services per [PDR-0006](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/PDRs/PDR-0006-service-canvas-standard.md).
