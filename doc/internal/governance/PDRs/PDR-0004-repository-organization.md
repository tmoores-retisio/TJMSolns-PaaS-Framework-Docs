# PDR-0004: Repository Organization Strategy

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Technical Story**: Phase 0 - Foundation

## Context

TJMPaaS aims to build a library of services that can be deployed independently, versioned separately, and potentially commercialized individually. The repository structure significantly impacts development workflow, deployment processes, and commercialization options.

### Problem Statement

Determine how to organize code repositories for TJMPaaS services to support:
- Independent service development and versioning
- Clear service boundaries
- Independent deployment and release cycles
- Potential service commercialization
- Governance and documentation centralization
- Manageable complexity for solo developer initially

### Goals

- Service isolation and independence
- Clear repository ownership
- Flexible commercialization options
- Centralized governance and documentation
- Scalable as services and team grow
- Simple initial setup for solo developer

### Constraints

- Solo developer initially (Tony Moores)
- GitHub as platform
- TJMSolns organization
- Services may have different licenses/commercialization models
- Some services may be open-source, others proprietary

## Decision

**Adopt a multi-repository strategy** with:

1. **One repository per service**: `TJMSolns-<ServiceName>`
2. **Central governance repository**: Current repo (TJMPaaS) for documentation, ADRs, PDRs, POLs
3. **Clear naming convention**: `TJMSolns-<ServiceName>` pattern
4. **Independent versioning**: Each service manages its own version
5. **Service autonomy**: Each service is a complete, buildable project

## Rationale

### Multi-Repo vs Monorepo

**Why Multi-Repo**:

1. **Service Isolation**: Each service truly independent
2. **Versioning**: Clear version per service
3. **Release Cycles**: Deploy services independently
4. **Access Control**: Granular repo-level permissions
5. **Commercialization**: Easy to license services differently
6. **Size**: Repos stay small and focused
7. **CI/CD**: Build/test only what changed
8. **Clarity**: Clear boundaries, no confusion about what belongs where

**Monorepo Drawbacks** (for TJMPaaS):
- Tight coupling temptation
- Single version for all
- Deployment coordination required
- Harder to separate for commercialization
- Repo size grows unbounded
- All-or-nothing access control

### Why TJMSolns-<ServiceName> Naming?

**Pattern**: `TJMSolns-<ServiceName>`

**Examples**:
- `TJMSolns-CartService`
- `TJMSolns-OrderService`
- `TJMSolns-PaymentGateway`
- `TJMSolns-InventoryService`
- `TJMSolns-UserAuthService`

**Benefits**:
- **Clear Ownership**: "TJMSolns" prefix shows organization
- **Namespace**: Avoids name collisions on GitHub
- **Consistency**: Same pattern for all services
- **Professionalism**: Business-oriented naming
- **Discovery**: Easy to find all services (search "TJMSolns-")
- **Branding**: Reinforces TJM Solutions brand

### Central Governance Repository

**Repository**: `TJMPaaS` (current repo)

**Purpose**:
- Project-wide documentation
- ADRs, PDRs, POLs
- Architecture documentation
- Roadmap and charter
- Conversation audit trail
- Cross-service standards

**Not In This Repo**:
- Service implementation code
- Service-specific documentation (goes in service repos)
- Service build configuration
- Service tests

**Benefits**:
- Single source of truth for governance
- Easy to find project-wide decisions
- Doesn't clutter service repos
- Clear separation: governance vs implementation

### Service Repository Structure

Each service repo should contain:

```
TJMSolns-<ServiceName>/
├── README.md                    # Service overview and entry point
├── SERVICE-CANVAS.md            # Comprehensive service overview (PDR-0006)
├── build.sc                     # Mill build definition
├── .github/
│   └── workflows/               # CI/CD for this service
├── src/
│   ├── main/scala/              # Service implementation
│   └── test/scala/              # Service tests
├── docs/                        # Service-specific detailed docs
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── DEPLOYMENT.md
│   ├── CONFIGURATION.md
│   └── runbooks/                # Operational runbooks
├── docker/
│   └── Dockerfile               # Service container
├── k8s/                         # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── LICENSE                      # Service-specific license
└── VERSION                      # Semantic version
```

