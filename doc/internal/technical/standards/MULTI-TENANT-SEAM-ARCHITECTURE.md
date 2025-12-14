# Multi-Tenant Seam Architecture

**Status**: Active Standard  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Category**: Architecture Standard

## Context

TJMPaaS services are designed to support multiple tenants (customers) on shared infrastructure while maintaining complete data isolation, security, and performance guarantees per tenant. The multi-tenant architecture must balance:
- Tenant isolation and security
- Resource efficiency and cost optimization
- Feature flexibility and customization per tenant
- Operational simplicity and scalability

### Problem Statement

Multi-tenancy can be implemented at various levels (database, schema, table, row). Without a clear architecture, services may:
- Implement inconsistent isolation strategies
- Mix concerns across isolation boundaries
- Create data leakage risks
- Complicate feature rollout and A/B testing
- Make role-based access control complex

### Goals

- **Clear Isolation Boundaries**: 4-level seam architecture defining isolation layers
- **Progressive Implementation**: Implement seams incrementally (MVP → full)
- **Consistent Pattern**: All services use same seam architecture
- **Security by Design**: Tenant isolation enforced at every layer
- **Operational Flexibility**: Feature flags, A/B testing, custom SLAs per tenant

## Architecture

### Four-Level Seam Architecture

TJMPaaS implements multi-tenancy through **four distinct seam levels**, each providing a specific isolation boundary:

```
┌─────────────────────────────────────────────────────────────┐
│ Seam Level 1: TENANT                                        │
│ - Data isolation by tenant_id                               │
│ - Every request includes X-Tenant-ID header                 │
│ - All tables have tenant_id foreign key                     │
│ - One actor instance per tenant                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Seam Level 2: TENANT-SERVICE                                │
│ - Service subscriptions/entitlements per tenant             │
│ - SLA tiers (Bronze/Silver/Gold) per tenant-service         │
│ - Rate limiting per tenant-service combination              │
│ - Billing tracked at tenant-service level                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Seam Level 3: TENANT-SERVICE-FEATURE                        │
│ - Feature flags per tenant (e.g., "advanced-pricing")       │
│ - A/B testing: Enable features for tenant cohorts           │
│ - Progressive rollout: Canary tenants first                 │
│ - Feature analytics: Usage metrics per tenant-feature       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Seam Level 4: TENANT-SERVICE-ROLE                           │
│ - RBAC within tenant context (Admin/User/ReadOnly)          │
│ - Permissions: Service-specific actions by role             │
│ - Delegation: Tenant admins manage their users' roles       │
│ - Audit: All actions logged with tenant-service-role        │
└─────────────────────────────────────────────────────────────┘
```

### Seam Level 1: Tenant Isolation

**Purpose**: Fundamental data isolation ensuring no tenant sees another tenant's data.

**Implementation**:

**API Layer**:
```
HTTP Headers:
  X-Tenant-ID: required on all requests
  Authorization: Bearer <JWT with tenant_id claim>

Request Validation:
  1. Extract X-Tenant-ID from header
  2. Validate JWT contains matching tenant_id claim
  3. Reject request if mismatch or missing
  4. Pass tenant_id to all downstream operations
```

**Database Layer**:
```sql
-- Every table includes tenant_id
CREATE TABLE carts (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  user_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  CONSTRAINT fk_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Every query filters by tenant_id
SELECT * FROM carts 
WHERE tenant_id = :tenant_id 
  AND user_id = :user_id;

-- Indexes include tenant_id for performance
CREATE INDEX idx_carts_tenant_user ON carts(tenant_id, user_id);
```

