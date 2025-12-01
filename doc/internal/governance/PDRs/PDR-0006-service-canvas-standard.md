# PDR-0006: Service Canvas Documentation Standard

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Technical Story**: Phase 0 - Foundation

## Context

TJMPaaS adopts a multi-repository strategy (PDR-0004) where each service is independently developed, versioned, and deployed. Services implement sophisticated patterns including CQRS (ADR-0007), event-driven architecture (ADR-0005), and agent-based concurrency (ADR-0006). This complexity requires comprehensive yet accessible service documentation.

### Problem Statement

Establish a documentation standard that:
- Provides single-page comprehensive service overview
- Forces complete thinking about service design upfront
- Documents API contracts, dependencies, and NFRs as first-class concerns
- Supports quick reference for operations and troubleshooting
- Integrates with project governance (ADRs, PDRs)
- Remains maintainable by solo developer initially
- Scales to team collaboration

### Goals

- One comprehensive document per service for quick reference
- Mandatory documentation of key architectural decisions
- Clear API contracts (commands, queries, events)
- Explicit non-functional requirements and SLOs
- Operational runbooks and troubleshooting guides
- Integration with TJMPaaS governance

### Constraints

- Multi-repository structure (each service in own repo)
- Solo developer initially (documentation must be practical)
- Services may have different tech stacks (within policy bounds)
- Must complement, not replace, detailed documentation

## Decision

**Adopt the Service Canvas as mandatory documentation standard** for all TJMPaaS services.

Each service must maintain a `SERVICE-CANVAS.md` file in the repository root that provides:
1. **Single-page comprehensive overview** of the service
2. **Structured sections** covering identity, dependencies, architecture, API contracts, NFRs, observability, operations, and more
3. **Quick reference** for developers, operators, and stakeholders
4. **Governance integration** with links to relevant ADRs and PDRs
5. **Living document** updated with significant service changes

## Rationale

### Why "Canvas"?

The term "canvas" (inspired by Business Model Canvas, Lean Canvas) emphasizes:
- **Single-page overview**: Everything important on one page
- **Structured thinking**: Forces consideration of all aspects
- **Visual organization**: Markdown tables for scanability
- **Collaborative tool**: Foundation for design discussions
- **Living document**: Evolves with service

### Benefits for TJMPaaS

**Design Forcing Function**:
- Must think through dependencies before coding
- Must define API contracts explicitly
- Must establish SLOs upfront
- Must consider operations and observability

**Multi-Repo Support**:
- Each service is self-documenting
- Canvas travels with service code
- No dependency on central documentation
- Easy to find (root of repo)

**CQRS/Event-Driven Alignment**:
- Explicit sections for Commands, Queries, Events
- Documents message protocols
- Captures expected usage and thresholds
- Maps to ADR-0007 patterns

**Actor Model Integration**:
- Documents agents/actors and their purposes
- Captures message protocols
- Shows supervision strategies
- Maps to ADR-0006 patterns

**Framework Selection Transparency**:
- Documents framework choices per service
- References PDR-0005 policy
- Justifies selections
- Aids future framework decisions

**Operational Excellence**:
- Health check endpoints documented
- Metrics and alerts defined
- Runbooks linked
- Disaster recovery plans explicit

**Quick Reference**:
- New team members understand service quickly
- On-call engineers find runbooks fast
- API consumers see contracts clearly
- Operations team knows SLOs

### Canvas vs. Other Documentation

**Canvas is NOT a replacement for**:
- **README.md**: Still the entry point; canvas complements it
- **Detailed API docs**: Canvas shows contracts, detailed docs show implementation
- **Architecture documents**: Canvas summarizes, architecture docs detail
- **Code comments**: Canvas is high-level, code is implementation

**Canvas IS**:
- Comprehensive single-page overview
- Quick reference for key information
- Design forcing function
- Living document updated with service

**Relationship**:
```
README.md (entry point, quick start)
   ↓
SERVICE-CANVAS.md (comprehensive overview, quick reference)
   ↓
docs/ARCHITECTURE.md (detailed design)
docs/API.md (detailed API specification)
docs/DEPLOYMENT.md (detailed deployment procedures)
docs/runbooks/ (detailed operational procedures)
```

## Alternatives Considered

### Alternative 1: README-Only Documentation

**Description**: Use only README.md for service documentation

**Pros**:
- Familiar pattern
- One less file
- Simpler structure

**Cons**:
- README becomes too long
- Hard to find specific information
- Doesn't force comprehensive thinking
- No standard structure

