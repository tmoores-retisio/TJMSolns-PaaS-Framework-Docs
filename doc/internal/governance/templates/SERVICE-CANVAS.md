# [ServiceName] Service Canvas

---
**Template Status**: Active Template  
**Template Authority**: TJMPaaS Official  
**Template Last Updated**: 2025-11-26  
**Governance**: [PDR-0006: Service Canvas Documentation Standard](../governance/PDRs/PDR-0006-service-canvas-standard.md)  
---

**Version**: See Git history  
**Last Updated**: YYYY-MM-DD  
**Owner**: [Team/Individual Name]  
**Status**: [Development | Production | Deprecated]

---

## Service Identity

| Attribute | Value |
|-----------|-------|
| **Service Name** | [ServiceName] |
| **Repository** | [TJMSolns-ServiceName](https://github.com/TJMSolns/TJMSolns-ServiceName) |
| **Mission** | [One sentence describing the service's purpose] |
| **Value Proposition** | [What problem does this service solve?] |
| **Domain** | [Commerce, User Management, Infrastructure, etc.] |
| **Language** | Scala 3.3+ |
| **Build Tool** | Mill |
| **JVM** | OpenJDK 17 or 21 LTS |
| **Container Registry** | [e.g., GCP Artifact Registry] |
| **Governance** | [TJMPaaS](https://github.com/TJMSolns/TJMPaaS) |

---

## Dependencies

### Service Dependencies

| Service | Purpose | Interaction Pattern | SLA Dependency |
|---------|---------|---------------------|----------------|
| [ServiceName] | [Why needed] | [REST/gRPC/Events/Messages] | [Critical/High/Medium/Low] |

### External Dependencies

| Dependency | Purpose | Interaction Pattern | Failure Mode |
|------------|---------|---------------------|--------------|
| [e.g., PostgreSQL] | [e.g., Event store] | [e.g., JDBC] | [e.g., Circuit breaker, fallback to cache] |
| [e.g., Kafka] | [e.g., Event bus] | [e.g., Producer/Consumer] | [e.g., Buffer locally, retry] |

### Framework Selections

Per [PDR-0005: Framework Selection Policy](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/PDRs/PDR-0005-framework-selection-policy.md)

| Category | Framework | Version | Rationale |
|----------|-----------|---------|-----------|
| **Actor System** | [Pekko/Akka Typed/ZIO Actors] | [x.y.z] | [Why chosen for this service] |
| **Effect System** | [ZIO/Cats Effect] | [x.y.z] | [Why chosen for this service] |
| **HTTP** | [http4s/ZIO HTTP] | [x.y.z] | [Why chosen for this service] |
| **Persistence** | [Pekko/Akka Persistence] | [x.y.z] | [Why chosen for this service] |
| **JSON** | [circe/zio-json] | [x.y.z] | [Why chosen for this service] |
| **Testing** | [munit/scalatest] | [x.y.z] | [Why chosen for this service] |

**ADR Reference**: [Link to ADR if framework choice documented]

---

## Architecture

### Agent/Actor Model

Per [ADR-0006: Agent-Based Service Patterns](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0006-agent-patterns.md)

| Actor/Agent | Purpose | State | Supervision |
|-------------|---------|-------|-------------|
| [ActorName] | [What it manages] | [What state it holds] | [Supervision strategy] |

**Example**: `ShoppingCartActor` | Manages shopping cart state | Cart items, totals, customer ID | Restart on failure

### Message Protocols

| Message Type | Direction | Purpose | Schema Version |
|--------------|-----------|---------|----------------|
| [CommandName] | [In] | [What it does] | [v1.0] |
| [QueryName] | [In] | [What it queries] | [v1.0] |
| [EventName] | [Out] | [What it signals] | [v1.0] |

### System Diagram

```
[Optional: ASCII diagram or link to architecture diagram]
```

---

## API Contract (CQRS)

Per [ADR-0007: CQRS and Event-Driven Architecture](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md)

### CQRS Approach

**CQRS Maturity Level**: [Level 1 / Level 2 / Level 3 / N/A]
- **Level 1 (Simple)**: Separate methods, same database
- **Level 2 (Standard)**: Separate models and databases, no event sourcing - **Recommended for most TJMPaaS services**
- **Level 3 (Full ES)**: Event sourcing, complete audit trail - Use for audit-critical domains (orders, payments, inventory)
- **N/A**: Simple CRUD, no CQRS needed

**Rationale**: [Why this level was chosen for this service]

**Example**: "Level 2 - Shopping cart requires independent read/write scaling for high browse-to-purchase ratio, but doesn't need complete audit trail of every cart modification."

See [CQRS Patterns Best Practices](../../technical/best-practices/architecture/cqrs-patterns.md) for detailed guidance.

### Commands (Write Operations)

| Command | Endpoint | Expected Use | SLO Threshold |
|---------|----------|--------------|---------------|
| [CommandName] | `POST /api/v1/[resource]` | [e.g., 100 req/sec peak] | [e.g., p95 < 100ms] |

**Example**:
```scala
// AddItem command
case class AddItem(
  cartId: CartId,
  item: Item,
  replyTo: ActorRef[Response]
) extends Command
```

### Queries (Read Operations)

| Query | Endpoint | Expected Use | SLO Threshold |
|-------|----------|--------------|---------------|
| [QueryName] | `GET /api/v1/[resource]` | [e.g., 500 req/sec peak] | [e.g., p95 < 50ms] |

**Example**:
```scala
// GetCart query
case class GetCart(
  cartId: CartId,
  replyTo: ActorRef[CartResponse]
) extends Query
```

### Events (Published)

| Event | Topic/Channel | Consumers | Retention |
|-------|---------------|-----------|-----------|
| [EventName] | [e.g., cart-events] | [e.g., OrderService, AnalyticsService] | [e.g., 7 days] |

**Example**:
```scala
// CartCheckedOut event
case class CartCheckedOut(
  cartId: CartId,
  items: Seq[Item],
  total: Money,
  timestamp: Instant
) extends Event
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
| **Responsive** | [How service ensures timely response] |
| **Resilient** | [Supervision strategies, circuit breakers, bulkheads] |
| **Elastic** | [Horizontal scaling via Kubernetes HPA, stateless design] |
| **Message-Driven** | [Actor model, async message-passing, backpressure] |

### Service Level Objectives (SLOs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Availability** | 99.9% | Uptime monitoring |
| **Latency (p95)** | < [X]ms | Request duration histogram |
| **Latency (p99)** | < [Y]ms | Request duration histogram |
| **Throughput** | [N] req/sec | Request rate counter |
| **Error Rate** | < 0.1% | Error ratio |

### Resource Limits

| Resource | Request | Limit | Notes |
|----------|---------|-------|-------|
| **CPU** | [e.g., 500m] | [e.g., 2000m] | [Scaling considerations] |
| **Memory** | [e.g., 512Mi] | [e.g., 2Gi] | [JVM heap size] |
| **Storage** | [e.g., 10Gi] | [e.g., 50Gi] | [Persistent volumes] |

### Scaling Characteristics

- **Horizontal Scaling**: [Yes/No], [Min replicas] to [Max replicas]
- **Auto-scaling Trigger**: [e.g., CPU > 70%]
- **Statefulness**: [Stateless/Stateful - if stateful, how state is managed]

---

## Observability

### Health Checks

| Endpoint | Type | Check | Timeout |
|----------|------|-------|---------|
| `/health` | Liveness | [What it checks] | [e.g., 5s] |
| `/ready` | Readiness | [What it checks] | [e.g., 10s] |

### Metrics (Prometheus)

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `[service]_requests_total` | Counter | `method`, `status` | Total requests |
| `[service]_request_duration_seconds` | Histogram | `method`, `endpoint` | Request latency |
| `[service]_actor_mailbox_size` | Gauge | `actor_type` | Actor mailbox depth |
| `[service]_events_published_total` | Counter | `event_type` | Events published |

### Logging

| Level | Usage | Examples |
|-------|-------|----------|
| **ERROR** | Failures requiring attention | [e.g., Persistence failure, external service timeout] |
| **WARN** | Degraded but functional | [e.g., Circuit breaker open, retry attempted] |
| **INFO** | Significant events | [e.g., Service started, command processed] |
| **DEBUG** | Detailed diagnostics | [e.g., Message received, state transition] |

**Structured Logging**: Yes (JSON format)  
**Log Aggregation**: [e.g., GCP Cloud Logging, ELK stack]

### Tracing

- **Framework**: [e.g., OpenTelemetry]
- **Sampling Rate**: [e.g., 10% in production]
- **Trace Context**: [Propagated via HTTP headers]

---

## Operations

### Deployment

| Attribute | Value |
|-----------|-------|
| **Container Image** | `[registry]/tjmsolns/[service]:[version]` |
| **Orchestration** | Kubernetes (GKE) |
| **Deployment Strategy** | [Rolling/Blue-Green/Canary] |
| **Namespace** | `[namespace]` |
| **Helm Chart** | [Yes/No], [Chart location if yes] |

### Environment Variables

| Variable | Purpose | Required | Default |
|----------|---------|----------|---------|
| `[VAR_NAME]` | [What it configures] | [Yes/No] | [Default value] |

**Example**: `KAFKA_BOOTSTRAP_SERVERS` | Kafka connection string | Yes | -

### Secrets

| Secret | Purpose | Source |
|--------|---------|--------|
| `[secret-name]` | [What credentials] | [e.g., Kubernetes Secret, GCP Secret Manager] |

### Runbooks

| Scenario | Priority | Runbook Link |
|----------|----------|--------------|
| [e.g., Service not starting] | P1 | [Link to runbook] |
| [e.g., High latency] | P2 | [Link to runbook] |
| [e.g., Event publishing failed] | P2 | [Link to runbook] |
| [e.g., Database connection failure] | P1 | [Link to runbook] |

### Maintenance Windows

- **Required**: [Yes/No]
- **Frequency**: [e.g., Monthly]
- **Duration**: [e.g., 30 minutes]
- **Schedule**: [e.g., First Sunday 02:00-02:30 UTC]

---

## Documentation

### Service Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| **README** | [Repo root] | Service overview, quick start |
| **API Specification** | `docs/API.md` or OpenAPI spec | Detailed API documentation |
| **Architecture** | `docs/ARCHITECTURE.md` | Detailed design and patterns |
| **Deployment** | `docs/DEPLOYMENT.md` | Deployment procedures |
| **Configuration** | `docs/CONFIGURATION.md` | Configuration reference |
| **Runbooks** | `docs/runbooks/` | Operational procedures |

### External Governance References

| Document | Link |
|----------|------|
| **Project Charter** | [TJMPaaS CHARTER.md](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/CHARTER.md) |
| **Roadmap** | [TJMPaaS ROADMAP.md](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/ROADMAP.md) |
| **ADRs** | [TJMPaaS ADRs](https://github.com/TJMSolns/TJMPaaS/tree/main/doc/internal/governance/ADRs) |
| **PDRs** | [TJMPaaS PDRs](https://github.com/TJMSolns/TJMPaaS/tree/main/doc/internal/governance/PDRs) |
| **Service Registry** | [TJMPaaS Service Registry](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/technical/services/REGISTRY.md) |

---

## Release History

| Version | Date | Changes | ADR/PDR |
|---------|------|---------|---------|
| 0.1.0 | YYYY-MM-DD | Initial release | - |

---

## Security

### Authentication & Authorization

- **Authentication**: [How service authenticates requests]
- **Authorization**: [How service authorizes actions]
- **Service-to-Service Auth**: [mTLS, JWT, API keys, etc.]

### Data Protection

- **Encryption at Rest**: [Yes/No], [Method if yes]
- **Encryption in Transit**: [TLS version]
- **PII/Sensitive Data**: [What data types, how protected]

### Security Scanning

- **Container Scanning**: [Tool, frequency]
- **Dependency Scanning**: [Tool, frequency]
- **SAST**: [Yes/No], [Tool if yes]

### Compliance

- **Requirements**: [e.g., PCI-DSS, GDPR, HIPAA, none]
- **Audit Logging**: [Yes/No], [What is logged]

---

## Testing

### Test Coverage

| Type | Target | Actual | Framework |
|------|--------|--------|-----------|
| **Unit** | > 80% | [X]% | [munit/scalatest] |
| **Integration** | > 70% | [X]% | [munit/scalatest] |
| **Actor Tests** | > 90% | [X]% | [ActorTestKit] |

### Test Types

| Type | Framework | CI Stage | Notes |
|------|-----------|----------|-------|
| **Unit** | [munit/scalatest] | Build | Fast, isolated tests |
| **Integration** | [munit/scalatest] | Build | External dependencies mocked |
| **Contract** | [Pact/custom] | Build | API contract validation |
| **End-to-End** | [custom] | Deploy | Full system tests |
| **Load** | [Gatling/k6] | Pre-Prod | Performance validation |

### Test Data

- **Approach**: [e.g., Fixtures, Factories, Test Containers]
- **Test DB**: [e.g., H2, PostgreSQL TestContainers]

---

## Disaster Recovery

### Backup Strategy

- **What**: [What data is backed up]
- **Frequency**: [How often]
- **Retention**: [How long]
- **Storage**: [Where backups stored]

### Recovery Objectives

- **RTO** (Recovery Time Objective): [e.g., 4 hours]
- **RPO** (Recovery Point Objective): [e.g., 1 hour]

### Failure Scenarios

| Scenario | Impact | Mitigation | Recovery |
|----------|--------|------------|----------|
| [e.g., Pod failure] | [Impact level] | [Auto-restart] | [Automatic, < 1 min] |
| [e.g., Database failure] | [Impact level] | [Circuit breaker, read replicas] | [Manual, < 30 min] |
| [e.g., Region outage] | [Impact level] | [Multi-region deployment] | [Failover, < 15 min] |

---

## Future Considerations

### Planned Enhancements

- [Feature or improvement planned]
- [Technical debt to address]

### Known Limitations

- [Current limitation]
- [Workaround if any]

### Deprecation Plans

- [Features/APIs planned for deprecation]
- [Timeline]

---

## Canvas Changelog

| Date | Change | Updated By |
|------|--------|------------|
| YYYY-MM-DD | Canvas created | [Name] |

---

**Note**: This canvas provides a single-page comprehensive overview. For detailed implementation, see service-specific documentation in the `docs/` directory. For project-wide governance, see [TJMPaaS repository](https://github.com/TJMSolns/TJMPaaS).