**Actor Layer**:
```scala
// One actor instance per tenant per entity
object CartActor {
  def apply(tenantId: TenantId, cartId: CartId): Behavior[Command] = {
    Behaviors.setup { context =>
      // Actor only processes commands for its tenant
      val persistenceId = PersistenceId.of(
        "Cart",
        s"${tenantId.value}-${cartId.value}"
      )
      
      EventSourcedBehavior[Command, Event, State](
        persistenceId = persistenceId,
        emptyState = State.empty(tenantId, cartId),
        commandHandler = handleCommand(tenantId),
        eventHandler = handleEvent
      )
    }
  }
  
  // All commands validated against tenant_id
  def handleCommand(tenantId: TenantId)(state: State, cmd: Command): Effect[Event, State] = {
    cmd match {
      case AddItem(itemTenantId, item, replyTo) if itemTenantId == tenantId =>
        Effect.persist(ItemAdded(item)).thenReply(replyTo)(_ => Success)
      
      case AddItem(wrongTenantId, _, replyTo) =>
        Effect.reply(replyTo)(Failure(s"Tenant mismatch: expected $tenantId, got $wrongTenantId"))
    }
  }
}
```

**Event Layer**:
```scala
// Every event includes tenant_id
sealed trait CartEvent {
  def tenantId: TenantId
  def timestamp: Instant
}

case class ItemAdded(
  tenantId: TenantId,
  cartId: CartId,
  item: Item,
  timestamp: Instant
) extends CartEvent

// Kafka messages include tenant_id in metadata
val record = ProducerRecord(
  topic = "cart-events",
  key = s"${event.tenantId}-${event.cartId}",
  value = eventJson,
  headers = Headers(
    "tenant-id" -> event.tenantId.value.toString,
    "event-type" -> "ItemAdded"
  )
)
```

**Observability**:
```scala
// All metrics labeled with tenant_id
metrics.counter("cart.items.added")
  .tag("tenant_id", tenantId.toString)
  .increment()

// All logs include tenant_id
logger.info(
  "Item added to cart",
  "tenant_id" -> tenantId,
  "cart_id" -> cartId,
  "item_id" -> item.id
)

// All traces propagate tenant context
Span.current()
  .setAttribute("tenant.id", tenantId.toString)
  .setAttribute("cart.id", cartId.toString)
```

**Security**:
- Row-level security (RLS) enforced in database
- Multi-tenant indexes for query performance
- Tenant data encrypted at rest (tenant-specific keys)
- Audit logs include tenant_id for compliance

### Seam Level 2: Tenant-Service Subscriptions

**Purpose**: Enable/disable services per tenant, support different SLA tiers, track usage for billing.

**Implementation**:

**Subscription Model**:
```sql
CREATE TABLE tenant_service_subscriptions (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  service_name TEXT NOT NULL,
  sla_tier TEXT NOT NULL CHECK (sla_tier IN ('Bronze', 'Silver', 'Gold')),
  enabled BOOLEAN NOT NULL DEFAULT true,
  provisioned_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ,
  UNIQUE(tenant_id, service_name)
);

-- Service enablement check
SELECT enabled, sla_tier
FROM tenant_service_subscriptions
WHERE tenant_id = :tenant_id
  AND service_name = 'CartService'
  AND (expires_at IS NULL OR expires_at > NOW());
```

**SLA Tiers**:
```yaml
Bronze:
  rate_limit: 100 req/min
  storage_quota: 10 GB
  support: Community (48h response)
  features: Basic only
  cost: $99/month

Silver:
  rate_limit: 1000 req/min
  storage_quota: 100 GB
  support: Email (12h response)
  features: Basic + Standard
  cost: $499/month

Gold:
  rate_limit: 10000 req/min
  storage_quota: 1 TB
  support: Phone (1h response)
  features: Basic + Standard + Premium
  cost: $1999/month
```

**Rate Limiting**:
```scala
// Rate limiter keyed by tenant-service
object RateLimiter {
  def checkLimit(tenantId: TenantId, serviceName: String): Future[Boolean] = {
    val key = s"ratelimit:${tenantId}:${serviceName}"
    
    // Get SLA tier from subscription
    getSubscription(tenantId, serviceName).flatMap { subscription =>
      val limit = subscription.slaTier match {
        case Bronze => 100
        case Silver => 1000
        case Gold => 10000
      }
      
      redis.incr(key, expireSeconds = 60).map { count =>
        count <= limit
      }
    }
  }
}

// Reject requests exceeding limit
def handleRequest(tenantId: TenantId): Future[Response] = {
  RateLimiter.checkLimit(tenantId, "CartService").flatMap {
    case true => processRequest()
    case false => Future.successful(Response.TooManyRequests)
  }
}
```