**Reason for rejection**: README should be entry point, not comprehensive reference; canvas provides structure README lacks

### Alternative 2: Wiki or External Documentation

**Description**: Maintain service documentation in GitHub Wiki or external system

**Pros**:
- More formatting options
- Easier to organize large docs
- Separate from code

**Cons**:
- Not in version control with code
- Can drift from reality
- Requires separate tool
- Doesn't travel with service

**Reason for rejection**: Documentation must be version-controlled with code; wiki/external systems add complexity

### Alternative 3: Multiple Separate Documents

**Description**: Break canvas into separate files (DEPENDENCIES.md, API.md, NFRs.md, etc.)

**Pros**:
- Smaller files
- Can be edited independently
- More granular ownership

**Cons**:
- Lose single-page overview benefit
- Harder to get complete picture
- More files to maintain
- No quick reference

**Reason for rejection**: Single-page overview is key value proposition; detailed docs can be separate

### Alternative 4: No Standard Structure

**Description**: Each service documents itself however it prefers

**Pros**:
- Maximum flexibility
- No constraints

**Cons**:
- Inconsistent across services
- Knowledge doesn't transfer
- Unclear what to document
- No standardization

**Reason for rejection**: Need consistency for maintainability and knowledge transfer

### Alternative 5: Heavy ADR Documentation

**Description**: Document every service decision in ADRs

**Pros**:
- Excellent decision history
- Rationale preserved

**Cons**:
- ADR overhead for every decision
- No quick reference
- Harder to find information
- Too heavyweight for service-level decisions

**Reason for rejection**: ADRs for project-wide decisions; canvas for service-specific information

## Consequences

### Positive

- **Complete Thinking**: Canvas forces consideration of all aspects
- **Quick Reference**: Single page for key information
- **Consistency**: Standard structure across all services
- **Governance Integration**: Links to ADRs, PDRs, POLs
- **API Contracts**: Explicit commands, queries, events
- **NFRs First-Class**: SLOs, resource limits, scaling documented
- **Operational Excellence**: Runbooks, health checks, metrics defined
- **Onboarding**: New team members understand services quickly
- **Multi-Repo Friendly**: Canvas travels with service
- **Maintenance**: Clear what to update when service changes

### Negative

- **Initial Overhead**: Must create canvas before/during service development
- **Maintenance Burden**: Must keep canvas current
- **Template Learning Curve**: Must understand canvas structure
- **Duplication**: Some info may appear in canvas and other docs

### Neutral

- **File Count**: One more file per service (but valuable)
- **Template Evolution**: Canvas template may evolve over time

## Implementation

### Requirements

**Location**: `SERVICE-CANVAS.md` in root of each service repository

**Template**: `doc/internal/governance/templates/SERVICE-CANVAS.md` in TJMPaaS governance repo

**Note**: As of 2025-11-26, template moved to `doc/internal/governance/templates/SERVICE-CANVAS.md` per co-location strategy (PDR-0007).

**Sections** (from template):
1. Service Identity (mission, value prop, tech stack, governance refs)
2. Dependencies (services, external, frameworks)
3. Architecture (agents/actors, message protocols)
4. API Contract (CQRS: commands, queries, events)
5. Non-Functional Requirements (reactive alignment, SLOs, resources)
6. Observability (health checks, metrics, logging, tracing)
7. Operations (deployment, env vars, secrets, runbooks)
8. Documentation (service docs, governance refs)
9. Release History
10. Security (auth, data protection, scanning, compliance)
11. Testing (coverage, types, frameworks)
12. Disaster Recovery (backup, RTO/RPO, failure scenarios)
13. Future Considerations
14. Canvas Changelog

**Format**: Markdown with tables for scanability

**Versioning**: Single canvas file, Git history provides versioning (no version in filename)

**Update Frequency**:
- **Major changes**: When architecture, API, or dependencies change
- **API changes**: When commands, queries, or events added/modified
- **New dependencies**: When service or external dependencies added
- **SLO changes**: When targets or resource limits change
- **Quarterly reviews**: Review and update as needed

### Creation Process

**When to Create**: Before implementing new service (design forcing function)

**How to Create**:
1. Copy template from `doc/internal/governance/templates/SERVICE-CANVAS.md`
2. Save as `SERVICE-CANVAS.md` in service repo root
3. Fill in sections systematically
4. Review with stakeholders (self-review initially)
5. Commit with initial service code
6. Link from README.md

### Integration with Development Workflow

**Design Phase**:
- Create canvas skeleton
- Define API contracts (commands, queries, events)
- Document dependencies
- Establish SLOs

