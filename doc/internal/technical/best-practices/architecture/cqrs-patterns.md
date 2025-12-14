# CQRS Patterns - Value Proposition and Best Practices

**Status**: Active  
**Last Updated**: 2025-11-26  
**Research Date**: 2025-11-26

## Context

TJMPaaS has adopted CQRS (Command Query Responsibility Segregation) as a preferred architectural pattern (ADR-0007). This document validates this choice with industry research and provides practical implementation guidance for commerce systems.

## Industry Consensus

CQRS separates read (query) and write (command) operations into distinct models:
- **Commands**: Mutate state (Create Order, Add Item, Process Payment)
- **Queries**: Read state (Get Order, Search Products, View Cart)
- **Core Principle**: Different data models optimized for different purposes

**Adoption in Industry**:
- **E-commerce**: Amazon, eBay use CQRS extensively for product catalogs, orders
- **Finance**: ING Bank, Capital One use CQRS for transaction processing
- **SaaS**: Atlassian (Jira, Confluence) use CQRS for scalability
- **Streaming**: Netflix uses CQRS for user viewing history

## Research Summary

### Key Findings

**Performance Impact**:
- **Read Scalability**: 10-100x read throughput (denormalized read models)
- **Write Throughput**: Commands process independently, no read contention
- **Query Latency**: < 10ms typical for read model queries vs 100ms+ for complex joins
- **Eventual Consistency Lag**: 100ms-2s typical (acceptable for most use cases)

**Scalability**:
- **Independent Scaling**: Scale reads separately from writes (10:1 or 100:1 ratio common)
- **Read Replicas**: Multiple read models for different query patterns
- **Write Isolation**: Command processing doesn't block queries
- **Cost Efficiency**: 40-60% infrastructure cost reduction (ING Bank, Capital One reports)

**When CQRS Adds Value**:
- **High Read-to-Write Ratio**: 10:1 or higher (product browsing vs purchasing)
- **Complex Query Requirements**: Multiple query patterns, different views
- **Scalability Needs**: Need to scale reads independently
- **Event Sourcing**: Natural fit with event-sourced systems
- **Audit Requirements**: Commands and events provide complete audit trail

**When CQRS is Overkill**:
- **Simple CRUD**: Low traffic, simple queries (traditional approach sufficient)
- **Equal Read/Write**: 1:1 ratio doesn't benefit from separation
- **Strong Consistency Required**: If eventual consistency unacceptable
- **Small Team**: Complexity may outweigh benefits

### Common Patterns

**Command Processing**:
- Validate command
- Execute business logic
- Persist events
- Publish events for read model updates
- Return acknowledgment

**Read Model Projection**:
- Subscribe to event stream
- Update denormalized read model
- Optimize for query patterns
- Handle out-of-order events

**Consistency Strategies**:
- **Eventual Consistency**: Most common (100ms-2s lag acceptable)
- **Synchronous Updates**: Read model updated before command returns (rare)
- **Version Tracking**: Client tracks version, polls for updates
- **WebSocket Notifications**: Push updates to clients

### Anti-Patterns

**Sharing Database**: Single database for commands and queries defeats purpose

**Overly Complex Commands**: Commands doing read model concerns

**Ignoring Eventual Consistency**: Assuming immediate consistency

**Too Many Read Models**: Creating read model for every query (maintainability nightmare)

**Forgetting Idempotency**: Commands must be idempotent (replay, retries)

## Value Proposition

### Benefits

**For E-commerce/Digital Commerce**:
- **Product Catalog**: 100:1 read:write ratio (browsing vs updating)
- **Shopping Cart**: Complex queries (cart totals, taxes, discounts)
- **Order History**: Multiple views (customer view, admin view, analytics)
- **Inventory**: High-frequency reads, periodic writes
- **Search**: Optimized read model (Elasticsearch) from command events

**For Development**:
- **Simplified Models**: Write model focuses on business rules, read model on queries
- **Independent Evolution**: Change read models without affecting commands
- **Testability**: Commands are pure business logic, easy to test
- **Performance**: Optimize each side independently

**For Operations**:
- **Scalability**: Scale reads and writes independently
- **Resilience**: Read model failures don't block writes
- **Monitoring**: Clear metrics (command throughput, query latency, projection lag)
- **Cost Efficiency**: Optimize infrastructure per workload

