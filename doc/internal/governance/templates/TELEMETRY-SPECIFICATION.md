# {Service Name} Telemetry Specification

**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Template Version**: 1.0

---

**Instructions**: Copy this template to service repository `docs/TELEMETRY-SPECIFICATION.md`. This defines observability requirements: metrics, logs, traces, dashboards, and alerts.

---

## Overview

**Service**: {Service Name}  
**Telemetry Stack**:
- **Metrics**: Prometheus
- **Logs**: Structured JSON logging
- **Traces**: OpenTelemetry
- **Dashboards**: Grafana
- **Alerts**: Prometheus Alertmanager

## Metrics

### Service-Level Metrics

**HTTP Request Metrics**:
```scala
// Request counter
metrics.counter("http.requests.total")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("method", request.method.name)
  .tag("path", request.uri.path.toString)
  .tag("status", response.status.code.toString)
  .increment()

// Request duration histogram
metrics.timer("http.requests.duration.seconds")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("method", request.method.name)
  .tag("path", request.uri.path.toString)
  .record(duration)
```

**Metric Details**:
| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| `http_requests_total` | Counter | service, tenant_id, method, path, status | Total HTTP requests |
| `http_requests_duration_seconds` | Histogram | service, tenant_id, method, path | Request latency distribution |
| `http_requests_in_flight` | Gauge | service, tenant_id | Currently processing requests |

**Actor Metrics**:
```scala
// Active actors gauge
metrics.gauge("actors.active")
  .tag("service", "{service-name}")
  .tag("actor_type", actorType)
  .tag("tenant_id", tenantId.toString)
  .set(activeActorCount)

// Actor message processing
metrics.counter("actors.messages.processed")
  .tag("service", "{service-name}")
  .tag("actor_type", actorType)
  .tag("message_type", messageType)
  .tag("tenant_id", tenantId.toString)
  .increment()

// Actor message duration
metrics.timer("actors.messages.duration.seconds")
  .tag("service", "{service-name}")
  .tag("actor_type", actorType)
  .tag("message_type", messageType)
  .tag("tenant_id", tenantId.toString)
  .record(duration)

// Actor mailbox size
metrics.gauge("actors.mailbox.size")
  .tag("service", "{service-name}")
  .tag("actor_type", actorType)
  .tag("tenant_id", tenantId.toString)
  .set(mailboxSize)
```

**Metric Details**:
| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| `actors_active` | Gauge | service, actor_type, tenant_id | Number of active actors |
| `actors_messages_processed_total` | Counter | service, actor_type, message_type, tenant_id | Messages processed |
| `actors_messages_duration_seconds` | Histogram | service, actor_type, message_type, tenant_id | Message processing latency |
| `actors_mailbox_size` | Gauge | service, actor_type, tenant_id | Messages queued in mailbox |

**Command/Query Metrics (CQRS)**:
```scala
// Command success/failure
metrics.counter("commands.total")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("command_type", commandType)
  .tag("success", success.toString)
  .increment()

// Command duration
metrics.timer("commands.duration.seconds")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("command_type", commandType)
  .record(duration)

// Query metrics (similar structure)
metrics.counter("queries.total")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("query_type", queryType)
  .increment()
```

**Event Metrics**:
```scala
// Events persisted
metrics.counter("events.persisted.total")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("event_type", eventType)
  .increment()

// Events published to Kafka
metrics.counter("events.published.total")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("event_type", eventType)
  .tag("topic", kafkaTopic)
  .increment()

// Event publishing lag
metrics.timer("events.publish.lag.seconds")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .record(lagDuration)
```

**Kafka Consumer Metrics**:
```scala
// Kafka consumer lag
metrics.gauge("kafka.consumer.lag")
  .tag("service", "{service-name}")
  .tag("group_id", consumerGroupId)
  .tag("topic", topic)
  .tag("partition", partition.toString)
  .set(lag)

// Messages consumed
metrics.counter("kafka.consumer.messages.total")
  .tag("service", "{service-name}")
  .tag("topic", topic)
  .increment()
```

