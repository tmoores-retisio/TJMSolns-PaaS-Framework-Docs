# POL: Cross-Service Consistency and Progressive Familiarity

**Status**: Active  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Category**: Policy

## Context

TJMPaaS aims to build a library of services that can be deployed independently while maintaining consistency in operational patterns. As services multiply, users (developers, operators, customers) benefit from progressive familiarity—learning patterns in one service that apply across all services.

### Problem Statement

Without consistency standards:
- Each service reinvents operational patterns
- Learning curve multiplies per service
- Operational complexity grows non-linearly
- Integration patterns diverge
- Customer onboarding becomes service-specific

### Goals

- **Progressive Familiarity**: Learning one service helps understand others
- **Operational Consistency**: Common patterns for provisioning, monitoring, deployment
- **Integration Predictability**: Services integrate in predictable ways
- **Reduced Cognitive Load**: Consistency reduces mental overhead
- **Balanced Innovation**: Allow innovation within consistency framework

## Policy

**TJMPaaS services SHALL maintain consistency across the following dimensions**, achieving progressive familiarity through standardized patterns while allowing service-specific optimization.

### Progressive Familiarity Framework

**Consistency Targets** (cumulative):
- **50% Familiarity** (Tier 1 - Essential): Core operational patterns identical
- **75% Familiarity** (Tier 2 - Standard): Common integration patterns identical
- **87.5% Familiarity** (Tier 3 - Advanced): Domain-specific patterns follow templates
- **100% Familiarity** (Aspirational): Service-specific innovation within framework

### Tier 1: Essential Consistency (50% - MANDATORY)

**Multi-Tenant Architecture**:
- ALL services MUST implement 4-level seam architecture (see MULTI-TENANT-SEAM-ARCHITECTURE.md)
- X-Tenant-ID header MUST be present on all API requests
- tenant_id MUST be included in all database tables
- tenant_id MUST be present in all event metadata
- Tenant isolation MUST be enforced at data layer

**Actor Model Patterns**:
- Pekko actors for concurrency (Apache 2.0 licensed per PDR-0005)
- OneForOne supervision strategy per ADR-0006
- One actor instance per tenant per entity type
- Actor state machines follow functional patterns (immutable state)
- Actor message protocols use sealed traits with case classes

**CQRS Implementation** (per ADR-0007):
- Level 2 (Standard CQRS) for most services
- Level 3 (Full CQRS/ES) for audit-critical services (orders, payments, inventory)
- Command/Query separation explicit in API design
- Event sourcing with Pekko Persistence for Level 3

**Event-Driven Integration**:
- Apache Kafka for inter-service events
- Event schemas follow EVENT-SCHEMA-STANDARDS.md
- At-least-once delivery guarantee
- Idempotent event handlers
- tenant_id in all event metadata

**API Design**:
- REST with HATEOAS Level 2 (per best practices)
- OpenAPI 3.1 specification for all endpoints
- X-Tenant-ID header on all requests (mandatory)
- Versioning via URL path (/v1/, /v2/)
- Standard error response format (see API-DESIGN-STANDARDS.md)

**Observability**:
- Prometheus metrics with tenant_id label
- Structured JSON logging with tenant_id field
- OpenTelemetry distributed tracing
- /health and /ready endpoints (Kubernetes liveness/readiness)
- Standard dashboard templates per service (see TELEMETRY-SPECIFICATION template)

**Provisioning Workflows**:
- ALL services delegate provisioning to Provisioning Service
- ProvisioningOrchestrator pattern for multi-step workflows
- Standard events: ProvisioningRequested, ProvisioningStarted, ProvisioningCompleted, ProvisioningFailed
- Idempotent provisioning operations (retry-safe)

### Tier 2: Standard Consistency (75% - RECOMMENDED)

**Testing Standards**:
- munit for unit tests (per ADR-0004)
- BDD scenarios with .feature files (Gherkin syntax)
- Contract tests between services
- Multi-tenant isolation tests (tenant data bleed detection)
- Minimum 80% code coverage for business logic

**Security Patterns**:
- JWT tokens with tenant_id claim
- Role-based access control (RBAC) within tenant context
- TLS 1.3 for all inter-service communication
- At-rest encryption for sensitive data (AES-256)
- Audit logging with 7-year retention for compliance