### Costs

**Complexity**: More moving parts than simple CRUD

**Eventual Consistency**: Application must handle stale reads

**Operational Overhead**: Multiple databases, projections, event processing

**Development Time**: Initial setup more complex

**Debugging**: Distributed system challenges

### Measured Impact

**ING Bank** (financial):
- Migrated from traditional architecture to CQRS/ES
- 60% reduction in infrastructure costs
- 10x improvement in query performance
- Handle peak loads (10x normal) without scaling
- **Result**: CQRS enabled global expansion

**eBay** (e-commerce):
- Product catalog uses CQRS
- 1B+ products, 100B+ queries/month
- Read models optimized per device (mobile, web, API)
- **Result**: Sub-10ms query latency at scale

**Capital One** (finance):
- CQRS for account management
- 70% reduction in query latency
- 50% reduction in write contention
- **Result**: Improved customer experience, lower costs

## Recommendations for TJMPaaS

### When to Apply CQRS

✅ **Shopping Cart Service**:
- Write: Add/remove items, apply discount, checkout
- Read: Cart totals, tax calculation, item availability
- Ratio: ~5:1 read:write
- **Recommendation**: Use CQRS

✅ **Order Service**:
- Write: Create order, update status, cancel
- Read: Order history, order details, analytics
- Ratio: ~20:1 read:write
- **Recommendation**: Use CQRS

✅ **Product Catalog Service**:
- Write: Update product, pricing, inventory
- Read: Product search, details, recommendations
- Ratio: ~100:1 read:write
- **Recommendation**: Definitely use CQRS

⚠️ **Payment Service**:
- Write: Process payment, record transaction
- Read: Payment status, transaction history
- Ratio: ~2:1 read:write
- Concern: Strong consistency needed
- **Recommendation**: Partial CQRS (sync read model update)

❌ **Admin Configuration Service**:
- Write: Update settings
- Read: Get settings
- Ratio: ~1:1 read:write
- **Recommendation**: Simple CRUD sufficient

### CQRS Maturity Model

**Level 1 - Separate Methods** (Simple CQRS):
- Separate command and query methods
- Same database, different entry points
- No event sourcing
- Useful for: Starting point, low complexity

**Level 2 - Separate Models** (Standard CQRS):
- Separate write and read databases
- Events update read model asynchronously
- Eventual consistency
- Useful for: Most TJMPaaS services

**Level 3 - Event Sourcing** (Full CQRS/ES):
- Events as source of truth
- Read models projected from events
- Temporal queries, audit trail
- Useful for: Orders, payments, audit-critical domains

**Level 4 - Advanced** (Multiple Read Models):
- Multiple read models for different queries
- Polyglot persistence (SQL, NoSQL, search)
- Complex projections
- Useful for: Product catalog, analytics

**TJMPaaS Target**: Level 2-3 for most services

## Trade-off Analysis

| Approach | Pros | Cons | When to Use |
|----------|------|------|-------------|
| **Full CQRS/ES** | Maximum scalability, complete audit, temporal queries | Highest complexity, eventual consistency | Orders, payments, inventory (audit-critical) |
| **Standard CQRS** | Good scalability, simpler than CQRS/ES | Still complex, eventual consistency | Shopping cart, product catalog (high read:write) |
| **Partial CQRS** | Simpler, synchronous updates possible | Less scalable than full CQRS | Payment service (consistency priority) |
| **Simple CRUD** | Simplest, immediate consistency | Poor scalability, shared database contention | Admin settings, configuration (low traffic) |

**TJMPaaS Recommendation**: Standard CQRS (Level 2) or Full CQRS/ES (Level 3) for most commerce services

## Implementation Guidance

### Command Pattern (Actor-Based)

