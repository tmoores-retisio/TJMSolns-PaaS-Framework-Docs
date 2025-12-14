# Entity Management Service - Telemetry Specification

**Status**: Active  
**Version**: 1.0.0  
**Last Updated**: 2025-11-29  
**Template**: [TELEMETRY-SPECIFICATION.md](../../governance/templates/TELEMETRY-SPECIFICATION.md)

---

## Overview

This document defines the complete observability setup for Entity Management Service: metrics, logging, tracing, health checks, dashboards, and alerts.

**Observability Stack**:
- **Metrics**: Prometheus + Grafana
- **Logging**: Structured JSON logs → Loki
- **Tracing**: OpenTelemetry → Jaeger
- **Alerting**: Prometheus Alertmanager → PagerDuty

---

## Health Checks

### Liveness Probe

**Endpoint**: `GET /health/live`  
**Purpose**: Is the process alive?  
**Success**: 200 OK  
**Failure**: 503 Service Unavailable  
**Check Interval**: 10 seconds  
**Failure Threshold**: 3 consecutive failures → restart pod

```json
{
  "status": "UP",
  "timestamp": "2025-11-29T10:00:00Z"
}
```

### Readiness Probe

**Endpoint**: `GET /health/ready`  
**Purpose**: Can the service accept traffic?  
**Success**: 200 OK  
**Failure**: 503 Service Unavailable  
**Check Interval**: 5 seconds  
**Failure Threshold**: 3 consecutive failures → remove from load balancer

```json
{
  "status": "UP",
  "checks": {
    "database": "UP",
    "kafka": "UP",
    "redis": "UP",
    "actor_system": "UP"
  },
  "timestamp": "2025-11-29T10:00:00Z"
}
```

**Checks**:
- **database**: Can connect to PostgreSQL and execute query
- **kafka**: Can connect to Kafka brokers
- **redis**: Can connect to Redis (optional, service degraded without)
- **actor_system**: Actor system initialized and accepting messages

---

## Metrics (Prometheus)

### Business Metrics

**Tenant Metrics**:
```prometheus
# Total tenants
entity_tenants_total{service="entity-management"} 1250

# Organizations per tenant
entity_organizations_total{tenant_id="550e8400..."} 5

# Users per tenant
entity_users_total{tenant_id="550e8400..."} 42

# Invitations sent (counter)
entity_invitations_sent_total{tenant_id="550e8400..."} 15
```

**Feature Usage Metrics**:
```prometheus
# Feature usage by tenant
entity_feature_usage_total{tenant_id="550e8400...", feature="organization"} 10
entity_feature_usage_total{tenant_id="550e8400...", feature="user_invitation"} 15
```

### API Metrics

**Request Duration** (histogram):
```prometheus
# Query latency
http_request_duration_seconds{
  service="entity-management",
  tenant_id="550e8400...",
  method="GET",
  endpoint="/tenants/:id",
  status="200"
} histogram

# Buckets: 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0
# Labels: p50, p95, p99
```

**Request Count** (counter):
```prometheus
# Total requests
http_requests_total{
  service="entity-management",
  tenant_id="550e8400...",
  method="GET",
  endpoint="/tenants/:id",
  status="200"
} 1523
```

**Active Requests** (gauge):
```prometheus
# Concurrent requests
http_requests_in_flight{
  service="entity-management",
  tenant_id="550e8400..."
} 12
```

### Command and Event Metrics

**Commands Processed** (counter):
```prometheus
# Commands by type and result
entity_commands_processed_total{
  tenant_id="550e8400...",
  command_type="CreateOrganization",
  result="success"
} 45

entity_commands_processed_total{
  tenant_id="550e8400...",
  command_type="InviteUser",
  result="failure",
  failure_reason="quota_exceeded"
} 3
```

**Command Duration** (histogram):
```prometheus
# Command processing latency
entity_command_duration_seconds{
  tenant_id="550e8400...",
  command_type="CreateOrganization"
} histogram
```

**Events Published** (counter):
```prometheus
# Events by type
entity_events_published_total{
  tenant_id="550e8400...",
  event_type="OrganizationCreated"
} 45

entity_events_published_total{
  tenant_id="550e8400...",
  event_type="UserInvited"
} 15
```

