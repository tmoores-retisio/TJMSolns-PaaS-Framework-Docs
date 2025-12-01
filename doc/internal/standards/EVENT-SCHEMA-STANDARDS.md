# Event Schema Standards

**Status**: Active Standard  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Category**: Event Standard

## Context

TJMPaaS services use event-driven architecture (per ADR-0007) for integration and state management. Events flow between services via Apache Kafka, enabling loose coupling, scalability, and audit trails. Consistent event schemas ensure:
- Predictable event consumption across services
- Clear semantic meaning of events
- Multi-tenant isolation at event layer
- Versioning and schema evolution
- Audit trail and compliance

### Problem Statement

Without event schema standards:
- Each service invents its own event formats
- Event consumers must handle inconsistent schemas
- Multi-tenant isolation inconsistent
- Schema evolution breaks consumers
- Difficult to build cross-service event processing

### Goals

- Consistent event schema across all TJMPaaS services
- Multi-tenant aware events (tenant_id mandatory)
- Clear event naming conventions
- Schema versioning and evolution
- CloudEvents-compatible where practical
- Avro schemas for type safety

## Standards

### 1. Event Structure (CloudEvents-Compatible)

**Base Event Format**:
```json
{
  "specversion": "1.0",
  "type": "com.tjmpaas.cart.ItemAdded.v1",
  "source": "/services/cart-service/carts/cart-abc",
  "id": "event-123-456",
  "time": "2025-11-28T10:30:00Z",
  "tenant_id": "tenant-789",
  "datacontenttype": "application/json",
  "dataschema": "https://schemas.tjmpaas.com/cart/ItemAdded.v1.json",
  "data": {
    "cartId": "cart-abc",
    "item": {
      "id": "item-1",
      "productId": "prod-456",
      "quantity": 2,
      "price": {
        "amount": 29.99,
        "currency": "USD"
      }
    },
    "timestamp": "2025-11-28T10:30:00Z"
  }
}
```

**Required Fields** (CloudEvents spec):

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `specversion` | string | CloudEvents version | "1.0" |
| `type` | string | Event type (reverse DNS + version) | "com.tjmpaas.cart.ItemAdded.v1" |
| `source` | string | Event source (URI) | "/services/cart-service/carts/cart-abc" |
| `id` | string | Unique event ID (UUID) | "event-123-456" |
| `time` | string | Event timestamp (ISO 8601 with timezone) | "2025-11-28T10:30:00Z" |
| `tenant_id` | string | **CUSTOM: Tenant ID for multi-tenancy** | "tenant-789" |
| `datacontenttype` | string | Content type of data field | "application/json" |
| `data` | object | Event payload (service-specific) | { ... } |

**Optional Fields**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `dataschema` | string | Schema URL for data field | "https://schemas.tjmpaas.com/cart/ItemAdded.v1.json" |
| `subject` | string | Subject of event (resource ID) | "cart-abc" |

### 2. Event Type Naming Convention

**Format**: `com.tjmpaas.{service}.{EventName}.{version}`

**Pattern**:
- `com.tjmpaas`: Reverse DNS for TJMPaaS
- `{service}`: Service name (lowercase, no hyphens)
- `{EventName}`: PascalCase event name (past tense verb + noun)
- `{version}`: Schema version (v1, v2, etc.)

**Examples**:
```
com.tjmpaas.cart.ItemAdded.v1
com.tjmpaas.cart.ItemRemoved.v1
com.tjmpaas.cart.CartCheckedOut.v1
com.tjmpaas.order.OrderPlaced.v1
com.tjmpaas.payment.PaymentProcessed.v1
com.tjmpaas.entity.TenantCreated.v1
com.tjmpaas.entity.UserAssignedToTenant.v1
```

**Event Naming Rules**:
- **Past tense**: Events are facts that happened (ItemAdded, not AddItem)
- **Business domain language**: Use ubiquitous language (OrderPlaced, not OrderSubmitted)
- **Specific**: Avoid generic names (PaymentProcessed, not PaymentEvent)
- **Consistent**: Similar events use similar naming (ItemAdded, ItemRemoved, ItemUpdated)

### 3. Event Source Naming Convention

**Format**: `/services/{service-name}/{resource-type}/{resource-id}`

**Examples**:
```
/services/cart-service/carts/cart-abc
/services/order-service/orders/order-123
/services/entity-management/tenants/tenant-789
/services/payment-service/payments/payment-456
```

**Rules**:
- Service name uses kebab-case
- Resource type is plural
- Resource ID is specific instance

### 4. Multi-Tenant Event Requirements

**MANDATORY: tenant_id Field**