**Deployment Patterns**:
- Kubernetes Deployments for stateless components
- StatefulSets for stateful components (actor sharding)
- HPA (Horizontal Pod Autoscaler) for elastic scaling
- Rolling update strategy (zero-downtime deployments)
- Blue-green deployment capability for major changes

**Error Handling**:
- Circuit breakers for downstream dependencies (using Pekko patterns)
- Exponential backoff for retries (100ms, 200ms, 400ms, 800ms, fail)
- Bulkheads for fault isolation
- Graceful degradation (degraded mode over complete failure)
- Standard error codes and messages

**Configuration Management**:
- Environment variables for deployment-specific config
- ConfigMaps for service configuration
- Secrets for sensitive data (encrypted at rest)
- Feature flags for progressive rollout (seam level 3)
- Tenant-specific configuration via database

### Tier 3: Advanced Consistency (87.5% - ENCOURAGED)

**Domain Model Patterns**:
- Domain entities follow value object pattern (immutability)
- Aggregate roots as event-sourced actors
- Entity-to-Tenant relationship ("all tenant implies entity but entity does not imply tenant")
- Hierarchical organization models (parent-child relationships)

**Read Model Optimization**:
- PostgreSQL for relational read models
- Elasticsearch for search read models
- Redis for caching (tenant-partitioned)
- Read model projections from event streams
- Eventually consistent read models (< 1 second lag)

**Actor Supervision**:
- Service-level supervisor actor per tenant
- Entity-level actors (CartActor, OrderActor, etc.) per tenant-entity
- Supervision strategies: Restart for recoverable errors, Stop for unrecoverable, Escalate for parent decision
- Actor passivation after idle timeout (10 minutes default)

**Operational Runbooks**:
- Deployment runbooks follow DEPLOYMENT-RUNBOOK template
- Troubleshooting playbooks per failure mode
- Rollback procedures documented
- Incident response procedures
- Capacity planning guides

### Tier 4: Service-Specific Innovation (100% - ALLOWED)

**Domain-Specific Logic**:
- Business rules unique to service domain
- Service-specific aggregate boundaries
- Domain-specific events and commands
- Service-specific performance optimizations
- Custom read model schemas

**Integration Patterns**:
- Service-specific sagas for distributed transactions
- Custom event choreography patterns
- Domain-specific API extensions (beyond core CRUD)
- Service-specific caching strategies

**Performance Optimizations**:
- Service-specific indexes and queries
- Domain-specific batch processing
- Custom sharding strategies (beyond tenant sharding)
- Service-specific resource limits

## Rationale

### Why Progressive Familiarity?

**50% Familiarity** (Tier 1):
- Learning one service = 50% understanding of next service
- Core operations (provision, deploy, monitor, troubleshoot) identical
- Reduces onboarding time by 50%

**75% Familiarity** (Tier 2):
- Adding standard patterns = another 25% understanding
- Common integration, testing, security patterns transfer
- Reduces integration complexity by 75%

**87.5% Familiarity** (Tier 3):
- Advanced patterns = another 12.5% understanding
- Domain model patterns, operational runbooks similar
- Reduces operational complexity by 87.5%

**100% Familiarity** (Aspirational):
- Remaining 12.5% is service-specific innovation
- Allows differentiation without chaos
- Innovation within framework, not reinvention of framework

### Benefits

**For Developers**:
- Learn patterns once, apply across services
- Predictable integration patterns
- Standard testing and deployment approaches
- Code reviews easier (consistent patterns)

**For Operators**:
- Single set of operational patterns
- Dashboard familiarity across services
- Troubleshooting procedures similar
- Capacity planning templates reusable

**For Customers/Tenants**:
- Consistent provisioning workflows
- Predictable service behavior
- Similar monitoring and alerting
- Easier adoption of additional services

**For TJMPaaS**:
- Faster service development (templates + patterns)
- Reduced integration testing (predictable contracts)
- Easier maintenance (consistent codebases)
- Commercial credibility (professional consistency)

### Trade-offs

**Pros**:
- Dramatic reduction in cognitive load
- Faster development and deployment
- Predictable behavior and integration
- Progressive learning curve

**Cons**:
- Some innovation constrained to framework
- Must maintain consistency as services grow
- Template overhead for simple services
- Discipline required to maintain standards

## Implementation

### Enforcement Mechanisms