**Event Publishing Latency** (histogram):
```prometheus
# Time from event persistence to Kafka publish
entity_event_publish_duration_seconds{
  tenant_id="550e8400...",
  event_type="OrganizationCreated"
} histogram
```

### Actor System Metrics

**Actor Count** (gauge):
```prometheus
# Active actors by type
pekko_actor_count{
  service="entity-management",
  tenant_id="550e8400...",
  actor_type="TenantActor"
} 1

pekko_actor_count{
  service="entity-management",
  tenant_id="550e8400...",
  actor_type="OrganizationActor"
} 5
```

**Mailbox Depth** (gauge):
```prometheus
# Messages waiting in mailbox
pekko_actor_mailbox_size{
  service="entity-management",
  tenant_id="550e8400...",
  actor_type="TenantActor",
  actor_id="tenant-550e8400..."
} 3
```

**Messages Processed** (counter):
```prometheus
# Total messages processed
pekko_actor_messages_processed_total{
  service="entity-management",
  tenant_id="550e8400...",
  actor_type="TenantActor"
} 1523
```

**Actor Restarts** (counter):
```prometheus
# Actor supervision restarts
pekko_actor_restarts_total{
  service="entity-management",
  tenant_id="550e8400...",
  actor_type="TenantActor",
  reason="exception"
} 2
```

### Database Metrics

**Connection Pool** (gauge):
```prometheus
# Active/idle connections
database_connection_pool_active{service="entity-management"} 15
database_connection_pool_idle{service="entity-management"} 35
database_connection_pool_size{service="entity-management"} 50
```

**Query Duration** (histogram):
```prometheus
# Query latency by query type
database_query_duration_seconds{
  service="entity-management",
  query_type="select_tenant"
} histogram
```

### JVM Metrics

```prometheus
# Memory usage
jvm_memory_used_bytes{area="heap"} 536870912
jvm_memory_max_bytes{area="heap"} 2147483648

# GC stats
jvm_gc_pause_seconds_sum 5.2
jvm_gc_pause_seconds_count 42

# Thread count
jvm_threads_current 45
jvm_threads_peak 67
```

---

## Logging (Structured JSON)

### Log Format

```json
{
  "timestamp": "2025-11-29T10:00:00.123Z",
  "level": "INFO",
  "service": "entity-management-service",
  "version": "1.0.0",
  "environment": "prod",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "trace_id": "abc123",
  "span_id": "def456",
  "user_id": "750e8400-e29b-41d4-a716-446655440000",
  "message": "Organization created successfully",
  "context": {
    "organization_id": "650e8400-e29b-41d4-a716-446655440000",
    "organization_name": "Engineering Department",
    "command_type": "CreateOrganization",
    "duration_ms": 45
  }
}
```

### Log Levels

**DEBUG**: Actor message processing details, internal state changes.
```json
{
  "level": "DEBUG",
  "message": "Actor processing command",
  "context": {
    "actor_id": "tenant-550e8400...",
    "actor_type": "TenantActor",
    "command_type": "CreateOrganization",
    "mailbox_size": 3
  }
}
```

**INFO**: API requests, commands processed, events published.
```json
{
  "level": "INFO",
  "message": "Command processed successfully",
  "context": {
    "command_type": "InviteUser",
    "user_email": "alice@acme.com",
    "duration_ms": 120
  }
}
```

**WARN**: Rate limit exceeded, validation warnings, degraded service.
```json
{
  "level": "WARN",
  "message": "Rate limit exceeded for tenant",
  "context": {
    "tenant_id": "550e8400...",
    "tier": "bronze",
    "limit": 1000,
    "current": 1001
  }
}
```

**ERROR**: Command failures, event publishing failures, exceptions.
```json
{
  "level": "ERROR",
  "message": "Failed to publish event to Kafka",
  "context": {
    "event_type": "UserInvited",
    "event_id": "abc123",
    "error": "Connection timeout",
    "retry_count": 3
  },
  "exception": {
    "type": "org.apache.kafka.common.errors.TimeoutException",
    "message": "Failed to send message to topic entity-events",
    "stacktrace": "..."
  }
}
```