**Billing Integration**:
```scala
// Track usage at tenant-service level
case class UsageEvent(
  tenantId: TenantId,
  serviceName: String,
  operation: String,
  quantity: Int,
  timestamp: Instant
)

// Example: Cart item storage
UsageEvent(
  tenantId = tenant1,
  serviceName = "CartService",
  operation = "storage.cart.items",
  quantity = 5, // 5 items stored
  timestamp = Instant.now()
)

// Billing aggregates usage monthly
SELECT 
  tenant_id,
  service_name,
  SUM(quantity) as total_usage,
  DATE_TRUNC('month', timestamp) as billing_month
FROM usage_events
WHERE service_name = 'CartService'
  AND operation = 'storage.cart.items'
GROUP BY tenant_id, service_name, billing_month;
```

**Service Enablement Check**:
```scala
// Every service request checks subscription
trait TenantServiceGuard {
  def checkSubscription(tenantId: TenantId, serviceName: String): Future[Either[Error, Subscription]] = {
    subscriptionRepo.findActive(tenantId, serviceName).map {
      case Some(sub) if sub.enabled => Right(sub)
      case Some(sub) => Left(ServiceDisabledError(serviceName))
      case None => Left(NoSubscriptionError(serviceName))
    }
  }
}

// Applied to all service endpoints
def addItemToCart(tenantId: TenantId, cartId: CartId, item: Item): Future[Response] = {
  checkSubscription(tenantId, "CartService").flatMap {
    case Right(subscription) =>
      // Check feature availability for SLA tier
      if (subscription.slaTier.hasFeature("cart.advanced-pricing")) {
        processAddItemWithPricing(cartId, item)
      } else {
        processAddItemBasic(cartId, item)
      }
    case Left(error) =>
      Future.successful(Response.Forbidden(error.message))
  }
}
```

### Seam Level 3: Tenant-Service-Feature Flags

**Purpose**: Enable/disable features per tenant for A/B testing, progressive rollout, and tier-based access.

**Implementation**:

**Feature Flag Model**:
```sql
CREATE TABLE tenant_feature_flags (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  service_name TEXT NOT NULL,
  feature_key TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT false,
  rollout_percentage INT CHECK (rollout_percentage BETWEEN 0 AND 100),
  enabled_at TIMESTAMPTZ,
  metadata JSONB,
  UNIQUE(tenant_id, service_name, feature_key)
);

-- Check if feature enabled for tenant
SELECT enabled
FROM tenant_feature_flags
WHERE tenant_id = :tenant_id
  AND service_name = 'CartService'
  AND feature_key = 'advanced-pricing'
  AND enabled = true;
```

**Feature Check**:
```scala
object FeatureFlags {
  def isEnabled(
    tenantId: TenantId,
    serviceName: String,
    featureKey: String
  ): Future[Boolean] = {
    featureFlagRepo.find(tenantId, serviceName, featureKey).map {
      case Some(flag) if flag.enabled =>
        // Check rollout percentage for gradual rollout
        flag.rolloutPercentage match {
          case 100 => true
          case pct if pct > 0 =>
            // Deterministic hash-based rollout
            val hash = (tenantId.hashCode % 100).abs
            hash < pct
          case _ => false
        }
      case _ => false
    }
  }
}

// Use in service logic
def calculatePrice(tenantId: TenantId, item: Item): Future[Price] = {
  FeatureFlags.isEnabled(tenantId, "CartService", "advanced-pricing").flatMap {
    case true => advancedPricingEngine.calculate(item)
    case false => basicPricingEngine.calculate(item)
  }
}
```

**Progressive Rollout**:
```scala
// Canary rollout: 5% → 25% → 50% → 100%
case class RolloutPlan(
  featureKey: String,
  stages: Seq[RolloutStage]
)

case class RolloutStage(
  percentage: Int,
  tenantCohort: Option[String], // e.g., "beta-testers"
  startDate: LocalDate,
  metrics: Seq[String] // success metrics to monitor
)

// Example: Roll out advanced pricing
val rollout = RolloutPlan(
  featureKey = "advanced-pricing",
  stages = Seq(
    RolloutStage(5, Some("beta-testers"), LocalDate.of(2025, 12, 1), Seq("pricing.accuracy", "cart.conversion")),
    RolloutStage(25, None, LocalDate.of(2025, 12, 8), Seq("pricing.accuracy", "cart.conversion")),
    RolloutStage(50, None, LocalDate.of(2025, 12, 15), Seq("pricing.accuracy", "cart.conversion")),
    RolloutStage(100, None, LocalDate.of(2026, 1, 1), Seq("pricing.accuracy", "cart.conversion"))
  )
)
```

