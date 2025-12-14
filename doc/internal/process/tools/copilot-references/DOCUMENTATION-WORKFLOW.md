# TJMPaaS Documentation Workflow

**Purpose**: When to create ADR, PDR, POL, or other documentation

**Last Updated**: 2025-11-26

---

## Quick Reference

| Document Type | When to Create | Template Location | Examples |
|---------------|---------------|-------------------|----------|
| **ADR** | Major technical/architecture decision | `doc/internal/governance/ADRs/ADR-TEMPLATE.md` | Tech stack, CQRS, actors, containerization |
| **PDR** | Workflow/process change | `doc/internal/governance/PDRs/PDR-TEMPLATE.md` | Repository organization, framework selection, documentation standards |
| **POL** | Rules, standards, compliance | `doc/internal/governance/POLs/POL-TEMPLATE.md` | Security policies, data handling, compliance requirements |
| **Session Summary** | Significant work session | `doc/internal/audit/SESSION-SUMMARY-TEMPLATE.md` | Major conversations, decisions, milestones |
| **Service Canvas** | New service | `doc/internal/governance/templates/SERVICE-CANVAS.md` | CartService, OrderService |
| **Best Practice** | Research/evidence | `doc/internal/best-practices/BEST-PRACTICE-TEMPLATE.md` | Scala 3 research, CQRS patterns, actor frameworks |

---

## ADR: Architectural Decision Record

### When to Create

✅ **Create ADR for**:
- Technology selection (Scala 3, Mill, Pekko, ZIO)
- Architectural patterns (CQRS, event sourcing, reactive)
- Major design decisions affecting multiple services
- Infrastructure choices (Kubernetes, GCP, containerization)
- Significant technical trade-offs

❌ **Don't create ADR for**:
- Service-specific implementation details (use Service Canvas)
- Process/workflow changes (use PDR)
- Temporary experiments (use working docs)
- Minor library choices (document in service README)

### Template Location

```
doc/internal/governance/ADRs/ADR-TEMPLATE.md
```

Co-located with ADRs for Copilot discoverability.

### Naming Convention

```
ADR-NNNN-short-title.md
```

Examples:
- `ADR-0004-scala3-technology-stack.md`
- `ADR-0005-reactive-manifesto-alignment.md`
- `ADR-0006-agent-patterns.md`
- `ADR-0007-cqrs-event-driven-architecture.md`

### Process

1. **Draft**:
   ```bash
   cd doc/internal/governance/ADRs
   cp ADR-TEMPLATE.md ADR-NNNN-short-title.md
   # Edit file, fill in sections
   ```

2. **Sections** (from template):
   - Context (problem statement, goals, constraints)
   - Decision (what was decided)
   - Rationale (why this decision)
   - Alternatives Considered (what was rejected and why)
   - Consequences (positive, negative, neutral)
   - Implementation (how to execute)
   - Validation (success criteria)
   - Risks (what could go wrong, mitigations)
   - Related Decisions (links to other ADRs/PDRs)
   - Related Best Practices (research validation)
   - References (industry sources)

3. **Status**:
   - `Proposed` → Draft, under discussion
   - `Accepted` → Decision made, active
   - `Superseded` → Replaced by newer ADR
   - `Deprecated` → No longer applicable

4. **Immutability**: Once `Accepted`, ADRs are immutable
   - Minor corrections OK (typos, clarifications)
   - Material changes require new ADR

### Current ADRs

- **ADR-0001**: GCP as Pilot Platform
- **ADR-0002**: Documentation-First Approach
- **ADR-0003**: Containerization Strategy
- **ADR-0004**: Scala 3 Technology Stack
- **ADR-0005**: Reactive Manifesto Alignment
- **ADR-0006**: Agent-Based Service Patterns
- **ADR-0007**: CQRS and Event-Driven Architecture

---

## PDR: Process Decision Record

### When to Create

✅ **Create PDR for**:
- Documentation standards and organization
- Development workflow changes
- Repository structure decisions
- Framework selection policies
- Code review processes
- Release procedures
- Governance processes

❌ **Don't create PDR for**:
- Technical/architecture decisions (use ADR)
- One-off operational decisions (use session summary)
- Service-specific processes (document in service)

### Template Location

```
doc/internal/governance/PDRs/PDR-TEMPLATE.md
```

Co-located with PDRs for Copilot discoverability.

### Naming Convention

```
PDR-NNNN-short-title.md
```

Examples:
- `PDR-0004-repository-organization.md`
- `PDR-0005-framework-selection-policy.md`
- `PDR-0006-service-canvas-standard.md`
- `PDR-0007-documentation-asset-management.md`

### Process

Same as ADR but for process/workflow decisions.

### Current PDRs