### Log Aggregation

**Queries**:
```
# All errors in last hour
{service="entity-management"} | json | level="ERROR" | __timestamp__ > now() - 1h

# Commands by tenant
{service="entity-management"} | json | tenant_id="550e8400..." | message =~ "Command.*"

# Slow queries (>500ms)
{service="entity-management"} | json | context_duration_ms > 500

# Multi-tenant isolation violations
{service="entity-management"} | json | message =~ "tenant.*mismatch"
```

---

## Distributed Tracing (OpenTelemetry)

### Trace Spans

**API Request Span** (root):
```
Span: http_request
  service: entity-management
  operation: POST /tenants/{tenantId}/organizations
  tenant_id: 550e8400...
  user_id: 750e8400...
  duration: 235ms
  status: OK
```

**Command Processing Span**:
```
Span: command_processing
  parent: http_request
  command_type: CreateOrganization
  actor_id: tenant-550e8400...
  duration: 180ms
  status: OK
```

**Event Persistence Span**:
```
Span: event_persistence
  parent: command_processing
  event_type: OrganizationCreated
  event_id: abc123
  duration: 45ms
  status: OK
```

**Event Publishing Span**:
```
Span: event_publishing
  parent: command_processing
  event_type: OrganizationCreated
  kafka_topic: entity-events
  kafka_partition: 3
  duration: 15ms
  status: OK
```

**Database Query Span**:
```
Span: database_query
  parent: command_processing
  query_type: insert_organization_view
  duration: 12ms
  status: OK
```

### Trace Attributes

**Required on all spans**:
- `service.name`: "entity-management-service"
- `service.version`: "1.0.0"
- `deployment.environment`: "prod"
- `tenant_id`: Tenant identifier
- `trace_id`: Distributed trace ID
- `span_id`: Span identifier
- `parent_span_id`: Parent span ID (if any)

**Optional**:
- `user_id`: Authenticated user
- `resource_id`: Entity ID being operated on
- `actor_id`: Actor instance identifier

---

## Dashboards (Grafana)

### Service Overview Dashboard

**Panels**:
1. **Request Rate**: Requests per second (by endpoint)
2. **Latency**: P50/P95/P99 (by endpoint)
3. **Error Rate**: 5xx errors percentage
4. **Active Tenants**: Unique tenants in last hour
5. **Actor Count**: Total active actors (by type)
6. **Event Throughput**: Events per second

**Filters**: Environment, time range

### Per-Tenant Dashboard

**Panels**:
1. **Request Rate**: Tenant-specific requests per second
2. **Latency vs SLA**: Tenant latency vs SLA target (by tier)
3. **Error Rate**: Tenant-specific error percentage
4. **Resource Consumption**: Organizations, teams, users counts
5. **Quota Usage**: API calls vs limit, invitations vs limit
6. **Commands**: Commands by type (bar chart)

**Filters**: Tenant ID, time range

### Actor System Dashboard

**Panels**:
1. **Actor Count**: Actors by type (stacked area)
2. **Message Throughput**: Messages per second (by actor type)
3. **Mailbox Depth**: Distribution (histogram)
4. **Actor Restarts**: Restarts per minute (by reason)
5. **Message Processing Latency**: P95 by actor type
6. **Sharding**: Actors per shard distribution

### Database Dashboard

**Panels**:
1. **Connection Pool**: Active/idle connections
2. **Query Latency**: P95 by query type
3. **Slow Queries**: Queries >500ms (table)
4. **Transaction Rate**: Transactions per second
5. **Deadlocks**: Deadlock count (should be 0)

### Multi-Tenant Isolation Dashboard

**Panels**:
1. **Isolation Violations**: Count (should be 0)
2. **Cross-Tenant Access Attempts**: Blocked attempts
3. **Seam Validation**: Test results by seam level
4. **Tenant ID Mismatches**: Header vs JWT mismatches

---

## Alerts (Prometheus Alertmanager)

### Critical Alerts (Page On-Call)

**ServiceDown**:
```yaml
alert: EntityManagementServiceDown
expr: up{service="entity-management"} == 0
for: 3m
severity: critical
annotations:
  summary: "Entity Management Service is down"
  description: "Service has been down for more than 3 minutes"
```