**Implementation Phase**:
- Update canvas as design evolves
- Add runbooks as operational patterns emerge
- Document actual metrics and health checks

**Review Phase**:
- Canvas part of code review
- Verify canvas matches implementation
- Check governance links valid

**Maintenance Phase**:
- Update canvas with API changes
- Revise SLOs based on production data
- Add runbooks for new scenarios
- Quarterly review and refresh

### Service Repository Checklist

From PDR-0004, updated to include canvas:

```
TJMSolns-<ServiceName>/
├── README.md                    # Service entry point
├── SERVICE-CANVAS.md            # ← Comprehensive overview (NEW)
├── build.sc                     # Mill build definition
├── .github/
│   └── workflows/               # CI/CD for this service
├── src/
│   ├── main/scala/              # Service implementation
│   └── test/scala/              # Service tests
├── docs/                        # Detailed documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── DEPLOYMENT.md
│   ├── CONFIGURATION.md
│   └── runbooks/
├── docker/
│   └── Dockerfile               # Service container
├── k8s/                         # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── LICENSE                      # Service-specific license
└── VERSION                      # Semantic version
```

### README.md Integration

README should reference canvas:

```markdown
# TJMSolns-ServiceName

[Brief description]

## Quick Links

- **[Service Canvas](./SERVICE-CANVAS.md)** - Comprehensive service overview
- [Architecture](./docs/ARCHITECTURE.md) - Detailed design
- [API Documentation](./docs/API.md) - API reference
- [Deployment Guide](./docs/DEPLOYMENT.md) - How to deploy

## Project Governance

This service is part of TJMPaaS. See [TJMPaaS repository](https://github.com/TJMSolns/TJMPaaS) for governance.
```

### Service Registry Integration

Update `doc/internal/services/REGISTRY.md` to include canvas column:

```markdown
## Active Services

| Service | Repository | Canvas | Status | Version | Description |
|---------|-----------|--------|--------|---------|-------------|
| CartService | [Repo](link) | [Canvas](canvas-link) | Development | 0.1.0 | Shopping cart |
```

## Validation

Success criteria:

- Every service has `SERVICE-CANVAS.md` in repo root
- Canvas follows template structure
- Canvas updated with significant changes
- Canvas links to relevant governance docs
- API contracts explicitly documented
- NFRs and SLOs defined
- Runbooks documented
- New team members can understand service from canvas

Metrics:
- Canvas creation time (< 2 hours for initial version)
- Canvas usefulness (subjective: do people reference it?)
- Canvas freshness (updated within 30 days of major changes)
- Onboarding time reduced (new team members productive faster)

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Canvas becomes stale | Medium | Quarterly reviews; link from README; part of code review |
| Too much overhead | Medium | Template makes it easier; valuable enough to justify effort |
| Duplication with other docs | Low | Canvas is overview, other docs are details; complementary |
| Template too prescriptive | Low | Template is guide, adapt as needed; will evolve |
| Not used in practice | Medium | Make valuable by linking from README; reference in onboarding |

## Related Decisions

- [PDR-0004: Repository Organization Strategy](./PDR-0004-repository-organization.md) - Canvas fits multi-repo structure
- [ADR-0007: CQRS and Event-Driven Architecture](../ADRs/ADR-0007-cqrs-event-driven-architecture.md) - Canvas documents CQRS patterns
- [ADR-0006: Agent-Based Service Patterns](../ADRs/ADR-0006-agent-patterns.md) - Canvas documents actor model
- [ADR-0005: Reactive Manifesto Alignment](../ADRs/ADR-0005-reactive-manifesto-alignment.md) - Canvas documents reactive principles
- [PDR-0005: Framework Selection Policy](./PDR-0005-framework-selection-policy.md) - Canvas documents framework choices
- Future PDR: Code review standards (include canvas review)

## Related Features

**Features That Validate This Decision**:

**Entity Management Service** demonstrates complete service canvas usage:

**Canvas Location**: [services/entity-management/SERVICE-CANVAS.md](../../services/entity-management/SERVICE-CANVAS.md)

**Canvas Sections Demonstrated**:
1. **Service Identity**: Mission, value proposition, tech stack (Scala 3, Pekko actors, ZIO effects)
2. **Dependencies**: PostgreSQL, Kafka, Redis, Authentication Service
3. **Architecture**: Actor-based design with TenantActor, OrganizationActor, UserActor, RoleActor, AuditLogger
4. **API Contract**:
   - Commands: CreateTenant, CreateOrganization, CreateUser, CreateRole (12+ total)
   - Queries: ListOrganizations, ListUsers, GetPermissions (8+ total)
   - Events: TenantProvisioned, UserCreated, RolePermissionsUpdated (15+ total)