### Service Canvas

Per [PDR-0006: Service Canvas Documentation Standard](./PDR-0006-service-canvas-standard.md), every service must include `SERVICE-CANVAS.md` at the repository root.

**Purpose**: Single-page comprehensive service overview for quick reference

**Content**:
- Service identity (mission, tech stack, governance)
- Dependencies (services, external, frameworks)
- Architecture (actor/agent model, message protocols)
- API Contract (CQRS: commands, queries, events)
- Non-Functional Requirements (reactive alignment, SLOs, resources)
- Observability (health checks, metrics, logging, tracing)
- Operations (deployment, runbooks, maintenance)
- Documentation links (detailed docs, governance)
- Release history, security, testing, disaster recovery

**Template**: Available at `doc/internal/templates/SERVICE-CANVAS.md` in TJMPaaS governance repo

**Example**: See `doc/internal/technical/examples/CartService-CANVAS-example.md` for reference implementation

**Documentation Hierarchy**:
```
README.md              → Entry point, quick start, local development
   ↓
SERVICE-CANVAS.md     → Comprehensive overview, quick reference
   ↓
docs/                  → Detailed documentation
  ├── ARCHITECTURE.md  → Detailed design and patterns
  ├── API.md           → Detailed API specifications
  ├── DEPLOYMENT.md    → Deployment procedures
  └── runbooks/        → Operational procedures
```

### Cross-Service Dependencies

**Problem**: Services may share code (data models, utilities)

**Solutions**:

1. **Shared Libraries**: Publish as artifacts
   - `TJMSolns-Commons` repo for shared code
   - Publish to Maven/private registry
   - Services depend on published versions

2. **Service-to-Service**: Through APIs only
   - No direct code dependencies
   - REST/gRPC APIs
   - Message passing

3. **Duplication**: Sometimes duplication is fine
   - Small utilities can be duplicated
   - Avoids coupling
   - Services remain independent

**Approach**: Start with option 3 (duplication), introduce shared library only when truly needed

## Alternatives Considered

### Alternative 1: Monorepo (All Services in One Repo)

**Description**: Single repository containing all services

**Pros**:
- Easy to find everything
- Atomic cross-service changes
- Shared tooling setup
- Single CI/CD config

**Cons**:
- Tight coupling temptation
- Unified versioning problematic
- Deployment coordination needed
- Harder to commercialize separately
- Repo size grows unbounded
- All-or-nothing permissions

**Reason for rejection**: Independence and commercialization flexibility more important than monorepo convenience

### Alternative 2: Service Folders in TJMPaaS Repo

**Description**: Keep services as folders in current repo

**Pros**:
- Simple initially
- No repo proliferation

**Cons**:
- Not truly independent
- Hard to separate later
- Difficult to commercialize
- Version management unclear
- Repo gets large

**Reason for rejection**: Creates future problems; better to start right

### Alternative 3: Generic Naming (e.g., "cart-service")

**Description**: Simple lowercase service names without prefix

**Pros**:
- Shorter names
- Less typing

**Cons**:
- Name collision risk
- No clear ownership
- Doesn't reinforce brand
- Harder to discover related services

**Reason for rejection**: TJMSolns prefix provides professionalism and clarity

### Alternative 4: No Governance Repo (Governance in Each Service)

**Description**: Each service repo contains its own ADRs/PDRs

**Pros**:
- Self-contained services
- No extra repo needed

**Cons**:
- Duplicate governance documents
- Inconsistent documentation
- Hard to find project-wide decisions
- No single source of truth

**Reason for rejection**: Governance and project-wide documentation need central home

### Alternative 5: Polyrepo with Different Naming

**Description**: Multiple repos but different naming convention

**Pros**:
- Service independence maintained

**Cons**:
- Less consistency if naming is ad-hoc
- Discovery harder without pattern

**Reason for rejection**: TJMSolns-<ServiceName> pattern provides needed consistency

## Consequences

### Positive