**Database Metrics**:
```scala
// Database connection pool
metrics.gauge("db.connection_pool.active")
  .tag("service", "{service-name}")
  .set(activeConnections)

metrics.gauge("db.connection_pool.idle")
  .tag("service", "{service-name}")
  .set(idleConnections)

// Database query duration
metrics.timer("db.query.duration.seconds")
  .tag("service", "{service-name}")
  .tag("query_type", queryType)
  .record(duration)
```

**Multi-Tenant Metrics**:
```scala
// Resources per tenant
metrics.gauge("resources.total")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("resource_type", resourceType)
  .set(resourceCount)

// API rate limit violations
metrics.counter("rate_limit.violations.total")
  .tag("service", "{service-name}")
  .tag("tenant_id", tenantId.toString)
  .tag("tier", subscriptionTier)
  .increment()
```

### JVM Metrics

**Standard JVM metrics** (via Prometheus JVM client or Micrometer):
- `jvm_memory_used_bytes`
- `jvm_memory_max_bytes`
- `jvm_gc_pause_seconds`
- `jvm_threads_live`
- `jvm_classes_loaded`

### Prometheus Exposition

**Endpoint**: `/metrics`  
**Format**: Prometheus text format

**Example metrics output**:
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{service="entity-management",tenant_id="123",method="GET",path="/api/v1/tenants",status="200"} 1523

# HELP http_requests_duration_seconds HTTP request latency
# TYPE http_requests_duration_seconds histogram
http_requests_duration_seconds_bucket{service="entity-management",tenant_id="123",method="GET",path="/api/v1/tenants",le="0.01"} 1200
http_requests_duration_seconds_bucket{service="entity-management",tenant_id="123",method="GET",path="/api/v1/tenants",le="0.05"} 1500
http_requests_duration_seconds_bucket{service="entity-management",tenant_id="123",method="GET",path="/api/v1/tenants",le="0.1"} 1520
http_requests_duration_seconds_bucket{service="entity-management",tenant_id="123",method="GET",path="/api/v1/tenants",le="+Inf"} 1523
http_requests_duration_seconds_sum{service="entity-management",tenant_id="123",method="GET",path="/api/v1/tenants"} 45.2
http_requests_duration_seconds_count{service="entity-management",tenant_id="123",method="GET",path="/api/v1/tenants"} 1523
```

## Logging

### Log Format

**Structured JSON logging**:
```json
{
  "timestamp": "2025-01-15T10:30:45.123Z",
  "level": "INFO",
  "service": "{service-name}",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "user_id": "660e8400-e29b-41d4-a716-446655440000",
  "request_id": "770e8400-e29b-41d4-a716-446655440000",
  "actor_type": "TenantActor",
  "actor_id": "tenant-550e8400",
  "message_type": "CreateTenant",
  "message": "Tenant created successfully",
  "duration_ms": 45,
  "details": {
    "tenant_name": "Acme Corp",
    "subscription_plan": "gold"
  }
}
```

### Log Levels

| Level | When to Use | Examples |
|-------|-------------|----------|
| ERROR | Unexpected errors, failures | Exception thrown, external service unavailable |
| WARN | Recoverable issues, deprecations | Retry attempted, deprecated API used |
| INFO | Normal operations, state changes | Tenant created, user assigned, event published |
| DEBUG | Detailed diagnostics | Message received, validation passed, state transition |
| TRACE | Very detailed diagnostics | Message serialization, DB query executed |

### Log Events

**Request/Response Logging**:
```scala
logger.info(
  "HTTP request processed",
  "tenant_id" -> tenantId,
  "method" -> request.method.name,
  "path" -> request.uri.path,
  "status" -> response.status.code,
  "duration_ms" -> duration.toMillis,
  "request_id" -> requestId,
  "user_id" -> userId
)
```

**Command Processing Logging**:
```scala
logger.info(
  "Command processed",
  "tenant_id" -> tenantId,
  "command_type" -> cmd.getClass.getSimpleName,
  "actor_type" -> "TenantActor",
  "actor_id" -> actorId,
  "success" -> success,
  "duration_ms" -> duration.toMillis,
  "details" -> details.asJson
)
```

**Event Logging**:
```scala
logger.info(
  "Event persisted",
  "tenant_id" -> tenantId,
  "event_type" -> event.getClass.getSimpleName,
  "persistence_id" -> persistenceId,
  "sequence_number" -> sequenceNr,
  "timestamp" -> timestamp.toString
)

