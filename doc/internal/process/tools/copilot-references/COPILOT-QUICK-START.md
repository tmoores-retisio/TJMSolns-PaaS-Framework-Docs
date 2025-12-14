# TJMPaaS Quick Start for Copilot

**Purpose**: Essential project information for quick reference

**Last Updated**: 2025-11-26

---

## Project Essentials

**Name**: TJM Solutions PaaS Framework (TJMPaaS)  
**Owner**: Tony Moores (TJMSolns)  
**Contact**: tmoores@tjm.solutions  
**GitHub**: tmoores-retisio  
**Status**: Phase 0 - Foundation (as of 2025-11-26)

**Mission**: Build a library of containerized, cloud-native services for digital commerce and modern applications.

**Approach**:
- Multi-cloud (starting with GCP)
- Multi-repository (one repo per service)
- Functional programming with Scala 3
- Reactive architecture with actor model
- CQRS and event-driven patterns
- Research-backed architectural decisions

---

## Technology Stack (Quick Reference)

| Category | Choice | Why |
|----------|--------|-----|
| **Language** | Scala 3.3+ | FP support, type safety, JVM ecosystem |
| **Build** | Mill | Fast, simple, Scala-native |
| **JVM** | OpenJDK 17/21 | LTS versions |
| **Actors** | Pekko (preferred) | Apache 2.0, community-driven Akka fork |
| | Akka Typed 2.6.x | Last Apache 2.0 Akka, mature ecosystem |
| | ZIO Actors | Lightweight, ZIO-first |
| **Effects** | ZIO or Cats Effect | Functional effects, pure FP |
| **HTTP** | http4s or ZIO HTTP | Pure functional HTTP |
| **Events** | Apache Kafka | High-throughput event streaming |
| **Containers** | Docker + Kubernetes | Cloud-native, multi-cloud portability |
| **Cloud** | GCP (initial) | Pilot platform, multi-cloud later |

**Framework Policy**: Best-fit per service, max 3 per category across all projects (PDR-0005)

---

## Repository Structure

```
TJMPaaS/                          # Governance repository (this repo)
├── .github/
│   └── copilot-instructions.md   # Lean navigational instructions
├── doc/
│   ├── internal/                 # Internal documentation
│   │   ├── CHARTER.md            # Project mission and scope
│   │   ├── ROADMAP.md            # Timeline and milestones
│   │   ├── TEMPLATES-GUIDE.md    # Master template index
│   │   ├── BEST-PRACTICES-GUIDE.md # Research index
│   │   ├── governance/
│   │   │   ├── ADRs/             # Architectural decisions
│   │   │   ├── PDRs/             # Process decisions
│   │   │   ├── POLs/             # Policies
│   │   │   └── templates/        # Cross-cutting templates
│   │   ├── best-practices/       # Research and evidence
│   │   ├── copilot-references/   # Quick reference docs
│   │   ├── examples/             # Reference implementations
│   │   └── audit/                # Session summaries
│   └── external/                 # Public documentation
└── ...

TJMSolns-ServiceName/             # Service repositories (separate)
├── README.md                     # Entry point
├── SERVICE-CANVAS.md             # Comprehensive service overview
├── build.sc                      # Mill build
├── src/                          # Source code
├── docs/                         # Detailed documentation
├── docker/                       # Containerization
└── k8s/                          # Kubernetes manifests
```

**Key Principle**: Multi-repo strategy - each service is independent (PDR-0004)

---

## Documentation Workflow

### When to Create Governance Documents

**ADR** (Architectural Decision Record):
- Major technical/architecture decisions
- Technology selection
- Architectural patterns
- Template: `doc/internal/governance/ADRs/ADR-TEMPLATE.md`

**PDR** (Process Decision Record):
- Workflow/process changes
- Documentation standards
- Development practices
- Template: `doc/internal/governance/PDRs/PDR-TEMPLATE.md`