- **PDR-0001**: Documentation Standards
- **PDR-0002**: Code Review Process
- **PDR-0003**: Governance Document Lifecycle
- **PDR-0004**: Repository Organization Strategy
- **PDR-0005**: Framework Selection Policy
- **PDR-0006**: Service Canvas Documentation Standard
- **PDR-0007**: Documentation Asset Management

---

## POL: Policy

### When to Create

✅ **Create POL for**:
- Security policies (data handling, access control, encryption)
- Compliance requirements (GDPR, PCI-DSS, SOC2)
- Mandatory standards (naming conventions, licensing)
- Legal/contractual requirements
- Risk management policies

❌ **Don't create POL for**:
- Recommendations (use ADR/PDR)
- Best practices (use best-practices/)
- Service-specific rules (document in service)

### Template Location

```
doc/internal/governance/POLs/POL-TEMPLATE.md
```

Co-located with POLs for Copilot discoverability.

### Naming Convention

```
POL-category-policy-name.md
```

Examples:
- `POL-security-data-encryption.md`
- `POL-compliance-gdpr.md`
- `POL-licensing-open-source-only.md`

### Process

Same structure as ADR/PDR but for mandatory policies.

### Current POLs

(To be created as needed)

---

## Service Canvas

### When to Create

✅ **Create for every service**: Mandatory per PDR-0006

**Timing**: Before or during service implementation (design forcing function)

### Template Location

```
doc/internal/governance/templates/SERVICE-CANVAS.md
```

**Copy to service repo root** when creating new service.

### Naming Convention

```
SERVICE-CANVAS.md
```

Always named exactly this, in service repository root.

### Process

1. **Copy template**:
   ```bash
   # In new service repository
   cp /path/to/TJMPaaS/doc/internal/governance/templates/SERVICE-CANVAS.md ./SERVICE-CANVAS.md
   ```

2. **Fill in sections**:
   - Service Identity (mission, tech stack, governance)
   - Dependencies (services, external, frameworks)
   - Architecture (actors, agents, message protocols)
   - API Contract (Commands, Queries, Events - CQRS)
   - Non-Functional Requirements (reactive alignment, SLOs, resources)
   - Observability (health checks, metrics, logging, tracing)
   - Operations (deployment, env vars, secrets, runbooks)
   - Documentation (links to detailed docs)
   - Release History
   - Security (auth, data protection, scanning)
   - Testing (coverage, types, frameworks)
   - Disaster Recovery (backup, RTO/RPO)
   - Future Considerations
   - Canvas Changelog

3. **Update regularly**:
   - Major changes (architecture, API, dependencies)
   - API changes (commands, queries, events)
   - New dependencies
   - SLO changes
   - Quarterly reviews

### Documentation Hierarchy

```
README.md              → Entry point, quick start
   ↓
SERVICE-CANVAS.md     → Comprehensive overview (1 page)
   ↓
docs/                  → Detailed documentation
  ├── ARCHITECTURE.md
  ├── API.md
  ├── DEPLOYMENT.md
  └── runbooks/
```

### Example

See `doc/internal/examples/CartService-CANVAS-example.md` for reference implementation.

---

## Session Summary

### When to Create

✅ **Create after**:
- Significant work sessions (> 2 hours of focused work)
- Major decisions made
- Multiple ADRs/PDRs created
- Milestone completions
- Scope changes
- Architecture discussions

### Template Location

```
doc/internal/audit/SESSION-SUMMARY-TEMPLATE.md
```

Co-located with session summaries.

### Naming Convention

```
session-YYYY-MM-DD-topic.md
```

Examples:
- `session-2025-11-26-governance-analysis.md`
- `session-2025-11-26-template-organization.md`
- `session-2025-11-26-copilot-optimization.md`

### Process

1. **Copy template**:
   ```bash
   cd doc/internal/audit
   cp SESSION-SUMMARY-TEMPLATE.md session-2025-11-26-topic.md
   ```

2. **Document**:
   - Date, participants, context
   - Decisions made
   - Actions taken
   - Outcomes
   - Next steps

---

## Best Practices Research

### When to Create

✅ **Create when**:
- Researching industry best practices
- Validating architectural decisions
- Investigating new technology
- Documenting evidence for ADRs
- Studying case studies

### Template Location

```
doc/internal/best-practices/BEST-PRACTICE-TEMPLATE.md
```

Co-located with best practices research.

### Naming Convention

```
doc/internal/best-practices/[category]/topic.md
```

Examples:
- `architecture/reactive-manifesto.md`
- `architecture/cqrs-patterns.md`
- `development/scala3.md`
- `development/mill-build-tool.md`

### Process

1. **Copy template**:
   ```bash
   cd doc/internal/best-practices/[category]
   cp ../BEST-PRACTICE-TEMPLATE.md topic.md
   ```

2. **Research**:
   - Overview (what is this?)
   - Industry consensus (what do experts say?)
   - Evidence (case studies, data, benchmarks)
   - Trade-offs (pros/cons, when to use/avoid)
   - TJMPaaS application (how we use it)
   - References (sources)