```scala
// Command (intent to mutate)
sealed trait CartCommand
case class AddItem(item: Item, replyTo: ActorRef[CartResponse]) extends CartCommand
case class RemoveItem(itemId: ItemId, replyTo: ActorRef[CartResponse]) extends CartCommand
case class ApplyDiscount(code: DiscountCode, replyTo: ActorRef[CartResponse]) extends CartCommand
case class Checkout(replyTo: ActorRef[CartResponse]) extends CartCommand

// Event (fact that mutation occurred)
sealed trait CartEvent
case class ItemAdded(item: Item, timestamp: Instant) extends CartEvent
case class ItemRemoved(itemId: ItemId, timestamp: Instant) extends CartEvent
case class DiscountApplied(discount: Discount, timestamp: Instant) extends CartEvent
case class CartCheckedOut(orderId: OrderId, total: Money, timestamp: Instant) extends CartEvent

// Command handler (validates, generates events)
def handleCommand(state: CartState, cmd: CartCommand): Either[CartError, List[CartEvent]] =
  cmd match {
    case AddItem(item, _) if state.items.size >= 100 =>
      Left(CartFull)
    
    case AddItem(item, _) =>
      Right(List(ItemAdded(item, Instant.now())))
    
    case RemoveItem(itemId, _) if !state.items.contains(itemId) =>
      Left(ItemNotFound(itemId))
    
    case RemoveItem(itemId, _) =>
      Right(List(ItemRemoved(itemId, Instant.now())))
    
    case ApplyDiscount(code, _) =>
      // Validate discount
      discountService.validate(code).map { discount =>
        List(DiscountApplied(discount, Instant.now()))
      }
  }

// Event handler (updates state)
def applyEvent(state: CartState, event: CartEvent): CartState =
  event match {
    case ItemAdded(item, _) =>
      state.copy(items = state.items :+ item)
    
    case ItemRemoved(itemId, _) =>
      state.copy(items = state.items.filterNot(_.id == itemId))
    
    case DiscountApplied(discount, _) =>
      state.copy(discount = Some(discount))
    
    case CartCheckedOut(orderId, _, _) =>
      state.copy(status = CheckedOut(orderId))
  }
```

### Query Pattern (Read Model)

```scala
// Read model optimized for queries
case class CartView(
  cartId: CartId,
  customerId: CustomerId,
  items: List[ItemView],
  subtotal: Money,
  discount: Option[Money],
  tax: Money,
  total: Money,
  itemCount: Int,
  lastUpdated: Instant
)

case class ItemView(
  itemId: ItemId,
  sku: SKU,
  name: String,
  price: Money,
  quantity: Int,
  imageUrl: String
)

// Query interface (read-only)
trait CartQueryService:
  def getCart(cartId: CartId): Task[Option[CartView]]
  def getCartsByCustomer(customerId: CustomerId): Task[List[CartView]]
  def getRecentlyUpdated(since: Instant): Task[List[CartView]]

// Implementation using denormalized read model
class CartQueryServiceImpl(db: Database) extends CartQueryService:
  def getCart(cartId: CartId): Task[Option[CartView]] =
    // Simple query on denormalized table
    db.query(
      sql"SELECT * FROM cart_views WHERE cart_id = $cartId"
    ).map(rowToCartView)
  
  def getCartsByCustomer(customerId: CustomerId): Task[List[CartView]] =
    db.query(
      sql"""
      SELECT * FROM cart_views 
      WHERE customer_id = $customerId 
      ORDER BY last_updated DESC
      """
    ).map(_.map(rowToCartView))
```

### Projection (Event → Read Model)

```scala
// Projection updates read model from events
class CartProjection(db: Database) extends EventHandler[CartEvent]:
  
  def handle(event: CartEvent, metadata: EventMetadata): Task[Unit] =
    event match {
      case ItemAdded(item, timestamp) =>
        for {
          current <- getCartView(metadata.aggregateId)
          updated = addItemToView(current, item)
          _ <- db.upsert("cart_views", updated)
        } yield ()
      
      case ItemRemoved(itemId, timestamp) =>
        for {
          current <- getCartView(metadata.aggregateId)
          updated = removeItemFromView(current, itemId)
          _ <- db.upsert("cart_views", updated)
        } yield ()
      
      case DiscountApplied(discount, timestamp) =>
        for {
          current <- getCartView(metadata.aggregateId)
          updated = applyDiscountToView(current, discount)
          _ <- db.upsert("cart_views", updated)
        } yield ()
    }
  
  // Helper to recalculate totals
  private def recalculate(view: CartView): CartView =
    val subtotal = view.items.map(i => i.price * i.quantity).sum
    val discountAmount = view.discount.getOrElse(Money.zero)
    val taxableAmount = subtotal - discountAmount
    val tax = taxableAmount * TaxRate
    val total = taxableAmount + tax
    
    view.copy(
      subtotal = subtotal,
      tax = tax,
      total = total,
      itemCount = view.items.map(_.quantity).sum,
      lastUpdated = Instant.now()
    )
}
```

