# TJMPaaS Service Registry

This registry tracks all services in the TJMPaaS ecosystem.

## Purpose

- Central index of all TJMPaaS services
- Quick reference for service locations and status
- Links to service canvases and repositories
- Track service versions and lifecycle

## Services with Documentation

**Note**: These services have actual design documentation in this repository. They may not be implemented yet.

| Service | Repository | Canvas | Status | Version | Description |
|---------|-----------|--------|--------|---------|-------------|
| **Entity Management Service** | [Internal Design Docs](../services/entity-management/) | [SERVICE-CANVAS.md](../services/entity-management/SERVICE-CANVAS.md) | Design Complete | 0.1.0-design | Multi-tenant entity management: tenants, organizations, users, roles, permissions, audit trail. **Reference implementation demonstrating all 8 templates and standards.** |
| **Provisioning Service** | [Internal Design Docs](../services/provisioning-service/) | [SERVICE-CHARTER.md](../services/provisioning-service/SERVICE-CHARTER.md) | Vision Stub Only | - | Central provisioning and entitlement management (charter only, no detailed design) |

## Aspirational Service Examples

**Note**: These are **example service names** used in documentation to illustrate patterns. They do NOT have design docs or implementations. They represent potential future services for a digital commerce platform.

**Purpose**: Used in ADRs, best practices, and examples to demonstrate architectural patterns (e.g., "shopping cart actor" illustrates actor model, "order processing" illustrates CQRS).

| Example Service | Used to Illustrate | Found In |
|-----------------|-------------------|----------|
| CartService | Actor patterns, CQRS, event sourcing | ADRs, best practices examples |
| OrderService | Saga patterns, distributed transactions | Architecture examples |
| InventoryService | Eventual consistency, reservation patterns | CQRS examples |
| PaymentService | Saga patterns, compensation logic | Event-driven examples |
| NotificationService | Event consumers, async patterns | Integration examples |
| ProductCatalog | Read models, search optimization | CQRS examples |
| UserAuthService | JWT, permission resolution | Security examples |

**When These Become Real**: If/when these services are designed, they'll move to "Services with Documentation" section above.

## Future Service Ideas

**Note**: These are potential future services beyond illustrative examples. Not yet designed.

| Service | Priority | Target Phase | Description |
|---------|----------|--------------|-------------|
| PricingService | Medium | Phase 2 | Pricing rules and calculations |
| AnalyticsService | Low | Phase 3 | Business intelligence and reporting |

## Service Status Definitions

### Documentation Status
- **Design Complete**: Full design documentation exists (8 templates + features), ready for implementation
- **Vision Stub Only**: High-level charter only, no detailed design
- **Aspirational Example**: Service name used in examples only, no actual design

### Implementation Status (Future)
- **Development**: Actively being developed, not production-ready
- **Staging**: In staging environment, undergoing testing
- **Production**: Deployed to production, serving traffic
- **Maintenance**: Production but in maintenance mode (limited changes)
- **Deprecated**: Being phased out, not for new use
- **Archived**: No longer maintained or deployed

## Repository Naming Convention

All service repositories follow the pattern: `TJMSolns-<ServiceName>`

**Example**: `TJMSolns-CartService`

See [PDR-0004: Repository Organization Strategy](../governance/PDRs/PDR-0004-repository-organization.md) for details.

## Service Canvas Requirement

All services must maintain a `SERVICE-CANVAS.md` file in the repository root providing comprehensive service overview.

See [PDR-0006: Service Canvas Documentation Standard](../governance/PDRs/PDR-0006-service-canvas-standard.md) for requirements.

## Reference Implementation

**Entity Management Service** provides a complete reference implementation:
- **Location**: `doc/internal/services/entity-management/`
- **Core Documentation** (8 files): SERVICE-CHARTER.md, SERVICE-CANVAS.md, SERVICE-ARCHITECTURE.md, API-SPECIFICATION.md, DEPLOYMENT-RUNBOOK.md, TELEMETRY-SPECIFICATION.md, ACCEPTANCE-CRITERIA.md, SECURITY-REQUIREMENTS.md
- **Feature Documentation** (5 features, 10 files): Tenant Provisioning, Organization Hierarchy, User Management, Role-Based Permissions, Audit Trail (each with .feature + .md)
- **Total**: 18 comprehensive design documents demonstrating all templates and multi-tenant patterns
- **Multi-Tenant Patterns**: Demonstrates all 4 seam levels (Tenant, Tenant-Service, Tenant-Service-Feature, Tenant-Service-Role)
- **Architecture Patterns**: CQRS, Event Sourcing, Actor Model, REST APIs, CloudEvents

Use Entity Management Service as reference when designing new services.

See [PDR-0006: Service Canvas Documentation Standard](../governance/PDRs/PDR-0006-service-canvas-standard.md) for details.

**Template**: [SERVICE-CANVAS.md template](../templates/SERVICE-CANVAS.md)  
**Example**: [CartService Canvas Example](../examples/CartService-CANVAS-example.md)

## Adding a New Service

When creating a new service:

1. Create repository following `TJMSolns-<ServiceName>` naming convention
2. Copy SERVICE-CANVAS.md template from `doc/internal/templates/SERVICE-CANVAS.md`
3. Fill in canvas sections before/during service development
4. Add entry to this registry with link to repository and canvas
5. Update status as service progresses through lifecycle

## Service Categories

Services are organized by domain:

### Commerce
- **CartService**: Shopping cart management
- **OrderService**: Order processing
- **PricingService**: Pricing and discounts

### Inventory
- **InventoryService**: Stock management
- **ProductCatalog**: Product information

### User Management
- **UserAuthService**: Authentication and authorization
- **ProfileService**: User profiles and preferences

### Payment
- **PaymentGateway**: Payment processing
- **BillingService**: Invoice and billing

### Communication
- **NotificationService**: Multi-channel notifications
- **EmailService**: Email delivery

### Analytics
- **AnalyticsService**: Business intelligence
- **RecommendationService**: Product recommendations

### Infrastructure
- **APIGateway**: API routing and management
- **ConfigService**: Centralized configuration

## Governance

For project-wide governance, architecture decisions, and process standards, see:

- [Project Charter](../CHARTER.md)
- [Roadmap](../ROADMAP.md)
- [ADRs (Architectural Decision Records)](../governance/ADRs/)
- [PDRs (Process Decision Records)](../governance/PDRs/)
- [POLs (Policies)](../governance/POLs/)

## Framework Selection

Services choose frameworks per [PDR-0005: Framework Selection Policy](../governance/PDRs/PDR-0005-framework-selection-policy.md):

- Best-fit framework per service
- Maximum 3 frameworks per category across ALL TJMSolns projects
- Open-source only (Apache 2.0, MIT, BSD, EPL)
- Documented in service canvas

## Technology Stack

All services built with:
- **Language**: Scala 3.3+
- **Build Tool**: Mill
- **JVM**: OpenJDK 17 or 21 LTS
- **Containerization**: Docker/OCI
- **Orchestration**: Kubernetes (GKE)

See [ADR-0004: Scala 3 Technology Stack](../governance/ADRs/ADR-0004-scala3-technology-stack.md) for details.

## Contact

- **Owner**: Tony Moores (TJM Solutions LLC)
- **Email**: tmoores@tjm.solutions
- **GitHub**: tmoores-retisio