**A/B Testing**:
```scala
// Assign tenants to experiment groups
case class Experiment(
  key: String,
  variants: Map[String, Int] // variant -> percentage
)

val pricingExperiment = Experiment(
  key = "pricing-algorithm-v2",
  variants = Map(
    "control" -> 50,  // current algorithm
    "variant-a" -> 25, // new algorithm A
    "variant-b" -> 25  // new algorithm B
  )
)

def getExperimentVariant(tenantId: TenantId, experimentKey: String): String = {
  val hash = (tenantId.hashCode % 100).abs
  
  pricingExperiment.variants.foldLeft((0, "control")) {
    case ((cumulative, _), (variant, percentage)) if hash < (cumulative + percentage) =>
      (cumulative + percentage, variant)
    case (acc, _) => acc
  }._2
}

// Use variant in pricing logic
def calculatePrice(tenantId: TenantId, item: Item): Future[Price] = {
  val variant = getExperimentVariant(tenantId, "pricing-algorithm-v2")
  
  variant match {
    case "control" => currentPricingAlgorithm(item)
    case "variant-a" => newPricingAlgorithmA(item)
    case "variant-b" => newPricingAlgorithmB(item)
  }
}
```

**Feature Analytics**:
```scala
// Track feature usage per tenant
metrics.counter("feature.usage")
  .tag("tenant_id", tenantId.toString)
  .tag("service", "CartService")
  .tag("feature", "advanced-pricing")
  .tag("variant", variant)
  .increment()

// Measure feature impact
metrics.timer("feature.performance")
  .tag("feature", "advanced-pricing")
  .tag("variant", variant)
  .record(duration)
```

### Seam Level 4: Tenant-Service-Role (RBAC)

**Purpose**: Role-based access control within tenant context, allowing tenant admins to manage their users' permissions.

**Implementation**:

**Role Model**:
```sql
CREATE TABLE tenant_users (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  user_id UUID NOT NULL REFERENCES users(id),
  role_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  created_by UUID REFERENCES users(id),
  UNIQUE(tenant_id, user_id)
);

CREATE TABLE tenant_service_roles (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  service_name TEXT NOT NULL,
  role_name TEXT NOT NULL,
  permissions JSONB NOT NULL,
  UNIQUE(tenant_id, service_name, role_name)
);

-- Example roles
INSERT INTO tenant_service_roles (tenant_id, service_name, role_name, permissions) VALUES
  (:tenant_id, 'CartService', 'CustomerAdmin', '["cart:*", "user:manage"]'),
  (:tenant_id, 'CartService', 'CustomerUser', '["cart:read", "cart:write:own"]'),
  (:tenant_id, 'CartService', 'CustomerReadOnly', '["cart:read:own"]');
```

**Permission Check**:
```scala
// Permission format: "service:action:scope"
// Examples: "cart:read:own", "cart:write:*", "user:manage"

object PermissionChecker {
  def hasPermission(
    tenantId: TenantId,
    userId: UserId,
    requiredPermission: String
  ): Future[Boolean] = {
    for {
      userRole <- getUserRole(tenantId, userId)
      rolePermissions <- getRolePermissions(tenantId, "CartService", userRole)
    } yield {
      rolePermissions.exists(matches(_, requiredPermission))
    }
  }
  
  def matches(granted: String, required: String): Boolean = {
    val grantedParts = granted.split(":")
    val requiredParts = required.split(":")
    
    grantedParts.zip(requiredParts).forall {
      case (g, r) if g == "*" => true
      case (g, r) => g == r
    }
  }
}

// Use in endpoint authorization
def addItemToCart(
  tenantId: TenantId,
  userId: UserId,
  cartId: CartId,
  item: Item
): Future[Response] = {
  PermissionChecker.hasPermission(tenantId, userId, "cart:write:own").flatMap {
    case true => processAddItem(cartId, item)
    case false => Future.successful(Response.Forbidden("Insufficient permissions"))
  }
}
```