3. **Update index**:
   - Add entry to `BEST-PRACTICES-GUIDE.md`

---

## Template Co-Location Strategy

### Rationale

**Why co-locate templates near usage context?**

Copilot has limited context window (~4K-8K tokens):
- Searches near current file location first
- Proximity dramatically improves discovery
- Templates in same directory = reliable suggestions
- Distant templates often missed

**Example**: Working in `governance/ADRs/`, template `ADRs/ADR-TEMPLATE.md` is found immediately. If template was in `templates/`, Copilot might miss it.

### DRY Compliance

Still maintain single source of truth:
- One template per type (no duplication)
- Strategically placed for discoverability
- Master index (TEMPLATES-GUIDE.md) for humans

### Template Locations

| Template | Location | Why There |
|----------|----------|-----------|
| ADR-TEMPLATE.md | `governance/ADRs/` | Near ADRs |
| PDR-TEMPLATE.md | `governance/PDRs/` | Near PDRs |
| POL-TEMPLATE.md | `governance/POLs/` | Near POLs |
| SERVICE-CANVAS.md | `governance/templates/` | Cross-cutting (copied to service repos) |
| BEST-PRACTICE-TEMPLATE.md | `best-practices/` | Near research docs |
| SESSION-SUMMARY-TEMPLATE.md | `audit/` | Near session summaries |

**Master Index**: `doc/internal/TEMPLATES-GUIDE.md` maps all template locations for human discoverability.

---

## Status Markers

All templates and governance documents include status:

```markdown
**Status**: [Active Template / Proposed / Accepted / Superseded / Deprecated]
**Authority**: [TJMPaaS Official / Previous Project / Reference Only]
**Last Updated**: YYYY-MM-DD
```

---

## Decision Flow

```
┌─────────────────────┐
│  Decision Needed    │
└─────────┬───────────┘
          │
          ├─ Technical/Architecture? ──→ ADR
          │
          ├─ Process/Workflow? ──→ PDR
          │
          ├─ Mandatory Rule/Policy? ──→ POL
          │
          ├─ New Service? ──→ Service Canvas
          │
          ├─ Research/Evidence? ──→ Best Practice
          │
          └─ Significant Session? ──→ Session Summary
```

---

## Governance Process Summary

1. **Identify** decision/change needing documentation
2. **Choose** document type (ADR/PDR/POL/Canvas/Best Practice/Session)
3. **Copy** template from appropriate location
4. **Fill** in all sections following template structure
5. **Review** (self-review initially, team review later)
6. **Update status** to `Accepted` when finalized
7. **Link** from related documents (cross-reference)
8. **Update indexes** (service registry, best practices guide, etc.)

---

## Immutability Rules

### ADRs and PDRs

**Once Accepted**:
- ✅ Minor corrections OK (typos, clarifications, formatting)
- ❌ Material changes require new ADR/PDR
- Why: Preserves decision history and rationale

**Superseding**:
```markdown
**Status**: Superseded by [ADR-NNNN](link)
```

### POLs

**Once Active**:
- ✅ Minor corrections OK
- ❌ Material changes require new POL version
- Why: Compliance and audit requirements

### Service Canvas

**Living Document**:
- ✅ Updated with service changes
- Update frequency: Major changes, API changes, new dependencies, SLO changes, quarterly reviews
- Canvas Changelog section tracks major updates

---

## Quick Links

**Templates**:
- [TEMPLATES-GUIDE.md](../TEMPLATES-GUIDE.md) - Master template index
- [ADR-TEMPLATE.md](../governance/ADRs/ADR-TEMPLATE.md)
- [PDR-TEMPLATE.md](../governance/PDRs/PDR-TEMPLATE.md)
- [POL-TEMPLATE.md](../governance/POLs/POL-TEMPLATE.md)
- [SERVICE-CANVAS.md](../governance/templates/SERVICE-CANVAS.md)
- [BEST-PRACTICE-TEMPLATE.md](../best-practices/BEST-PRACTICE-TEMPLATE.md)
- [SESSION-SUMMARY-TEMPLATE.md](../audit/SESSION-SUMMARY-TEMPLATE.md)

**Governance**:
- [ADRs](../governance/ADRs/) - All architectural decisions
- [PDRs](../governance/PDRs/) - All process decisions
- [POLs](../governance/POLs/) - All policies
- [Best Practices](../best-practices/) - All research

**Standards**:
- [PDR-0003: Governance Document Lifecycle](../governance/PDRs/PDR-0003-governance-document-lifecycle.md)
- [PDR-0006: Service Canvas Standard](../governance/PDRs/PDR-0006-service-canvas-standard.md)
- [PDR-0007: Documentation Asset Management](../governance/PDRs/PDR-0007-documentation-asset-management.md)

---

**For Examples**: See existing ADRs, PDRs, and the CartService canvas example in `doc/internal/examples/`