Every event MUST include `tenant_id` at root level:

```json
{
  "tenant_id": "tenant-789",
  "type": "com.tjmpaas.cart.ItemAdded.v1",
  "data": {
    "cartId": "cart-abc",
    ...
  }
}
```

**Kafka Message Headers**:
```scala
val record = ProducerRecord(
  topic = "cart-events",
  key = s"${event.tenantId}-${event.cartId}", // Tenant-partitioned key
  value = eventJson,
  headers = Headers(
    "tenant-id" -> event.tenantId.toString,
    "event-type" -> "com.tjmpaas.cart.ItemAdded.v1",
    "event-id" -> event.id.toString,
    "event-time" -> event.time.toString
  )
)
```

**Consumer Filtering**:
```scala
// Consumers filter by tenant_id for isolation
consumer.subscribe("cart-events")
consumer.records.filter { record =>
  val tenantId = record.headers.get("tenant-id")
  allowedTenants.contains(tenantId)
}
```

### 5. Event Data Schema

**Scala Case Classes** (source of truth):
```scala
sealed trait CartEvent {
  def tenantId: TenantId
  def cartId: CartId
  def timestamp: Instant
}

case class ItemAdded(
  tenantId: TenantId,
  cartId: CartId,
  item: CartItem,
  timestamp: Instant
) extends CartEvent

case class CartItem(
  id: ItemId,
  productId: ProductId,
  quantity: Int,
  price: Money
)

case class Money(
  amount: BigDecimal,
  currency: String // ISO 4217 code
)
```