**Tenant Admin Delegation**:
```scala
// Tenant admins can assign roles to their users
def assignRole(
  tenantId: TenantId,
  adminUserId: UserId,
  targetUserId: UserId,
  roleName: String
): Future[Either[Error, Unit]] = {
  for {
    // Verify admin has permission to manage users
    canManage <- PermissionChecker.hasPermission(tenantId, adminUserId, "user:manage")
    
    result <- if (canManage) {
      tenantUserRepo.upsert(TenantUser(
        tenantId = tenantId,
        userId = targetUserId,
        roleName = roleName,
        createdBy = Some(adminUserId)
      )).map(Right(_))
    } else {
      Future.successful(Left(InsufficientPermissionsError))
    }
  } yield result
}
```

**Audit Logging**:
```scala
// Every action logged with tenant-service-role context
case class AuditLog(
  id: UUID,
  tenantId: TenantId,
  userId: UserId,
  serviceName: String,
  action: String,
  resourceId: String,
  roleName: String,
  permissions: Seq[String],
  result: String, // "success" or "denied"
  timestamp: Instant,
  metadata: Map[String, String]
)

// Example audit entry
AuditLog(
  id = UUID.randomUUID(),
  tenantId = tenant1,
  userId = user123,
  serviceName = "CartService",
  action = "cart:write",
  resourceId = "cart-abc",
  roleName = "CustomerUser",
  permissions = Seq("cart:read", "cart:write:own"),
  result = "success",
  timestamp = Instant.now(),
  metadata = Map("item_id" -> "item-xyz")
)
```

**Service-Specific Roles**:
```scala
// Each service defines its own role hierarchy
object CartServiceRoles {
  val CustomerAdmin = ServiceRole(
    name = "CustomerAdmin",
    permissions = Set(
      "cart:read:*",
      "cart:write:*",
      "cart:delete:*",
      "user:manage"
    )
  )
  
  val CustomerUser = ServiceRole(
    name = "CustomerUser",
    permissions = Set(
      "cart:read:own",
      "cart:write:own",
      "cart:checkout:own"
    )
  )
  
  val CustomerReadOnly = ServiceRole(
    name = "CustomerReadOnly",
    permissions = Set(
      "cart:read:own"
    )
  )
}
```

## Implementation Guidance

### Progressive Implementation (MVP → Full)

**Phase 1: MVP (Seam Levels 1-2)**:
- Implement Seam Level 1: Tenant isolation (mandatory for all services)
- Implement Seam Level 2: Service subscriptions (enable/disable, basic SLA tiers)
- Document Seam Levels 3-4 in architecture but defer implementation
- Estimated effort: 2-3 sprints

**Phase 2: Standard (Add Seam Level 3)**:
- Implement feature flags per tenant
- Basic A/B testing capability
- Progressive rollout framework
- Estimated effort: 1-2 sprints

**Phase 3: Advanced (Add Seam Level 4)**:
- Full RBAC within tenant context
- Tenant admin delegation
- Fine-grained permissions
- Comprehensive audit logging
- Estimated effort: 2-3 sprints

### Entity-Tenant Relationship

**Critical Principle**: "All tenant implies entity but entity does not imply tenant"

**Entities WITHOUT Tenant Status**:
- Prospect organizations (pre-sale, no billing)
- Free-tier users (using services without subscription)
- Partner organizations (SSO only, no direct service use)
- Inactive/suspended accounts (lost tenant status)

**Entities WITH Tenant Status**:
- Active subscribers with billing relationship
- Rooted in entity (organization or individual)
- Have members with roles for self-management
- Payment responsibility established

**Promotion Workflow**:
```
Entity Created → Entity Exists (no tenant status)
              ↓
         Provisioning Workflow Initiated
              ↓
         Tenant Status Granted
              ↓
         Services Activated (Seam Level 2)
              ↓
         Users Assigned Roles (Seam Level 4)
              ↓
         Features Enabled (Seam Level 3)
```