- **Service Autonomy**: Each service truly independent
- **Versioning Clarity**: Clear version per service
- **Release Flexibility**: Deploy services on own schedule
- **Commercialization**: Easy to license differently
- **Access Control**: Granular repo permissions
- **Size Management**: Repos stay focused and small
- **CI/CD Efficiency**: Build only what changed
- **Team Scaling**: Teams can own services
- **Clarity**: Clear boundaries and ownership

### Negative

- **Repository Count**: More repos to manage
- **Cross-Cutting Changes**: Need to update multiple repos
- **Shared Code Complexity**: Need library publishing strategy
- **Initial Setup**: More repos to create initially
- **Consistency**: Requires discipline for standards

### Neutral

- **Discoverability**: Need to search "TJMSolns-" to find all
- **Tooling**: Need scripts to operate across repos if needed

## Implementation

### Initial Setup

**Phase 0-1**: Create repositories as services are developed
- First service: Create first service repo
- Governance: Keep using TJMPaaS repo
- Templates: Create service template repo for consistency

**Repository Creation Checklist**:
- [ ] Name follows TJMSolns-<ServiceName> pattern
- [ ] README.md with service overview
- [ ] SERVICE-CANVAS.md from template (PDR-0006)
- [ ] Mill build configuration (build.sc)
- [ ] LICENSE file
- [ ] VERSION file
- [ ] Dockerfile
- [ ] GitHub Actions workflows
- [ ] docs/ directory structure (ARCHITECTURE.md, API.md, DEPLOYMENT.md, runbooks/)
- [ ] .gitignore appropriate for Scala
- [ ] Reference to TJMPaaS governance repo in README

### Service Template Repository

Create `TJMSolns-ServiceTemplate` with:
- Standard structure
- Mill build setup
- CI/CD workflows
- Documentation templates
- Docker configuration
- Kubernetes manifests

Use GitHub template feature to create new services.

### Governance Repository Management

**TJMPaaS repo (current)** maintains:
- `doc/internal/governance/` - ADRs, PDRs, POLs
- `doc/internal/CHARTER.md`
- `doc/internal/ROADMAP.md`
- `doc/internal/architecture/` - Cross-service architecture
- `doc/internal/technical/services/` - Service registry and index
- `doc/internal/compliance/audit/` - Conversation logs

**Service index**: Maintain `doc/internal/technical/services/REGISTRY.md`:

```markdown
# Service Registry

## Active Services

| Service | Repository | Status | Version | Description |
|---------|-----------|--------|---------|-------------|
| CartService | [TJMSolns-CartService](https://github.com/TJMSolns/TJMSolns-CartService) | Development | 0.1.0 | Shopping cart management |
| OrderService | [TJMSolns-OrderService](https://github.com/TJMSolns/TJMSolns-OrderService) | Planned | - | Order processing |
```

### Cross-Service Documentation

**Architecture docs** in TJMPaaS repo cover:
- Service interaction patterns
- API design standards
- Message formats
- Authentication/authorization flows

**Service-specific docs** in service repos cover:
- Service implementation details
- API specifications
- Deployment procedures
- Configuration options

### Versioning Strategy

**Service Versions**:
- Semantic versioning (MAJOR.MINOR.PATCH)
- VERSION file in repo root
- Git tags for releases (v1.2.3)
- Independent versions per service

**Governance Version**:
- TJMPaaS repo doesn't have traditional version
- ADRs/PDRs/POLs versioned by date and number
- Roadmap tracks overall project phases

### Dependency Management

**Published Libraries** (when needed):
- Create TJMSolns-Commons repo
- Publish to Maven Central or private registry
- Services depend on published versions
- Clear versioning and changelog

**Initial Approach**:
- Start without shared libraries
- Duplicate small utilities
- Introduce shared library only when clear benefit

### CI/CD Strategy

**Service Repos**:
- GitHub Actions per service
- Build, test, containerize
- Deploy to appropriate environment
- Independent pipelines

**Governance Repo**:
- Markdown linting
- Link validation
- Documentation generation

### Team Growth

**Current** (solo):
- All repos owned by Tony
- Full access to all

**Future** (team):
- Team members can own services
- Repo-level permissions
- Governance repo accessible to all
- Service repos can be private/public as appropriate

### Commercial Considerations