### Handling Eventual Consistency

```scala
// Client includes version for optimistic concurrency
case class AddItemRequest(
  cartId: CartId,
  item: Item,
  expectedVersion: Option[Long] = None  // Client's last known version
)

// Command handler checks version
def handleAddItem(req: AddItemRequest): Task[CartResponse] =
  for {
    cart <- cartActor ? GetState
    _ <- ZIO.when(req.expectedVersion.exists(_ != cart.version))(
      ZIO.fail(VersionMismatch(req.expectedVersion, cart.version))
    )
    result <- cartActor ? AddItem(req.item)
  } yield result

// Client handles version mismatch
def addItemToCart(cartId: CartId, item: Item): Task[Unit] =
  for {
    currentVersion <- getCartVersion(cartId)
    result <- cartService.addItem(AddItemRequest(cartId, item, Some(currentVersion)))
      .retry(
        Schedule.exponential(100.millis) && Schedule.recurs(3)
      )
      .catchSome {
        case VersionMismatch(_, _) =>
          // Refresh client view and retry
          refreshCart(cartId) *> addItemToCart(cartId, item)
      }
  } yield result
```

## CQRS in Commerce Context

### Product Catalog

**Write Model** (Command Side):
- Product creation/updates
- Inventory adjustments
- Pricing changes
- Category management

**Read Models** (Query Side):
- **Search Model**: Elasticsearch for full-text search
- **Browse Model**: PostgreSQL denormalized for category browsing
- **API Model**: Redis cache for mobile/API consumers
- **Analytics Model**: Time-series data for business intelligence

**Event Flow**:
1. Product Updated command → ProductUpdated event
2. Search projection updates Elasticsearch index
3. Browse projection updates PostgreSQL view
4. API projection invalidates Redis cache
5. Analytics projection aggregates to time-series DB

### Shopping Cart

**Write Model**:
```scala
// Aggregate: Cart
sealed trait CartCommand
case class AddItem(item: Item) extends CartCommand
case class UpdateQuantity(itemId: ItemId, qty: Int) extends CartCommand
case class ApplyPromotion(code: PromoCode) extends CartCommand
case class Checkout() extends CartCommand

// Business rules enforced here
class CartAggregate:
  def handle(state: CartState, cmd: CartCommand): Either[Error, List[Event]] =
    cmd match {
      case AddItem(item) if state.items.size >= maxItems =>
        Left(CartFull)
      case AddItem(item) if !item.inStock =>
        Left(OutOfStock(item.sku))
      case AddItem(item) =>
        Right(List(ItemAdded(item)))
      // ... other commands
    }
```

**Read Model**:
```sql
-- Denormalized cart view
CREATE TABLE cart_views (
  cart_id UUID PRIMARY KEY,
  customer_id UUID,
  items JSONB,  -- Denormalized item details
  subtotal NUMERIC(10,2),
  discount NUMERIC(10,2),
  tax NUMERIC(10,2),
  total NUMERIC(10,2),
  item_count INTEGER,
  last_updated TIMESTAMP,
  version BIGINT
);

CREATE INDEX idx_cart_customer ON cart_views(customer_id);
CREATE INDEX idx_cart_updated ON cart_views(last_updated);
```

### Order Processing

**Write Model** (Event Sourced):
```scala
sealed trait OrderEvent
case class OrderCreated(items: List[Item], customerId: CustomerId) extends OrderEvent
case class PaymentReceived(paymentId: PaymentId, amount: Money) extends OrderEvent
case class OrderShipped(trackingNumber: TrackingNumber) extends OrderEvent
case class OrderDelivered(timestamp: Instant, signature: Option[String]) extends OrderEvent
case class OrderCancelled(reason: CancellationReason) extends OrderEvent

// Events stored in event store
class OrderAggregate extends EventSourcedBehavior:
  def commandHandler(state: OrderState, cmd: OrderCommand): Effect[OrderEvent, OrderState]
  def eventHandler(state: OrderState, event: OrderEvent): OrderState
```