**HighErrorRate**:
```yaml
alert: EntityManagementHighErrorRate
expr: (rate(http_requests_total{service="entity-management",status=~"5.."}[5m]) / rate(http_requests_total{service="entity-management"}[5m])) > 0.05
for: 5m
severity: critical
annotations:
  summary: "High error rate (>5%)"
  description: "Error rate is {{ $value | humanizePercentage }}"
```

**DatabaseConnectionPoolExhausted**:
```yaml
alert: EntityManagementDBPoolExhausted
expr: database_connection_pool_active{service="entity-management"} / database_connection_pool_size{service="entity-management"} > 0.9
for: 5m
severity: critical
annotations:
  summary: "Database connection pool >90% utilized"
```

**ActorRestartLoop**:
```yaml
alert: EntityManagementActorRestartLoop
expr: rate(pekko_actor_restarts_total{service="entity-management"}[1m]) > 10
for: 5m
severity: critical
annotations:
  summary: "Actor restart rate >10/minute"
  description: "Actor type: {{ $labels.actor_type }}, Reason: {{ $labels.reason }}"
```

**MultiTenantIsolationViolation**:
```yaml
alert: EntityManagementIsolationViolation
expr: increase(entity_isolation_violations_total{service="entity-management"}[5m]) > 0
for: 1m
severity: critical
annotations:
  summary: "Multi-tenant isolation violation detected"
  description: "SECURITY: Cross-tenant access attempt detected"
```

### Warning Alerts (Investigate)

**HighLatency**:
```yaml
alert: EntityManagementHighLatency
expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service="entity-management"}[5m])) > 0.5
for: 5m
severity: warning
annotations:
  summary: "High latency (P95 >500ms)"
```

**TenantSLAViolation**:
```yaml
alert: EntityManagementTenantSLAViolation
expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service="entity-management",tenant_id=~".+"}[5m])) > on(tenant_id) sla_target_seconds
for: 5m
severity: warning
annotations:
  summary: "Tenant SLA violation"
  description: "Tenant {{ $labels.tenant_id }} exceeding SLA target"
```

**HighMailboxDepth**:
```yaml
alert: EntityManagementHighMailboxDepth
expr: pekko_actor_mailbox_size{service="entity-management"} > 1000
for: 10m
severity: warning
annotations:
  summary: "High actor mailbox depth (>1000 messages)"
```

**EventPublishingLag**:
```yaml
alert: EntityManagementEventLag
expr: entity_event_publish_duration_seconds > 1.0
for: 5m
severity: warning
annotations:
  summary: "Event publishing lag >1 second"
```

---

## Alerting Runbooks

### HighErrorRate

**Symptoms**: Error rate >5% for 5 minutes.

**Investigation**:
1. Check logs: `kubectl logs deployment/entity-management | grep ERROR`
2. Identify error types: Group by error message
3. Check external dependencies: Database, Kafka, Redis
4. Check recent deployments: Was there a recent change?

**Mitigation**:
- If database issue: Scale read replicas, check slow queries
- If Kafka issue: Check broker health, consumer lag
- If deployment issue: Rollback to previous version

### ActorRestartLoop

**Symptoms**: >10 actor restarts per minute.

**Investigation**:
1. Check supervision logs: Identify failing actor type and messages
2. Review recent events: What message caused failure?
3. Check for data corruption: Inspect event store for problematic events

**Mitigation**:
- Add validation for problematic message type
- Skip corrupted event (add to DLQ)
- Hotfix and redeploy

### MultiTenantIsolationViolation

**Symptoms**: Cross-tenant access detected.

**Investigation** (URGENT):
1. Alert security team immediately
2. Identify affected tenants from logs
3. Review audit trail for both tenants
4. Determine if code bug or malicious

**Mitigation**:
- If bug: Hotfix and immediate deployment
- If malicious: Block user, notify affected tenant
- Document incident for post-mortem

---

## Related Documentation

- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md)
- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md)
- [SECURITY-REQUIREMENTS.md](./SECURITY-REQUIREMENTS.md)

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-29 | Initial telemetry spec | Platform Team |