logger.info(
  "Event published",
  "tenant_id" -> tenantId,
  "event_type" -> event.getClass.getSimpleName,
  "kafka_topic" -> topic,
  "kafka_partition" -> partition,
  "kafka_offset" -> offset
)
```

**Error Logging**:
```scala
logger.error(
  "Command failed",
  "tenant_id" -> tenantId,
  "command_type" -> cmd.getClass.getSimpleName,
  "error_code" -> errorCode,
  "error_message" -> errorMessage,
  "stack_trace" -> exception.getStackTrace.mkString("\n")
)
```

### Log Aggregation

**Log Collection**: Fluentd/Fluent Bit  
**Log Storage**: Elasticsearch  
**Log Visualization**: Kibana

**Kubernetes Logging**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: {service-name}
spec:
  containers:
  - name: {service-name}
    image: gcr.io/{project}/{service-name}:latest
    env:
    - name: LOG_LEVEL
      value: "INFO"
    - name: LOG_FORMAT
      value: "json"
```

## Distributed Tracing

### OpenTelemetry Configuration

**Trace Context Propagation**:
- W3C Trace Context headers (`traceparent`, `tracestate`)
- Propagate through HTTP requests, Kafka messages, actor messages

**Instrumentation**:
```scala
import io.opentelemetry.api.trace.{Span, StatusCode, Tracer}
import io.opentelemetry.api.trace.attributes.SemanticAttributes

// HTTP request span
val span = tracer.spanBuilder("HTTP {method} {path}")
  .setSpanKind(SpanKind.SERVER)
  .setAttribute(SemanticAttributes.HTTP_METHOD, method)
  .setAttribute(SemanticAttributes.HTTP_TARGET, path)
  .setAttribute("tenant_id", tenantId.toString)
  .startSpan()

try {
  // Process request
  val response = handleRequest(request)
  span.setStatus(StatusCode.OK)
  span.setAttribute(SemanticAttributes.HTTP_STATUS_CODE, response.status.code)
  response
} catch {
  case ex: Exception =>
    span.setStatus(StatusCode.ERROR, ex.getMessage)
    span.recordException(ex)
    throw ex
} finally {
  span.end()
}
```

**Actor Message Span**:
```scala
// Extract parent span context from message
val parentContext = message.traceContext.getOrElse(Context.current())

val span = tracer.spanBuilder("Actor.{MessageType}")
  .setParent(parentContext)
  .setSpanKind(SpanKind.INTERNAL)
  .setAttribute("actor.type", actorType)
  .setAttribute("actor.id", actorId.toString)
  .setAttribute("message.type", messageType)
  .setAttribute("tenant_id", tenantId.toString)
  .startSpan()

// Process message
// ...

span.end()
```

**Kafka Message Span**:
```scala
// Producer: Inject trace context into Kafka headers
val span = tracer.spanBuilder("Kafka.Publish")
  .setSpanKind(SpanKind.PRODUCER)
  .setAttribute("messaging.system", "kafka")
  .setAttribute("messaging.destination", topic)
  .setAttribute("tenant_id", tenantId.toString)
  .startSpan()

val headers = new RecordHeaders()
propagator.inject(Context.current().`with`(span), headers, headerSetter)

producer.send(new ProducerRecord(topic, key, value, headers))
span.end()

// Consumer: Extract trace context from Kafka headers
val parentContext = propagator.extract(Context.current(), record.headers(), headerGetter)

val span = tracer.spanBuilder("Kafka.Consume")
  .setParent(parentContext)
  .setSpanKind(SpanKind.CONSUMER)
  .setAttribute("messaging.system", "kafka")
  .setAttribute("messaging.source", topic)
  .startSpan()

// Process message
// ...

span.end()
```

