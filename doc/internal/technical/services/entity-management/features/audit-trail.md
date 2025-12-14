# Feature: Comprehensive Audit Trail

**Feature ID**: EMS-F005  
**Status**: Planned  
**Priority**: Critical (P0)  
**Seam Levels**: All seams (cross-cutting concern)

## Overview

Comprehensive Audit Trail provides immutable logging of all entity changes, authentication events, authorization decisions, and security incidents for compliance, security monitoring, and incident investigation.

## Business Context

**Problem**: Regulatory compliance (SOC2, HIPAA, GDPR) requires complete audit trails of data access and modifications with 7-year retention.

**Solution**: Event-sourced audit log capturing all state changes, access attempts, and security events in an immutable, queryable format.

**Value**: Enables compliance with regulatory requirements; supports security incident investigation; provides accountability for all actions.

## User Stories

**US-014**: As a compliance officer, I want complete audit logs so that I can demonstrate regulatory compliance.

**US-015**: As a security analyst, I want to query audit logs so that I can investigate security incidents.

**US-016**: As a system, I want immutable audit logs so that tampering is prevented.

## Functional Requirements

### Audit Event Types

**Authentication Events**:
- `audit.auth.success` - Successful authentication
- `audit.auth.failed` - Failed authentication attempt
- `audit.auth.token_refresh` - JWT token refreshed
- `audit.auth.logout` - User logout

**Authorization Events**:
- `audit.authz.permission_denied` - Permission check failed
- `audit.security.cross_tenant_access` - Cross-tenant access attempt

**Data Modification Events**:
- `audit.tenant.created` - Tenant provisioned
- `audit.organization.created` - Organization created
- `audit.organization.updated` - Organization modified
- `audit.organization.deleted` - Organization deleted
- `audit.user.created` - User created
- `audit.user.role_changed` - User role updated
- `audit.user.deactivated` - User deactivated
- `audit.role.created` - Custom role created
- `audit.role.permissions_updated` - Role permissions changed

**Data Access Events**:
- `audit.data.pii_accessed` - PII data viewed
- `audit.data.sensitive_export` - Sensitive data exported

### Audit Event Schema

**Standard Format**:
```json
{
  "event_id": "aa0e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-01-15T10:30:45.123Z",
  "event_type": "audit.tenant.created",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "660e8400-e29b-41d4-a716-446655440000",
  "user_email": "admin@acme.example.com",
  "action": "CREATE",
  "resource_type": "tenant",
  "resource_id": "550e8400-e29b-41d4-a716-446655440000",
  "request_id": "770e8400-e29b-41d4-a716-446655440000",
  "ip_address": "203.0.113.42",
  "user_agent": "Mozilla/5.0 ...",
  "details": {
    "tenant_name": "Acme Corp",
    "subscription_plan": "gold"
  },
  "result": "success",
  "error_code": null,
  "severity": "info"
}
```

**Field Descriptions**:
- `event_id`: Unique identifier for this audit event (UUID)
- `timestamp`: ISO 8601 timestamp with millisecond precision
- `event_type`: Structured event type (see list above)
- `tenant_id`: Tenant context for the action
- `user_id`: User who performed the action
- `user_email`: User email (for human readability)
- `action`: CRUD operation (CREATE, READ, UPDATE, DELETE)
- `resource_type`: Type of resource affected (tenant, organization, user, role)
- `resource_id`: Unique ID of affected resource
- `request_id`: Correlation ID for distributed tracing
- `ip_address`: Source IP of request
- `user_agent`: Client user agent string
- `details`: Event-specific additional data (JSON object)
- `result`: "success" or "failure"
- `error_code`: If failure, structured error code
- `severity`: info, warning, error, critical

### Query API

**Query by Tenant**:
```
GET /api/v1/audit?tenant_id={tenant_id}&limit=100&offset=0
```

**Query by User**:
```
GET /api/v1/audit?user_id={user_id}&limit=100&offset=0
```

**Query by Date Range**:
```
GET /api/v1/audit?start_date=2025-01-01&end_date=2025-01-31
```

**Query by Event Type**:
```
GET /api/v1/audit?event_type=audit.security.cross_tenant_access
```