5. **Non-Functional Requirements**: 
   - Responsive: <100ms P95 for queries, <200ms P95 for commands
   - Resilient: Actor supervision, circuit breakers
   - Elastic: Horizontal scaling to 10K+ tenants
   - Message-Driven: Kafka integration, async boundaries
6. **Observability**: Health checks (/health, /ready), 20+ Prometheus metrics, structured logging, distributed tracing
7. **Operations**: Docker deployment, Kubernetes manifests, runbooks for common scenarios
8. **Security**: JWT authentication, X-Tenant-ID validation, RBAC enforcement, audit logging
9. **Features Section**: Lists all 5 features with status 🟢 (design complete)

**Related Documentation**:
- [Entity Management Features](../../services/entity-management/features/) - 5 features with BDD scenarios
- [Entity Management Architecture](../../services/entity-management/SERVICE-ARCHITECTURE.md) - Detailed technical design
- [Entity Management API Spec](../../services/entity-management/API-SPECIFICATION.md) - OpenAPI specification

**Template Validation**: Entity Management Service proves SERVICE-CANVAS.md template is comprehensive and practical for complex multi-tenant services. Canvas provides quick reference while detailed docs provide depth.

## References

- [Business Model Canvas](https://www.strategyzer.com/canvas/business-model-canvas)
- [Lean Canvas](https://leanstack.com/lean-canvas)
- [Microservice Canvas](https://github.com/ddd-crew/microservice-canvas) - Inspiration
- [C4 Model](https://c4model.com/) - Complementary architecture documentation

## Notes

**Canvas Philosophy**:

The canvas is inspired by Business Model Canvas and Lean Canvas:
- **Single page**: Forces prioritization and clarity
- **Structured**: Consistent sections guide thinking
- **Visual**: Tables and formatting aid scanning
- **Collaborative**: Foundation for discussions
- **Iterative**: Starts simple, evolves with service

**Adapted for TJMPaaS**:

TJMPaaS canvas emphasizes:
- **CQRS patterns**: Commands, Queries, Events as first-class sections
- **Actor model**: Agents/actors and message protocols
- **Reactive principles**: NFRs aligned with ADR-0005
- **Framework transparency**: Choices documented per PDR-0005
- **Governance integration**: Links to ADRs, PDRs, POLs
- **Operational excellence**: Runbooks, metrics, health checks

**Solo Developer Practicality**:

For solo developer (initially):
- Template reduces effort
- Canvas helps think through design
- Quick reference when context switching
- Documents decisions for future self
- Prepares for team growth

**Team Scaling**:

As team grows:
- Canvas is onboarding tool
- Common structure aids communication
- Review canvas in code reviews
- Canvas is design discussion artifact

**Canvas vs. ADRs/PDRs**:

Clear distinction:
- **ADRs**: Project-wide architectural decisions (in TJMPaaS governance repo)
- **PDRs**: Project-wide process decisions (in TJMPaaS governance repo)
- **Canvas**: Service-specific comprehensive overview (in service repo)

Canvas references ADRs/PDRs where applicable (e.g., "Per ADR-0006, we use Pekko for actors").

**Versioning Strategy**:

Single canvas file, no version in filename:
- **Why**: Git history provides versioning
- **How**: Commit canvas changes with code changes
- **Benefit**: Always current, no stale old versions
- **Changelog section**: Track major canvas updates

**Example Workflow**:

1. Starting new service: Copy template, fill in design
2. Development: Update canvas as design evolves
3. Code review: Review canvas along with code
4. Production: Canvas reflects reality
5. Maintenance: Update canvas with changes
6. Quarterly: Review and refresh canvas

**Future Evolution**:

Canvas template will evolve:
- Add sections as patterns emerge
- Remove sections if not valuable
- Refine structure based on usage
- Incorporate feedback from team

Changes to template documented in template changelog, existing canvases updated as needed.

**Template Location Strategy**:

Service canvas template is in `doc/internal/governance/templates/` (not co-located with service canvases) because:
- Service canvases live in service repositories (not governance repo)
- Template is copied to service repos, not referenced in place
- Cross-cutting template appropriate in governance/templates/
- See [PDR-0007: Documentation Asset Management](./PDR-0007-documentation-asset-management.md) for template co-location strategy

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