### Trace Sampling

**Sampling Strategy**:
- **Production**: 10% sampling (adaptive based on error rate)
- **Staging**: 50% sampling
- **Development**: 100% sampling

**Sampler Configuration**:
```scala
SamplerConfig(
  parentBased = true,
  rootSampler = TraceIdRatioBased(0.1), // 10%
  errorSampling = Always // Always sample traces with errors
)
```

### Trace Backend

**Jaeger** (or equivalent):
- UI: `https://jaeger.{domain}`
- Query traces by trace ID, service, operation, tags

**Example Queries**:
- All traces for tenant: `tenant_id=550e8400-e29b-41d4-a716-446655440000`
- Slow traces: `duration > 1s`
- Error traces: `error=true`

## Dashboards

### Grafana Dashboard Structure

**Dashboard 1: Service Overview**

**Panels**:
1. **Request Rate** (time series)
   - Query: `rate(http_requests_total{service="{service-name}"}[5m])`
   - Grouped by: `tenant_id`, `path`, `method`

2. **Error Rate** (time series + gauge)
   - Query: `rate(http_requests_total{service="{service-name}",status=~"5.."}[5m]) / rate(http_requests_total{service="{service-name}"}[5m])`
   - Alert threshold: >5%

3. **Latency (P50, P95, P99)** (time series)
   - Query: `histogram_quantile(0.95, rate(http_requests_duration_seconds_bucket{service="{service-name}"}[5m]))`
   - Thresholds: P95 <100ms (green), <200ms (yellow), >200ms (red)

4. **Active Actors** (gauge)
   - Query: `actors_active{service="{service-name}"}`
   - Grouped by: `actor_type`, `tenant_id`

5. **Command Success Rate** (time series)
   - Query: `rate(commands_total{service="{service-name}",success="true"}[5m]) / rate(commands_total{service="{service-name}"}[5m])`

6. **Event Publishing Rate** (time series)
   - Query: `rate(events_published_total{service="{service-name}"}[5m])`
   - Grouped by: `event_type`, `topic`

7. **Kafka Consumer Lag** (time series)
   - Query: `kafka_consumer_lag{service="{service-name}"}`
   - Alert threshold: >1000 messages

8. **Resource Usage** (time series)
   - CPU: `rate(container_cpu_usage_seconds_total{pod=~"{service-name}.*"}[5m])`
   - Memory: `container_memory_working_set_bytes{pod=~"{service-name}.*"}`

**Dashboard 2: Multi-Tenant View**

**Panels**:
1. **Requests by Tenant** (table)
   - Query: `topk(10, sum by (tenant_id) (rate(http_requests_total{service="{service-name}"}[5m])))`

2. **Error Rate by Tenant** (heatmap)
   - Query: `sum by (tenant_id) (rate(http_requests_total{service="{service-name}",status=~"5.."}[5m]))`

3. **Resources by Tenant** (bar gauge)
   - Query: `resources_total{service="{service-name}"}`
   - Grouped by: `tenant_id`, `resource_type`

4. **Rate Limit Violations by Tenant** (time series)
   - Query: `rate(rate_limit_violations_total{service="{service-name}"}[5m])`
   - Grouped by: `tenant_id`, `tier`

**Dashboard 3: Actor System**

**Panels**:
1. **Active Actors by Type** (graph)
2. **Message Processing Rate** (graph)
3. **Message Duration P95** (graph)
4. **Mailbox Size** (graph)
5. **Actor Restarts** (graph)