**Documentation**:
- Every service MUST document consistency tier compliance in SERVICE-CANVAS.md
- SERVICE-CHARTER.md MUST justify any Tier 1 exceptions (requires ADR)
- ARCHITECTURE.md MUST reference relevant standards documents

**Code Reviews**:
- Pull requests MUST verify Tier 1 compliance (blocking)
- Pull requests SHOULD verify Tier 2 compliance (non-blocking but encouraged)
- Tier 3 deviations SHOULD be documented in code comments

**Automated Testing**:
- Multi-tenant isolation tests MUST pass (Tier 1)
- Contract tests MUST pass for integration points (Tier 2)
- Code coverage MUST meet 80% threshold (Tier 2)

**Service Registry**:
- REGISTRY.md tracks consistency tier compliance per service
- New services start at Tier 1, progress to higher tiers
- Tier compliance visible in service status

### Exception Process

**Tier 1 Exceptions**:
- Requires ADR justifying exception
- Must demonstrate technical impossibility or significant performance benefit
- Reviewed quarterly for removal
- Maximum 2 Tier 1 exceptions per service

**Tier 2 Deviations**:
- Document in SERVICE-CANVAS.md with rationale
- No formal approval required
- Encouraged to converge over time

**Tier 3 Deviations**:
- Expected for domain-specific needs
- Document in ARCHITECTURE.md
- No formal approval required

### Compliance Tracking

**Service Maturity Levels**:
- **Emerging** (Design phase): Tier 1 planned
- **Developing** (Implementation): Tier 1 implemented
- **Standard** (Production): Tier 1-2 implemented
- **Mature** (Scaled): Tier 1-3 implemented

**Metrics**:
- Consistency compliance score (% of Tier 1 patterns implemented)
- Progressive familiarity index (average tier across services)
- Exception count (Tier 1 exceptions across all services)
- Convergence trend (services moving to higher tiers over time)

## Examples

### Entity Management Service (Reference Implementation)

**Tier 1 Compliance** (50% - Essential):
- ✅ Multi-tenant seam architecture (4 levels documented, levels 1-2 implemented)
- ✅ Pekko actors (TenantActor, OrganizationActor, UserActor)
- ✅ CQRS Level 3 with event sourcing (Pekko Persistence)
- ✅ Kafka integration for tenant events
- ✅ REST API with X-Tenant-ID headers
- ✅ Prometheus metrics + structured logging
- ✅ Provisioning workflow integration (delegates to Provisioning Service)

**Tier 2 Compliance** (75% - Standard):
- ✅ munit tests + BDD scenarios (.feature files)
- ✅ JWT + RBAC within tenant context
- ✅ Kubernetes Deployment + HPA
- ✅ Circuit breakers + exponential backoff
- ✅ Environment variables + ConfigMaps

**Tier 3 Compliance** (87.5% - Advanced):
- ✅ Entity-Tenant separation domain model
- ✅ PostgreSQL event store + read models
- ✅ Actor supervision hierarchies
- ✅ Deployment runbook documented

**Tier 4 Innovation** (100% - Service-Specific):
- Entity-to-Tenant promotion workflow (unique to Entity Management)
- Hierarchical organization models (domain-specific)
- Multi-level tenant administration (service-specific RBAC)

### Future CartService (Planned)

**Tier 1 Compliance** (50% - Essential):
- ✅ Multi-tenant seam architecture (cart_id includes tenant_id)
- ✅ Pekko actors (CartActor per tenant-cart)
- ✅ CQRS Level 2 (separate read/write models, no ES)
- ✅ Kafka integration for cart events (CartCheckedOut)
- ✅ REST API with X-Tenant-ID headers
- ✅ Observability with tenant-partitioned metrics
- ✅ Cart provisioning via Provisioning Service

**Tier 2 Compliance** (75% - Standard):
- ✅ munit tests + contract tests with OrderService
- ✅ JWT + tenant-scoped access control
- ✅ Kubernetes Deployment with HPA (scale on cart creation rate)
- ✅ Circuit breakers for inventory check
- ✅ Feature flags for A/B testing (seam level 3)

**Tier 3 Compliance** (87.5% - Advanced):
- ✅ Shopping cart aggregate with line items
- ✅ PostgreSQL read model + Redis caching (cart summaries)
- ✅ Actor passivation (10-minute idle timeout)
- ✅ Deployment runbook for peak traffic (Black Friday)