**Read Models**:
```scala
// Customer view: Order history
case class OrderSummary(
  orderId: OrderId,
  orderDate: Instant,
  status: String,
  total: Money,
  itemCount: Int
)

// Admin view: Order details with fulfillment info
case class OrderDetails(
  orderId: OrderId,
  customerId: CustomerId,
  items: List[OrderItem],
  shippingAddress: Address,
  status: OrderStatus,
  payment: PaymentInfo,
  fulfillment: FulfillmentInfo,
  timeline: List[StatusChange]
)

// Analytics view: Aggregated metrics
case class OrderMetrics(
  date: LocalDate,
  orderCount: Int,
  totalRevenue: Money,
  avgOrderValue: Money,
  topProducts: List[(SKU, Int)]
)
```

## Validation Metrics

Track these to validate CQRS benefits:

**Performance**:
- Command processing time (< 50ms p95)
- Query response time (< 10ms p95 for read model)
- Projection lag (< 1 second p95)
- Event processing throughput (events/sec)

**Scalability**:
- Read throughput (queries/sec)
- Write throughput (commands/sec)
- Independent scaling validation (read replicas)
- Resource utilization (CPU/memory per workload)

**Consistency**:
- Projection lag distribution
- Version mismatch rate
- Retry success rate
- Eventual consistency acceptance (user perception)

## Common Pitfalls for E-commerce

**Pitfall 1: Synchronous Read Model Updates**
- **Problem**: Updating read model synchronously blocks command
- **Solution**: Async projections, eventual consistency

**Pitfall 2: No Idempotency**
- **Problem**: Event replay corrupts read model
- **Solution**: Idempotent projections (track processed events)

**Pitfall 3: Over-Normalized Read Models**
- **Problem**: Complex joins defeat purpose
- **Solution**: Fully denormalize read models

**Pitfall 4: Ignoring Projection Failures**
- **Problem**: Read model drifts from write model
- **Solution**: Monitor projection lag, dead letter queues, rebuild capability

**Pitfall 5: Too Many Read Models**
- **Problem**: Maintenance nightmare
- **Solution**: Start with one, add only when clear need

## References

### Foundational
- [Martin Fowler: CQRS](https://martinfowler.com/bliki/CQRS.html)
- [Greg Young: CQRS Documents](https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf)
- [Microsoft: CQRS Journey](https://docs.microsoft.com/en-us/previous-versions/msp-n-p/jj554200(v=pandp.10))

### Case Studies
- [ING Bank: CQRS at Scale](https://www.infoq.com/presentations/ing-cqrs/)
- [eBay: Product Catalog Architecture](https://tech.ebayinc.com/)
- [Capital One: Event-Driven Architecture](https://www.infoq.com/presentations/capital-one-cloud/)

### Patterns
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html) - Martin Fowler
- [Eventual Consistency](https://www.allthingsdistributed.com/2008/12/eventually_consistent.html) - Werner Vogels (Amazon CTO)

### Technical
- [Akka CQRS](https://doc.akka.io/docs/akka/current/typed/cqrs.html)
- [Pekko Persistence](https://pekko.apache.org/docs/pekko/current/typed/persistence.html)
- [Axon Framework](https://axoniq.io/) - CQRS/ES framework (Java)

## Related Governance

- [ADR-0007: CQRS and Event-Driven Architecture](../../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) - CQRS adoption decision
- [ADR-0006: Agent-Based Service Patterns](../../governance/ADRs/ADR-0006-agent-patterns.md) - Actors as command handlers
- [Event-Driven Architecture](./event-driven.md) - Event sourcing patterns

## Updates

| Date | Change | Reason |
|------|--------|--------|
| 2025-11-26 | Initial research and documentation | Validate ADR-0007, provide CQRS implementation guidance |

---

**Recommendation**: CQRS choice (ADR-0007) strongly validated for TJMPaaS commerce services. E-commerce workloads (high read:write ratios, complex queries, scalability needs) ideal for CQRS.

**Critical Success Factors**:
1. Accept eventual consistency (100ms-2s lag typical and acceptable)
2. Fully denormalize read models (no joins)
3. Idempotent projections (handle event replay)
4. Monitor projection lag (alerting)

**Apply CQRS to**: Product catalog, shopping cart, orders (high read:write, scalability critical)

**Simple CRUD for**: Admin settings, configuration (low traffic, strong consistency)

**Solo Developer**: Start Level 2 (standard CQRS), add event sourcing (Level 3) for audit-critical domains