**POL** (Policy):
- Rules, standards, compliance
- Mandatory requirements
- Governance policies
- Template: `doc/internal/governance/POLs/POL-TEMPLATE.md`

**Session Summary**:
- After significant work sessions
- Major conversations/decisions
- Milestone completions
- Template: `doc/internal/compliance/audit/SESSION-SUMMARY-TEMPLATE.md`

---

## Common Tasks

### Creating a New ADR
```bash
cd doc/internal/governance/ADRs
cp ADR-TEMPLATE.md ADR-NNNN-short-title.md
# Edit file, following template structure
```

### Creating a New Service
1. Create repo: `TJMSolns-ServiceName`
2. Copy SERVICE-CANVAS.md template to repo root
3. Fill in canvas (design forcing function)
4. Implement service
5. Update service registry in governance repo

### Adding Best Practices Research
```bash
cd doc/internal/technical/best-practices/[category]
cp ../BEST-PRACTICE-TEMPLATE.md new-topic.md
# Research, document findings
# Update BEST-PRACTICES-GUIDE.md index
```

### Documenting a Session
```bash
cd doc/internal/compliance/audit/sessions
cp SESSION-SUMMARY-TEMPLATE.md session-2025-11-26-topic.md
# Fill in decisions, actions, outcomes
```

---

## Key Architectural Patterns

### Reactive Manifesto (ADR-0005)
- **Responsive**: Timely response
- **Resilient**: Handle failures gracefully
- **Elastic**: Scale with demand
- **Message-Driven**: Async communication

### CQRS (ADR-0007)
- **Level 1**: Simple CQRS - Separate methods, same DB (rarely used)
- **Level 2**: Standard CQRS - Separate models/DBs, no ES (**TJMPaaS default**)
- **Level 3**: Full CQRS/ES - Event sourcing (audit-critical only)

### Event-Driven Architecture (ADR-0007)
- Kafka for high-throughput event streaming
- Async boundaries between services
- Saga patterns for distributed transactions

### Actor Model (ADR-0006)
- Pekko/Akka/ZIO actors for stateful entities
- Message-passing for concurrency
- Supervision hierarchies for fault tolerance
- One actor per entity (cart, order, session)

---

## Working with Tony

**Philosophy**: Critical thinking > agreement

**Key Points**:
- Solo developer initially
- Values constructive disagreement backed by research
- Multi-disciplinary perspective: Commerce + Architecture + PM
- Document decisions for future team
- Keep complexity manageable

**When to Disagree**:
- Conflicts with best practices
- Superior alternatives exist
- Risks not considered
- Simpler solutions available

**How to Disagree**:
- State clearly with rationale
- Provide research-backed alternatives
- Show trade-off analysis
- Reference industry evidence

---

## Quick Links

**Governance**:
- [CHARTER.md](../CHARTER.md) - Project mission
- [ROADMAP.md](../ROADMAP.md) - Timeline
- [ADRs](../governance/ADRs/) - Architecture decisions
- [PDRs](../governance/PDRs/) - Process decisions

**Standards**:
- [TEMPLATES-GUIDE.md](../TEMPLATES-GUIDE.md) - All templates
- [BEST-PRACTICES-GUIDE.md](../BEST-PRACTICES-GUIDE.md) - All research
- [PDR-0007](../governance/PDRs/PDR-0007-documentation-asset-management.md) - Doc organization

**Key ADRs**:
- ADR-0004: Scala 3 stack
- ADR-0005: Reactive Manifesto
- ADR-0006: Actor patterns
- ADR-0007: CQRS/Event-Driven

**Key PDRs**:
- PDR-0004: Multi-repo strategy
- PDR-0005: Framework selection (max 3)
- PDR-0006: Service canvas standard
- PDR-0007: Documentation asset management

---

**For More Details**: See referenced documents above or consult master guides (CHARTER, ROADMAP, BEST-PRACTICES-GUIDE, TEMPLATES-GUIDE)
