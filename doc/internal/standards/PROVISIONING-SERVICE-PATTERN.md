# Provisioning Service Pattern: DRY Operational Control Surface

**Status**: Active Standard  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Category**: Architecture Pattern

## Context

Every TJMPaaS service requires provisioning workflows: creating tenants, activating services, onboarding users, allocating resources. Without a consistent approach, each service implements its own provisioning logic, leading to:
- Inconsistent provisioning experiences across services
- Duplicated provisioning code in every service
- No single place to implement operational improvements
- Complex integration for multi-service provisioning
- Difficult to ensure idempotency and retry safety

### Problem Statement

Establish a DRY (Don't Repeat Yourself) operational control surface for all provisioning workflows across TJMPaaS services, ensuring:
- **Consistency**: Same workflow patterns for provisioning anything
- **Reusability**: Single implementation used by all services
- **Progressive Familiarity**: Learn provisioning once, apply everywhere
- **Operational Excellence**: Single place to add monitoring, retry logic, validation
- **Multi-Step Orchestration**: Handle complex provisioning spanning multiple services

### Goals

- Single Provisioning Service used by all TJMPaaS services
- Consistent workflow patterns (request → start → complete/fail)
- Idempotent operations (safe to retry)
- Audit trail for all provisioning activities
- Support for both synchronous and asynchronous provisioning
- Clear operational control surface for all provisioning workflows

## Pattern

### Provisioning Service as DRY Control Surface

**Core Concept**: All provisioning workflows delegate to a centralized Provisioning Service rather than implementing provisioning logic in each service.

```
┌─────────────────────────────────────────────────────────────┐
│                   Provisioning Service                       │
│                 (DRY Control Surface)                        │
│                                                              │
│  ProvisioningOrchestrator Actor                             │
│  - Coordinates multi-step workflows                          │
│  - Handles retries and failures                              │
│  - Emits audit events                                        │
│  - Ensures idempotency                                       │
└─────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ Entity           │  │ CartService      │  │ OrderService     │
│ Management       │  │                  │  │                  │
│ Service          │  │ Delegates cart   │  │ Delegates order  │
│                  │  │ provisioning to  │  │ provisioning to  │
│ Delegates tenant │  │ Provisioning     │  │ Provisioning     │
│ provisioning to  │  │ Service          │  │ Service          │
│ Provisioning     │  │                  │  │                  │
│ Service          │  └──────────────────┘  └──────────────────┘
└──────────────────┘
```

### Provisioning Workflow Types

The Provisioning Service supports four primary workflow types:

**1. Tenant Provisioning**:
```scala
case class ProvisionTenantRequest(
  requestId: UUID,
  entityId: EntityId,
  subscriptionPlan: SubscriptionPlan,
  billingInfo: BillingInfo,
  requestedBy: UserId
)

// Workflow steps:
// 1. Validate entity exists and eligible for tenant status
// 2. Create tenant record in Entity Management Service
// 3. Initialize billing account
// 4. Set up default service subscriptions
// 5. Create default admin user role
// 6. Emit TenantProvisioned event
```

**2. Service Provisioning** (Enable service for tenant):
```scala
case class ProvisionServiceRequest(
  requestId: UUID,
  tenantId: TenantId,
  serviceName: String,
  slaTier: SlaTier,
  requestedBy: UserId
)

// Workflow steps:
// 1. Validate tenant exists and active
// 2. Check service availability for tenant's subscription
// 3. Create tenant_service_subscription record
// 4. Initialize service-specific resources (databases, actors, etc.)
// 5. Set default rate limits for SLA tier
// 6. Emit ServiceProvisioned event
```

**3. User Provisioning** (Add user to tenant):
```scala
case class ProvisionUserRequest(
  requestId: UUID,
  tenantId: TenantId,
  email: Email,
  roleName: String,
  requestedBy: UserId
)

// Workflow steps:
// 1. Validate tenant exists and requester has user:manage permission
// 2. Create or lookup user by email
// 3. Add user to tenant with specified role
// 4. Send invitation email
// 5. Initialize user preferences
// 6. Emit UserProvisioned event
```

**4. Resource Provisioning** (Allocate resources for service):
```scala
case class ProvisionResourceRequest(
  requestId: UUID,
  tenantId: TenantId,
  serviceName: String,
  resourceType: ResourceType, // Database, Storage, Compute
  resourceSpec: ResourceSpec,
  requestedBy: UserId
)

// Workflow steps:
// 1. Validate tenant service subscription
// 2. Check quota limits for tenant SLA tier
// 3. Allocate resource (create database, allocate storage, etc.)
// 4. Update resource tracking/billing
// 5. Configure monitoring and alerts
// 6. Emit ResourceProvisioned event
```

### ProvisioningOrchestrator Actor Pattern

**Actor Design**:
```scala
object ProvisioningOrchestrator {
  sealed trait Command
  
  case class ProvisionTenant(
    request: ProvisionTenantRequest,
    replyTo: ActorRef[ProvisioningResponse]
  ) extends Command
  
  case class ProvisionService(
    request: ProvisionServiceRequest,
    replyTo: ActorRef[ProvisioningResponse]
  ) extends Command
  
  case class ProvisionUser(
    request: ProvisionUserRequest,
    replyTo: ActorRef[ProvisioningResponse]
  ) extends Command
  
  case class ProvisionResource(
    request: ProvisionResourceRequest,
    replyTo: ActorRef[ProvisioningResponse]
  ) extends Command
  
  // Internal messages
  private case class StepCompleted(step: String, result: Any) extends Command
  private case class StepFailed(step: String, error: Throwable) extends Command
  
  sealed trait ProvisioningResponse
  case class ProvisioningStarted(requestId: UUID) extends ProvisioningResponse
  case class ProvisioningCompleted(requestId: UUID, resourceId: String) extends ProvisioningResponse
  case class ProvisioningFailed(requestId: UUID, reason: String) extends ProvisioningResponse
  
  // Event sourcing for audit trail
  sealed trait Event
  case class ProvisioningRequested(requestId: UUID, workflowType: String, tenantId: TenantId) extends Event
  case class ProvisioningStepStarted(requestId: UUID, step: String) extends Event
  case class ProvisioningStepCompleted(requestId: UUID, step: String) extends Event
  case class ProvisioningStepFailed(requestId: UUID, step: String, reason: String) extends Event
  case class ProvisioningSucceeded(requestId: UUID, resourceId: String) extends Event
  case class ProvisioningFailedEvent(requestId: UUID, reason: String) extends Event
  
  def apply(requestId: UUID): EventSourcedBehavior[Command, Event, State] = {
    EventSourcedBehavior[Command, Event, State](
      persistenceId = PersistenceId.of("ProvisioningOrchestrator", requestId.toString),
      emptyState = State.empty(requestId),
      commandHandler = handleCommand,
      eventHandler = handleEvent
    )
  }
  
  case class State(
    requestId: UUID,
    workflowType: Option[String],
    completedSteps: Set[String],
    failedStep: Option[String],
    status: ProvisioningStatus
  )
  
  sealed trait ProvisioningStatus
  case object NotStarted extends ProvisioningStatus
  case object InProgress extends ProvisioningStatus
  case object Completed extends ProvisioningStatus
  case object Failed extends ProvisioningStatus
}
```

### Idempotency and Retry Safety

**Idempotency Key**:
```scala
// Every provisioning request includes idempotency key
case class ProvisionTenantRequest(
  requestId: UUID, // Idempotency key
  entityId: EntityId,
  subscriptionPlan: SubscriptionPlan,
  billingInfo: BillingInfo,
  requestedBy: UserId
)

// Provisioning Service checks if request already processed
def handleProvisionRequest(request: ProvisionTenantRequest): Future[ProvisioningResponse] = {
  provisioningRepo.findByRequestId(request.requestId).flatMap {
    case Some(existing) if existing.status == Completed =>
      // Already completed - return success (idempotent)
      Future.successful(ProvisioningCompleted(existing.requestId, existing.resourceId))
    
    case Some(existing) if existing.status == InProgress =>
      // Already in progress - return started status
      Future.successful(ProvisioningStarted(existing.requestId))
    
    case Some(existing) if existing.status == Failed =>
      // Previously failed - retry the provisioning
      retryProvisioning(request)
    
    case None =>
      // New request - start provisioning
      startProvisioning(request)
  }
}
```

**Retry Logic**:
```scala
// Each step is retryable with exponential backoff
def executeStepWithRetry[T](
  stepName: String,
  operation: => Future[T],
  maxRetries: Int = 3
): Future[T] = {
  def attempt(retriesLeft: Int, delay: FiniteDuration): Future[T] = {
    operation.recoverWith {
      case ex: TransientError if retriesLeft > 0 =>
        logger.warn(s"Step $stepName failed, retrying in $delay (${retriesLeft} retries left)", ex)
        after(delay)(attempt(retriesLeft - 1, delay * 2))
      
      case ex =>
        logger.error(s"Step $stepName failed permanently", ex)
        Future.failed(ex)
    }
  }
  
  attempt(maxRetries, 100.milliseconds)
}
```

### Event Sourcing for Audit Trail

**Complete Audit Trail**:
```scala
// Every provisioning step generates events
val events = Seq(
  ProvisioningRequested(requestId, "tenant", tenantId),
  ProvisioningStepStarted(requestId, "validate-entity"),
  ProvisioningStepCompleted(requestId, "validate-entity"),
  ProvisioningStepStarted(requestId, "create-tenant"),
  ProvisioningStepCompleted(requestId, "create-tenant"),
  ProvisioningStepStarted(requestId, "setup-billing"),
  ProvisioningStepCompleted(requestId, "setup-billing"),
  ProvisioningStepStarted(requestId, "activate-services"),
  ProvisioningStepCompleted(requestId, "activate-services"),
  ProvisioningSucceeded(requestId, tenantId.toString)
)

// Events persisted to event store
// Full audit trail available for compliance
// Can replay provisioning workflow for debugging
```

### Integration with Services

**Entity Management Service Example**:
```scala
// Entity Management delegates tenant provisioning to Provisioning Service
object TenantActor {
  case class PromoteToTenant(
    subscriptionPlan: SubscriptionPlan,
    billingInfo: BillingInfo,
    replyTo: ActorRef[Response]
  ) extends Command
  
  def handlePromoteToTenant(
    state: EntityState,
    cmd: PromoteToTenant,
    provisioningService: ActorRef[ProvisioningOrchestrator.Command]
  ): Effect[Event, EntityState] = {
    
    // Send provisioning request to Provisioning Service
    val provisionRequest = ProvisionTenantRequest(
      requestId = UUID.randomUUID(),
      entityId = state.entityId,
      subscriptionPlan = cmd.subscriptionPlan,
      billingInfo = cmd.billingInfo,
      requestedBy = cmd.replyTo // assuming authenticated
    )
    
    context.ask(provisioningService, ProvisioningOrchestrator.ProvisionTenant(provisionRequest, _)) {
      case Success(ProvisioningCompleted(_, tenantId)) =>
        TenantProvisioningCompleted(TenantId(tenantId))
      case Success(ProvisioningFailed(_, reason)) =>
        TenantProvisioningFailed(reason)
      case Failure(ex) =>
        TenantProvisioningFailed(ex.getMessage)
    }
    
    Effect
      .persist(TenantProvisioningStarted(provisionRequest.requestId))
      .thenReply(cmd.replyTo)(_ => ProvisioningInitiated)
  }
}
```

**CartService Example**:
```scala
// CartService delegates cart provisioning to Provisioning Service
def provisionCartForTenant(tenantId: TenantId): Future[CartProvisioned] = {
  val request = ProvisionServiceRequest(
    requestId = UUID.randomUUID(),
    tenantId = tenantId,
    serviceName = "CartService",
    slaTier = SlaTier.Bronze, // default tier
    requestedBy = systemUserId
  )
  
  provisioningService.ask(ProvisionService(request, _)).map {
    case ProvisioningCompleted(_, resourceId) =>
      CartProvisioned(tenantId, CartServiceId(resourceId))
    case ProvisioningFailed(_, reason) =>
      throw ProvisioningException(s"Failed to provision CartService for tenant $tenantId: $reason")
  }
}
```

## Benefits

**For Service Developers**:
- Don't implement provisioning logic (delegate to Provisioning Service)
- Consistent patterns across all services
- Retry logic, idempotency, audit trail handled centrally
- Focus on service-specific business logic

**For Operators**:
- Single place to monitor all provisioning activities
- Centralized dashboards and alerts
- Consistent troubleshooting procedures
- Easy to add operational improvements (all services benefit)

**For Customers/Tenants**:
- Consistent provisioning experience across services
- Reliable provisioning (retry logic built-in)
- Clear status tracking (requestId for all workflows)
- Audit trail for compliance

**For TJMPaaS**:
- DRY principle: Write provisioning logic once
- Progressive familiarity: Learn provisioning pattern once
- Operational excellence: Improve one service, all benefit
- Faster service development: Provisioning already solved

## Implementation Guidance

### Provisioning Service Architecture

**Components**:
```
ProvisioningService/
├── api/
│   └── ProvisioningApi.scala          # REST API endpoints
├── actors/
│   ├── ProvisioningOrchestrator.scala # Main orchestrator actor
│   ├── TenantProvisioner.scala        # Tenant-specific logic
│   ├── ServiceProvisioner.scala       # Service activation logic
│   ├── UserProvisioner.scala          # User onboarding logic
│   └── ResourceProvisioner.scala      # Resource allocation logic
├── workflows/
│   ├── TenantProvisioningWorkflow.scala
│   ├── ServiceProvisioningWorkflow.scala
│   ├── UserProvisioningWorkflow.scala
│   └── ResourceProvisioningWorkflow.scala
├── repository/
│   └── ProvisioningRepository.scala   # Event store queries
└── events/
    └── ProvisioningEvents.scala       # Event definitions
```

**API Design**:
```scala
// REST API for provisioning workflows
POST /api/v1/provisioning/tenant
POST /api/v1/provisioning/service
POST /api/v1/provisioning/user
POST /api/v1/provisioning/resource

// Status endpoint (idempotent check)
GET /api/v1/provisioning/{requestId}/status

// All endpoints require X-Tenant-ID header (except tenant creation)
// All endpoints return requestId for tracking
```

### Multi-Step Workflow Pattern

**Saga Pattern for Distributed Transactions**:
```scala
trait ProvisioningWorkflow {
  def steps: Seq[WorkflowStep]
  
  case class WorkflowStep(
    name: String,
    execute: () => Future[StepResult],
    compensate: () => Future[Unit] // Rollback if later step fails
  )
  
  def executeWorkflow(): Future[WorkflowResult] = {
    steps.foldLeft(Future.successful(Seq.empty[StepResult])) { (acc, step) =>
      acc.flatMap { results =>
        step.execute().map(results :+ _).recoverWith {
          case ex =>
            // Step failed - compensate all previous steps
            logger.error(s"Step ${step.name} failed, compensating previous steps", ex)
            compensateSteps(results.reverse).flatMap(_ => Future.failed(ex))
        }
      }
    }.map(results => WorkflowResult.Success(results))
  }
  
  def compensateSteps(results: Seq[StepResult]): Future[Unit] = {
    results.zip(steps).foldLeft(Future.successful(())) { case (acc, (result, step)) =>
      acc.flatMap { _ =>
        step.compensate().recover {
          case ex =>
            logger.error(s"Compensation failed for step ${step.name}", ex)
            () // Log but continue compensating other steps
        }
      }
    }
  }
}
```

**Example: Tenant Provisioning Workflow**:
```scala
class TenantProvisioningWorkflow(
  entityService: EntityService,
  billingService: BillingService,
  subscriptionService: SubscriptionService
) extends ProvisioningWorkflow {
  
  override def steps: Seq[WorkflowStep] = Seq(
    WorkflowStep(
      name = "validate-entity",
      execute = () => entityService.validateEligible(request.entityId),
      compensate = () => Future.successful(()) // No compensation needed
    ),
    WorkflowStep(
      name = "create-tenant",
      execute = () => entityService.createTenant(request.entityId),
      compensate = () => entityService.deleteTenant(createdTenantId)
    ),
    WorkflowStep(
      name = "setup-billing",
      execute = () => billingService.createAccount(createdTenantId, request.billingInfo),
      compensate = () => billingService.deleteAccount(billingAccountId)
    ),
    WorkflowStep(
      name = "activate-services",
      execute = () => subscriptionService.activateDefault(createdTenantId, request.subscriptionPlan),
      compensate = () => subscriptionService.deactivateAll(createdTenantId)
    )
  )
}
```

### Observability

**Metrics**:
```scala
// Provisioning request rates
metrics.counter("provisioning.requests")
  .tag("workflow_type", workflowType)
  .tag("tenant_id", tenantId.toString)
  .increment()

// Provisioning duration
metrics.timer("provisioning.duration")
  .tag("workflow_type", workflowType)
  .tag("status", "success") // or "failed"
  .record(duration)

// Step-level metrics
metrics.timer("provisioning.step.duration")
  .tag("workflow_type", workflowType)
  .tag("step", stepName)
  .tag("status", "success") // or "failed"
  .record(stepDuration)

// Retry metrics
metrics.counter("provisioning.retries")
  .tag("workflow_type", workflowType)
  .tag("step", stepName)
  .increment()
```

**Logging**:
```scala
// Structured logs with requestId for tracing
logger.info(
  "Provisioning started",
  "request_id" -> requestId,
  "workflow_type" -> workflowType,
  "tenant_id" -> tenantId,
  "requested_by" -> requestedBy
)

logger.info(
  "Provisioning step started",
  "request_id" -> requestId,
  "step" -> stepName
)

logger.info(
  "Provisioning step completed",
  "request_id" -> requestId,
  "step" -> stepName,
  "duration_ms" -> duration.toMillis
)

logger.error(
  "Provisioning failed",
  "request_id" -> requestId,
  "workflow_type" -> workflowType,
  "failed_step" -> stepName,
  "reason" -> reason,
  ex
)
```

**Dashboards**:
- Provisioning request rate (per workflow type, per tenant)
- Provisioning success rate (per workflow type)
- Provisioning duration (p50, p95, p99)
- Failed provisioning reasons (top N)
- Retry rates (per step)
- Active provisioning workflows (in-progress count)

## Validation

Success criteria:

- All TJMPaaS services delegate provisioning to Provisioning Service (100% compliance)
- Zero duplicate provisioning logic in service codebases
- Provisioning success rate >99.9% (excluding permanent failures like invalid data)
- Provisioning idempotency verified (retry same request = same outcome)
- Complete audit trail available for all provisioning activities

Metrics:
- Services using Provisioning Service: >80% of production services
- Provisioning success rate: >99.9%
- Average provisioning duration: <30 seconds for simple workflows
- Retry success rate: >95% (transient failures recovered)

## Related Standards

- [POL-cross-service-consistency.md](./POL-cross-service-consistency.md) - Tier 1 consistency includes provisioning
- [MULTI-TENANT-SEAM-ARCHITECTURE.md](./MULTI-TENANT-SEAM-ARCHITECTURE.md) - Tenant provisioning workflow
- [API-DESIGN-STANDARDS.md](./API-DESIGN-STANDARDS.md) - Provisioning API conventions
- [EVENT-SCHEMA-STANDARDS.md](./EVENT-SCHEMA-STANDARDS.md) - Provisioning event schemas

## Related Governance

- [ADR-0006: Agent-Based Service Patterns](../governance/ADRs/ADR-0006-agent-patterns.md) - ProvisioningOrchestrator actor
- [ADR-0007: CQRS and Event-Driven Architecture](../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) - Event sourcing for audit

## Notes

**Why Separate Provisioning Service?**

- **DRY**: Write provisioning logic once, not in every service
- **Consistency**: Same workflow patterns everywhere
- **Progressive Familiarity**: Learn once, apply everywhere (POL-cross-service-consistency Tier 1)
- **Operational Excellence**: Single place to improve retry logic, monitoring, audit
- **Multi-Service Orchestration**: Provisioning often spans multiple services (tenant → services → users → resources)

**Provisioning vs Domain Logic**:

- **Provisioning**: Operational setup (create database, allocate resources, configure access)
- **Domain Logic**: Business rules (cart rules, pricing logic, order fulfillment)

Provisioning Service handles operational setup, delegates to services for domain validation.

**Entity Management Service as Primary User**:

Entity Management Service is the primary consumer of Provisioning Service:
- Tenant provisioning (entity → tenant promotion)
- Service activation (enable services for tenant)
- User provisioning (add users to tenant)

Other services use Provisioning Service for service-specific resource allocation.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-28 | Initial pattern definition establishing DRY operational control surface | Tony Moores |