**Combined Filters**:
```
GET /api/v1/audit?tenant_id={id}&start_date=2025-01-01&event_type=audit.user.created
```

### Storage Requirements

**Immutability**:
- Audit events stored in append-only event store
- No updates or deletes allowed
- Attempted modifications trigger security alerts

**Retention**:
- 7-year retention for compliance (SOC2, HIPAA, GDPR)
- Hot storage: 90 days (fast queries)
- Warm storage: 1 year (moderate query speed)
- Cold storage: 7 years (archival, slower queries)

**Storage Backend**:
- Primary: PostgreSQL with append-only table (or EventStoreDB)
- Archive: S3/GCS with Glacier/Coldline storage class
- Indexing: Elasticsearch for fast full-text search

## Multi-Tenant Considerations

**Tenant Isolation in Audit Logs**:
- All audit events include `tenant_id`
- Query API filters by tenant_id automatically
- Cross-tenant audit queries blocked (except platform admin)

**Security Event Monitoring**:
- Cross-tenant access attempts logged with high severity
- Automated alerts for suspicious patterns
- Security team can query across tenants

## Non-Functional Requirements

- **Performance**: Audit event write <10ms P95 (non-blocking)
- **Availability**: 99.99% (audit logging must not fail)
- **Durability**: Zero audit event loss (durable storage)
- **Queryability**: Audit queries return in <1s P95

## Architecture

**Async Audit Logging**:
```scala
trait AuditLogger {
  def log(event: AuditEvent): Future[Unit]
}

class KafkaAuditLogger(producer: KafkaProducer) extends AuditLogger {
  def log(event: AuditEvent): Future[Unit] = {
    val record = new ProducerRecord(
      "audit-events",
      event.tenantId.toString,  // Key for partitioning
      event.toJson
    )
    producer.send(record).toScala.map(_ => ())
  }
}

// Usage in command handler
def handleCommand(cmd: CreateTenant): Effect[Event, State] = {
  Effect.persist(TenantCreated(...))
    .thenRun { _ =>
      auditLogger.log(AuditEvent(
        eventType = "audit.tenant.created",
        tenantId = cmd.tenantId,
        userId = cmd.requesterId,
        action = "CREATE",
        resourceType = "tenant",
        resourceId = cmd.tenantId,
        result = "success"
      ))
    }
}
```

**Audit Event Consumer**:
```scala
class AuditEventConsumer(repository: AuditRepository) {
  def consume(event: AuditEvent): Future[Unit] = {
    // Write to append-only table
    repository.insert(event).map { _ =>
      // Also index in Elasticsearch for fast search
      elasticsearchClient.index("audit-events", event)
    }
  }
}
```

**Tamper Detection**:
```scala
// Audit events include cryptographic hash chain
case class AuditEvent(
  eventId: UUID,
  timestamp: Instant,
  previousHash: String,  // Hash of previous event
  contentHash: String,   // Hash of this event's content
  // ... other fields
)

def verifyAuditChain(events: Seq[AuditEvent]): Boolean = {
  events.sliding(2).forall { case Seq(prev, current) =>
    current.previousHash == prev.contentHash
  }
}
```

## Testing Strategy

See companion `audit-trail.feature` file for BDD scenarios.

**Test Coverage**:
- ✅ All event types captured
- ✅ Immutability enforced
- ✅ Query API filters work correctly
- ✅ Cross-tenant isolation maintained
- ✅ Retention policy enforced
- ✅ Tamper detection working

## Dependencies

- Kafka: Audit event stream
- PostgreSQL: Append-only audit table
- Elasticsearch: Fast audit search (optional)
- S3/GCS: Archive storage

## Metrics

- `audit_events_total` (counter, labels: event_type, result)
- `audit_event_write_duration_seconds` (histogram)
- `audit_query_duration_seconds` (histogram)
- `audit_events_archived_total` (counter)

## Acceptance Criteria

- [ ] All entity changes generate audit events
- [ ] Authentication/authorization events logged
- [ ] Security events (cross-tenant access) logged
- [ ] Audit events immutable (append-only)
- [ ] 7-year retention policy configured
- [ ] Query API supports filters (tenant, user, date, type)
- [ ] Elasticsearch indexing for fast search
- [ ] All BDD scenarios passing