**JSON Schema** (for consumers):
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://schemas.tjmpaas.com/cart/ItemAdded.v1.json",
  "title": "ItemAdded",
  "type": "object",
  "required": ["cartId", "item", "timestamp"],
  "properties": {
    "cartId": {
      "type": "string",
      "format": "uuid"
    },
    "item": {
      "type": "object",
      "required": ["id", "productId", "quantity", "price"],
      "properties": {
        "id": {
          "type": "string"
        },
        "productId": {
          "type": "string"
        },
        "quantity": {
          "type": "integer",
          "minimum": 1
        },
        "price": {
          "type": "object",
          "required": ["amount", "currency"],
          "properties": {
            "amount": {
              "type": "number",
              "minimum": 0
            },
            "currency": {
              "type": "string",
              "pattern": "^[A-Z]{3}$"
            }
          }
        }
      }
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

**Avro Schema** (optional, for schema registry):
```json
{
  "type": "record",
  "name": "ItemAdded",
  "namespace": "com.tjmpaas.cart.v1",
  "fields": [
    {"name": "cartId", "type": "string"},
    {"name": "item", "type": {
      "type": "record",
      "name": "CartItem",
      "fields": [
        {"name": "id", "type": "string"},
        {"name": "productId", "type": "string"},
        {"name": "quantity", "type": "int"},
        {"name": "price", "type": {
          "type": "record",
          "name": "Money",
          "fields": [
            {"name": "amount", "type": "double"},
            {"name": "currency", "type": "string"}
          ]
        }}
      ]
    }},
    {"name": "timestamp", "type": "long", "logicalType": "timestamp-millis"}
  ]
}
```

### 6. Event Categories

**Domain Events** (business-significant):
```
com.tjmpaas.cart.ItemAdded.v1
com.tjmpaas.cart.ItemRemoved.v1
com.tjmpaas.cart.CartCheckedOut.v1
com.tjmpaas.order.OrderPlaced.v1
com.tjmpaas.order.OrderShipped.v1
com.tjmpaas.payment.PaymentProcessed.v1
```

**Integration Events** (cross-service coordination):
```
com.tjmpaas.cart.CartCheckedOut.v1  → triggers OrderService
com.tjmpaas.order.OrderPlaced.v1    → triggers PaymentService, InventoryService
com.tjmpaas.payment.PaymentProcessed.v1 → triggers FulfillmentService
```

**Provisioning Events** (operational):
```
com.tjmpaas.provisioning.TenantProvisioningRequested.v1
com.tjmpaas.provisioning.TenantProvisioningStarted.v1
com.tjmpaas.provisioning.TenantProvisioningCompleted.v1
com.tjmpaas.provisioning.TenantProvisioningFailed.v1
```

**Audit Events** (compliance):
```
com.tjmpaas.audit.UserLoggedIn.v1
com.tjmpaas.audit.PermissionGranted.v1
com.tjmpaas.audit.DataAccessed.v1
com.tjmpaas.audit.DataModified.v1
```

### 7. Kafka Topic Naming

**Format**: `{service-name}-{event-category}`

**Examples**:
```
cart-events           # All CartService events
order-events          # All OrderService events
payment-events        # All PaymentService events
entity-events         # All Entity Management events
provisioning-events   # All Provisioning Service events
audit-events          # Cross-service audit events
```

**Topic Configuration**:
```
Partitions: 10 (or more for high-throughput topics)
Replication Factor: 3
Retention: 7 days (domain events), 365 days (audit events)
Cleanup Policy: delete (not compact, events are immutable)
```

**Partition Key** (for ordering):
```scala
// Partition by tenant-resource for ordering within tenant
val key = s"${event.tenantId}-${event.cartId}"

// Events for same cart go to same partition (order preserved)
producer.send(ProducerRecord(
  topic = "cart-events",
  key = key,
  value = eventJson
))
```

### 8. Schema Versioning and Evolution

**Breaking Changes** (require new version):
- Removing fields
- Changing field types
- Renaming fields
- Changing field semantics

**Non-Breaking Changes** (same version):
- Adding new optional fields
- Adding new event types

**Version Migration**:
```scala
// Consumer handles multiple versions
def handleEvent(event: CloudEvent): Unit = event.`type` match {
  case "com.tjmpaas.cart.ItemAdded.v1" =>
    val data = parse[ItemAddedV1](event.data)
    processItemAddedV1(data)
  
  case "com.tjmpaas.cart.ItemAdded.v2" =>
    val data = parse[ItemAddedV2](event.data)
    processItemAddedV2(data)
  
  case unknownType =>
    logger.warn(s"Unknown event type: $unknownType")
    // Ignore unknown events (forward compatibility)
}
```

**Upcasting** (transform old events to new schema):
```scala
def upcast(event: ItemAddedV1): ItemAddedV2 = {
  ItemAddedV2(
    cartId = event.cartId,
    item = event.item,
    addedBy = None, // New field, default to None
    timestamp = event.timestamp
  )
}
```

### 9. Event Validation

**Producer Validation**:
```scala
// Validate event before publishing
def validateEvent(event: CartEvent): Either[ValidationError, Unit] = {
  for {
    _ <- validateTenantId(event.tenantId)
    _ <- validateCartId(event.cartId)
    _ <- validateTimestamp(event.timestamp)
    _ <- validateData(event)
  } yield ()
}

// Publish only if valid
validateEvent(event) match {
  case Right(_) => producer.send(eventRecord)
  case Left(error) => logger.error(s"Invalid event: $error")
}
```

**Consumer Validation**:
```scala
// Validate event on consumption
def consumeEvent(record: ConsumerRecord): Unit = {
  val event = parse[CloudEvent](record.value)
  
  validateEvent(event) match {
    case Right(_) => processEvent(event)
    case Left(error) =>
      logger.error(s"Invalid event consumed: $error")
      // Send to dead-letter queue
      deadLetterQueue.send(record)
  }
}
```

### 10. Dead Letter Queue (DLQ)

**DLQ Topic**: `{service-name}-dlq`

**When to Send to DLQ**:
- Event parsing fails (malformed JSON)
- Event validation fails (missing required fields)
- Event processing fails after max retries (transient errors)

**DLQ Event Format**:
```json
{
  "originalTopic": "cart-events",
  "originalPartition": 5,
  "originalOffset": 12345,
  "originalKey": "tenant-789-cart-abc",
  "originalValue": "<original event JSON>",
  "error": {
    "message": "Failed to process ItemAdded event",
    "exception": "java.lang.NullPointerException",
    "stackTrace": "...",
    "attemptCount": 3
  },
  "timestamp": "2025-11-28T10:30:00Z"
}
```

**DLQ Processing**:
- Manual review of DLQ events
- Fix producer bugs (malformed events)
- Fix consumer bugs (processing errors)
- Replay events after fixes deployed

### 11. Event Ordering Guarantees

**Within Partition**: Events ordered by offset
```
Partition 5:
  Offset 100: ItemAdded (cart-abc, item-1)
  Offset 101: ItemAdded (cart-abc, item-2)
  Offset 102: CartCheckedOut (cart-abc)

Consumer processes in order: 100 → 101 → 102
```

**Across Partitions**: No ordering guarantee
```
Partition 5:
  Offset 100: ItemAdded (cart-abc)
Partition 7:
  Offset 200: ItemAdded (cart-def)

No guarantee which processes first
```

**Solution**: Partition by resource ID for ordering within resource
```scala
// All events for cart-abc go to same partition
val key = s"${event.tenantId}-${event.cartId}"
```

### 12. Event Idempotency

**Consumer Must Be Idempotent**:
```scala
// Track processed event IDs to avoid duplicate processing
case class EventProcessingRecord(
  eventId: UUID,
  processedAt: Instant
)

def processEvent(event: CloudEvent): Future[Unit] = {
  eventRepo.findByEventId(event.id).flatMap {
    case Some(_) =>
      // Already processed - skip (idempotent)
      logger.debug(s"Event ${event.id} already processed, skipping")
      Future.successful(())
    
    case None =>
      // Process event and record
      for {
        _ <- handleEvent(event)
        _ <- eventRepo.save(EventProcessingRecord(event.id, Instant.now()))
      } yield ()
  }
}
```

**At-Least-Once Delivery**:
- Kafka guarantees at-least-once delivery
- Consumer may receive same event multiple times
- Consumer must handle duplicates gracefully

## Implementation Examples

### CartService Events

```scala
sealed trait CartEvent extends CloudEvent {
  def tenantId: TenantId
  def cartId: CartId
}

case class ItemAdded(
  id: UUID,
  tenantId: TenantId,
  cartId: CartId,
  item: CartItem,
  time: Instant
) extends CartEvent {
  override def `type`: String = "com.tjmpaas.cart.ItemAdded.v1"
  override def source: String = s"/services/cart-service/carts/$cartId"
}

case class ItemRemoved(
  id: UUID,
  tenantId: TenantId,
  cartId: CartId,
  itemId: ItemId,
  time: Instant
) extends CartEvent {
  override def `type`: String = "com.tjmpaas.cart.ItemRemoved.v1"
  override def source: String = s"/services/cart-service/carts/$cartId"
}

case class CartCheckedOut(
  id: UUID,
  tenantId: TenantId,
  cartId: CartId,
  total: Money,
  time: Instant
) extends CartEvent {
  override def `type`: String = "com.tjmpaas.cart.CartCheckedOut.v1"
  override def source: String = s"/services/cart-service/carts/$cartId"
}
```

### Entity Management Events

```scala
case class TenantCreated(
  id: UUID,
  tenantId: TenantId,
  entityId: EntityId,
  subscriptionPlan: SubscriptionPlan,
  time: Instant
) extends EntityEvent {
  override def `type`: String = "com.tjmpaas.entity.TenantCreated.v1"
  override def source: String = s"/services/entity-management/tenants/$tenantId"
}

case class UserAssignedToTenant(
  id: UUID,
  tenantId: TenantId,
  userId: UserId,
  roleName: String,
  time: Instant
) extends EntityEvent {
  override def `type`: String = "com.tjmpaas.entity.UserAssignedToTenant.v1"
  override def source: String = s"/services/entity-management/tenants/$tenantId"
}
```

## Validation

Success criteria:

- All TJMPaaS service events follow CloudEvents standard (100% compliance)
- tenant_id present in all events
- Event types follow naming convention
- JSON schemas available for all event types
- Kafka topics follow naming convention
- Consumers handle events idempotently

Metrics:
- Event schema compliance: 100% of published events
- CloudEvents adoption: 100% of services
- Schema evolution errors: <0.1% (minimal consumer breakage)
- DLQ event rate: <0.01% (most events process successfully)

## Related Standards

- [POL-cross-service-consistency.md](./POL-cross-service-consistency.md) - Tier 1 consistency includes event schemas
- [MULTI-TENANT-SEAM-ARCHITECTURE.md](./MULTI-TENANT-SEAM-ARCHITECTURE.md) - tenant_id in all events
- [API-DESIGN-STANDARDS.md](./API-DESIGN-STANDARDS.md) - Event naming matches resource names

## Related Governance

- [ADR-0007: CQRS and Event-Driven Architecture](../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) - Event-driven integration

## Related Best Practices

- [Event-Driven Architecture Best Practices](../best-practices/architecture/event-driven.md) - Industry patterns

## Notes

**Why CloudEvents?**

- Industry standard for event format (CNCF project)
- Language and platform agnostic
- Extensible (custom fields like tenant_id)
- Tooling support (CloudEvents SDKs)
- Future-proof (evolving standard)

**Why Avro for Schema Registry?**

- Compact binary format (smaller than JSON)
- Schema evolution support built-in
- Backward/forward compatibility validation
- Confluent Schema Registry integration
- Generated code from schema

**Event Sourcing vs Event-Driven**:

- **Event Sourcing**: Events as state persistence (ItemAdded persisted to event store)
- **Event-Driven**: Events for integration (ItemAdded published to Kafka for OrderService)

Services may do both: Event source internally, publish integration events to Kafka.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-28 | Initial event schema standards establishing CloudEvents-compatible format | Tony Moores |