### Database Design Patterns

**Tenant Isolation**:
```sql
-- Option 1: Row-level (recommended for most cases)
CREATE TABLE carts (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  -- tenant_id in every table
);

-- Option 2: Schema-per-tenant (for very large tenants)
CREATE SCHEMA tenant_abc123;
CREATE TABLE tenant_abc123.carts (
  id UUID PRIMARY KEY
  -- no tenant_id needed, schema provides isolation
);

-- Option 3: Database-per-tenant (for highest isolation)
-- Separate PostgreSQL database per tenant
-- Most expensive, used only for regulated industries
```

**Recommendation**: Use row-level isolation (Option 1) for TJMPaaS services unless specific requirements dictate otherwise.

### Kubernetes Multi-Tenancy

**Pod-per-Tenant** (not recommended for TJMPaaS):
- Separate pod per tenant
- Complete isolation but expensive
- Use only for very large tenants (>$100K/year)

**Shared Pods with Tenant Sharding** (recommended):
- Multiple tenants per pod
- Pekko Cluster sharding by tenant_id
- Actor instances isolated per tenant
- Resource limits per pod (not per tenant)

```scala
// Pekko Cluster sharding by tenant
val sharding = ClusterSharding(system).init(Entity(
  typeKey = EntityTypeKey[CartCommand]("Cart"),
  createBehavior = ctx => CartActor(ctx.entityId),
  settings = ClusterShardingSettings(system),
  messageExtractor = new HashCodeMessageExtractor[CartCommand](
    numberOfShards = 100
  ) {
    override def entityId(message: CartCommand): String = {
      s"${message.tenantId}-${message.cartId}"
    }
  }
))
```

## Validation

Success criteria:

- All services implement Seam Level 1 (tenant isolation) - 100% compliance
- Production services implement Seam Level 2 (service subscriptions) - 80%+ compliance
- No tenant data leakage incidents in production
- Feature rollouts use Seam Level 3 (feature flags) - 50%+ of new features
- Tenant admin delegation (Seam Level 4) available in Entity Management Service

Metrics:
- Tenant isolation test coverage >95% (automated tests)
- Zero tenant data bleed incidents
- Average feature rollout uses 3+ stages (5% → 25% → 50% → 100%)
- Tenant admin self-service reduces support tickets by 50%

## Related Standards

- [POL-cross-service-consistency.md](./POL-cross-service-consistency.md) - Tier 1 requires Seam Levels 1-2
- [PROVISIONING-SERVICE-PATTERN.md](./PROVISIONING-SERVICE-PATTERN.md) - Tenant provisioning workflow
- [API-DESIGN-STANDARDS.md](./API-DESIGN-STANDARDS.md) - X-Tenant-ID header requirements
- [EVENT-SCHEMA-STANDARDS.md](./EVENT-SCHEMA-STANDARDS.md) - tenant_id in event metadata

## Related Governance

- [ADR-0005: Reactive Manifesto Alignment](../governance/ADRs/ADR-0005-reactive-manifesto.md) - Message-driven multi-tenancy
- [ADR-0006: Agent-Based Service Patterns](../governance/ADRs/ADR-0006-agent-patterns.md) - Actor per tenant pattern
- [ADR-0007: CQRS and Event-Driven Architecture](../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) - Multi-tenant CQRS

## Notes

**Why Four Seams?**

- **Seam 1**: Fundamental security boundary (tenant data isolation)
- **Seam 2**: Commercial boundary (who pays for what)
- **Seam 3**: Product flexibility boundary (feature experimentation)
- **Seam 4**: Operational delegation boundary (tenant self-management)

Each seam addresses a distinct concern; conflating them leads to complexity.

**Entity Management Service Demonstrates All Seams**:

- Level 1: Complete tenant isolation in entities/organizations
- Level 2: Entity Management itself is a service tenants subscribe to
- Level 3: Feature flags for entity hierarchy depth, org chart features
- Level 4: Tenant admins manage their organization's user roles

Other services can copy these patterns wholesale.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-28 | Initial architecture standard establishing 4-level seam model | Tony Moores |