**Flexible Licensing**:
- Governance repo: Internal only
- Service repos: Choose per service
  - Open source (Apache 2.0, MIT)
  - Proprietary (commercial license)
  - Dual licensing

**Service Distribution**:
- Container images can be public/private
- Source can be public/private
- Clear separation enables commercial options

## Validation

Success criteria:

- Services can be versioned independently
- Services can be deployed independently
- Services can be built without other service code
- Governance documentation centralized and clear
- New services easy to create (template works)
- Cross-service changes manageable
- Repository naming consistent

Metrics:
- Time to create new service (< 30 minutes using template)
- Build time per service (< 5 minutes)
- Independence verified (services build in isolation)
- Documentation findability (governance docs easy to locate)

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Too many repos to manage | Low | Start small; use automation; service template; only create when needed |
| Inconsistency across services | Medium | Service template; documented standards; code reviews; automation |
| Shared code duplication | Low | Acceptable initially; introduce shared library only when clearly beneficial |
| Cross-cutting changes difficult | Medium | Good automation; scripts to update multiple repos; clear communication |
| Governance repo gets ignored | Low | Reference from service READMEs; make discoverable; maintain actively |
| Naming confusion | Low | Clear convention; document in governance; enforce in reviews |

## Related Decisions

- [ADR-0002: Documentation-First Approach](./ADR-0002-documentation-first-approach.md) - Governance documentation centralized
- [PDR-0001: Documentation Standards](./PDR-0001-documentation-standards.md) - How docs are structured
- [PDR-0006: Service Canvas Documentation Standard](./PDR-0006-service-canvas-standard.md) - Canvas as mandatory service documentation
- [ADR-0003: Containerization Strategy](./ADR-0003-containerization-strategy.md) - Each service containerized independently
- Future ADR: Shared library strategy (when needed)
- Future PDR: CI/CD pipeline standards

## Related Features

**Features That Validate This Decision**:

*To be documented in Phase 1 (Governance Inference Analysis)*

Expected features:
- All service features should be self-contained within service repositories
- Features should not have hard code dependencies across services (only API/message integration)
- Multi-repo structure enables independent feature deployment

**Inference Tracking**: See [GOVERNANCE-FEATURE-INFERENCE-MAP.md](../../GOVERNANCE-FEATURE-INFERENCE-MAP.md#pdr-0004-repository-organization-strategy)

## References

- [Microservices - Martin Fowler](https://martinfowler.com/articles/microservices.html)
- [Monorepo vs Polyrepo](https://github.com/joelparkerhenderson/monorepo-vs-polyrepo)
- [GitHub Repository Structure Best Practices](https://docs.github.com/en/repositories)
- [Semantic Versioning](https://semver.org/)

## Notes

**Why This Matters**:

Repository structure is hard to change later. Starting with multi-repo:
- Enables commercialization flexibility
- Supports independent service lifecycles
- Scales as services and team grow
- Maintains clear boundaries

**Governance as Hub**:

The TJMPaaS repository becomes the **hub** for:
- Project vision and roadmap
- Architectural decisions
- Process standards
- Service registry
- Historical record

Service repositories are **spokes** that reference the hub for project-wide context.

**Starting Small**:

As solo developer:
- Don't create repos until services exist
- Use template to speed creation
- Governance repo already established
- First service will validate the approach

**Evolution Path**:

1. **Phase 0-1**: First 2-3 services, validate structure
2. **Phase 2**: Service template refined, more services
3. **Phase 3**: Shared library if needed, automation
4. **Phase 4-5**: Team growth, distributed ownership

**Example Service README Reference**:

Every service README should link to governance:

```markdown
# TJMSolns-CartService

## Project Governance

This service is part of the TJMPaaS project. For architectural decisions, 
process standards, and project governance, see the 
[TJMPaaS repository](https://github.com/TJMSolns/TJMPaaS).

- [Project Charter](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/CHARTER.md)
- [Architecture Decisions](https://github.com/TJMSolns/TJMPaaS/tree/main/doc/internal/governance/ADRs)
- [Service Registry](https://github.com/TJMSolns/TJMPaaS/blob/main/doc/internal/technical/services/REGISTRY.md)
```

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