**Tier 4 Innovation** (100% - Service-Specific):
- Cart abandonment recovery workflows (CartService-specific)
- Price calculation engine (complex pricing rules)
- Cart merging (anonymous → authenticated transition)
- Promotional code application logic

## Validation

Success criteria:

- All services achieve Tier 1 compliance (100% of services)
- Most services achieve Tier 2 compliance (80%+ of production services)
- Entity Management Service demonstrates Tier 1-3 compliance (reference implementation)
- Developer onboarding time reduced by 50% after learning first service
- Operational runbooks 80% reusable across services

Metrics:
- Consistency compliance score tracked in REGISTRY.md
- Progressive familiarity index (average tier) increases over time
- Tier 1 exceptions remain below 2 per service
- New services reach Tier 1 within first sprint

## Related Policies

- [MULTI-TENANT-SEAM-ARCHITECTURE.md](./MULTI-TENANT-SEAM-ARCHITECTURE.md) - 4-level seam architecture (Tier 1)
- [PROVISIONING-SERVICE-PATTERN.md](./PROVISIONING-SERVICE-PATTERN.md) - DRY operational control surface (Tier 1)
- [API-DESIGN-STANDARDS.md](./API-DESIGN-STANDARDS.md) - REST API consistency (Tier 1)
- [EVENT-SCHEMA-STANDARDS.md](./EVENT-SCHEMA-STANDARDS.md) - Event integration patterns (Tier 1)

## Related Governance

- [ADR-0004: Scala 3 Technology Stack](../governance/ADRs/ADR-0004-scala3-technology-stack.md) - Language consistency
- [ADR-0005: Reactive Manifesto Alignment](../governance/ADRs/ADR-0005-reactive-manifesto-alignment.md) - Reactive patterns
- [ADR-0006: Agent-Based Service Patterns](../governance/ADRs/ADR-0006-agent-patterns.md) - Actor model consistency
- [ADR-0007: CQRS and Event-Driven Architecture](../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) - CQRS patterns
- [PDR-0005: Framework Selection Policy](../governance/PDRs/PDR-0005-framework-selection-policy.md) - Technology consistency
- [PDR-0006: Service Canvas Documentation Standard](../governance/PDRs/PDR-0006-service-canvas-standard.md) - Documentation consistency

## Notes

**Progressive Familiarity is Key Differentiator**:

TJMPaaS competitive advantage:
- Learn one service → understand all services
- Single operational model → reduced training costs
- Predictable integration → faster time-to-value
- Consistent quality → commercial credibility

**Balance Innovation and Consistency**:

- Tier 1 (Essential) - No exceptions without ADR
- Tier 2 (Standard) - Deviations allowed but discouraged
- Tier 3 (Advanced) - Templates provided, customization expected
- Tier 4 (Innovation) - Full creativity within framework

**Entity Management as Reference**:

Entity Management Service demonstrates all patterns:
- Other services can copy patterns wholesale
- Learning Entity Management = 87.5% understanding of any service
- Reference implementation accelerates development

**Enforcement Through Documentation**:

Every SERVICE-CANVAS.md includes:
```markdown
## Consistency Compliance

**Tier 1 (Essential)**: ✅ 100% compliant
- Multi-tenant seam architecture: Implemented
- Actor model: Pekko with OneForOne supervision
- CQRS: Level 2 implemented
- Event-driven: Kafka integration
- API: REST with X-Tenant-ID
- Observability: Prometheus + structured logs
- Provisioning: Delegates to Provisioning Service

**Tier 2 (Standard)**: ✅ 90% compliant
- Testing: munit + BDD scenarios
- Security: JWT + RBAC (deviation: custom claim structure)
- Deployment: Kubernetes + HPA
- Error handling: Circuit breakers + exponential backoff
- Configuration: Environment variables + ConfigMaps

**Tier 3 (Advanced)**: 🔄 70% compliant (work in progress)
- Domain model: Immutable value objects
- Read models: PostgreSQL (Elasticsearch planned for v2)
- Actor supervision: Implemented
- Runbooks: Deployment documented, troubleshooting in progress

**Tier 4 (Innovation)**: Service-specific
- [List domain-specific innovations]
```

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-28 | Initial policy establishing progressive familiarity framework | Tony Moores |