**Dashboard Export**:
```bash
# Export dashboard JSON
curl -H "Authorization: Bearer {api-key}" \
  https://grafana.{domain}/api/dashboards/uid/{dashboard-uid} \
  > k8s/grafana-dashboard-{service-name}.json
```

## Alerts

### Alerting Rules

**Critical Alerts** (PagerDuty/immediate notification):

```yaml
- alert: ServiceDown
  expr: up{service="{service-name}"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "{service-name} is down"
    description: "No instances of {service-name} are reachable"
    runbook: "https://docs.{domain}/runbooks/{service-name}/service-down"

- alert: HighErrorRate
  expr: |
    rate(http_requests_total{service="{service-name}",status=~"5.."}[5m])
    / rate(http_requests_total{service="{service-name}"}[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate in {service-name}"
    description: "Error rate is {{ $value | humanizePercentage }}"
    runbook: "https://docs.{domain}/runbooks/{service-name}/high-error-rate"

- alert: MultiTenantIsolationViolation
  expr: |
    sum(rate(cross_tenant_access_attempts_total{service="{service-name}"}[5m])) > 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Multi-tenant isolation violation detected"
    description: "Cross-tenant access attempts detected in {service-name}"
    runbook: "https://docs.{domain}/runbooks/{service-name}/isolation-violation"
```

**Warning Alerts** (Slack/email notification):

```yaml
- alert: HighLatency
  expr: |
    histogram_quantile(0.95, 
      rate(http_requests_duration_seconds_bucket{service="{service-name}"}[5m])
    ) > 1.0
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High latency in {service-name}"
    description: "P95 latency is {{ $value }}s"

- alert: KafkaConsumerLag
  expr: kafka_consumer_lag{service="{service-name}"} > 1000
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "Kafka consumer lag high for {service-name}"
    description: "Lag is {{ $value }} messages"

- alert: HighActorMailboxSize
  expr: actors_mailbox_size{service="{service-name}"} > 1000
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High actor mailbox size in {service-name}"
    description: "Mailbox size is {{ $value }} for {{ $labels.actor_type }}"
```

### Alert Routing

**Alertmanager Configuration**:
```yaml
route:
  receiver: 'default'
  group_by: ['alertname', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  
  routes:
  - match:
      severity: critical
      service: {service-name}
    receiver: 'pagerduty-critical'
  
  - match:
      severity: warning
      service: {service-name}
    receiver: 'slack-warnings'

receivers:
- name: 'pagerduty-critical'
  pagerduty_configs:
  - service_key: '{pagerduty-key}'

- name: 'slack-warnings'
  slack_configs:
  - api_url: '{slack-webhook}'
    channel: '#alerts-{service-name}'
```

## SLOs and SLIs

### Service Level Indicators (SLIs)

| SLI | Target | Measurement |
|-----|--------|-------------|
| Availability | 99.9% | `sum(rate(http_requests_total{status!~"5.."}[30d])) / sum(rate(http_requests_total[30d]))` |
| Latency (P95) | <200ms | `histogram_quantile(0.95, rate(http_requests_duration_seconds_bucket[5m]))` |
| Error Rate | <1% | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))` |
| Command Success Rate | >99% | `sum(rate(commands_total{success="true"}[5m])) / sum(rate(commands_total[5m]))` |

### Error Budget

**Monthly Error Budget** (99.9% availability):
- Total time: 730 hours
- Allowed downtime: 43.8 minutes
- Error budget: 0.1% of requests

**Error Budget Alerts**:
```yaml
- alert: ErrorBudgetExhausted
  expr: |
    (1 - sum(rate(http_requests_total{status!~"5.."}[30d])) / sum(rate(http_requests_total[30d]))) > 0.001
  for: 1h
  labels:
    severity: critical
  annotations:
    summary: "Error budget exhausted for {service-name}"
    description: "Error budget consumption is {{ $value | humanizePercentage }}"
```

## Related Documentation

- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) - Operational procedures
- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Architecture details

## Revision History

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial telemetry specification | {Name} |
