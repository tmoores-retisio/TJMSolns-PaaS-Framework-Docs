# Technical Documentation Layer

**Purpose**: Architecture, design, and implementation details for TJMPaaS services and infrastructure

**Audience**: Developers, technical architects, operations engineers

**Lifecycle**: Draft → Technical Review → Published → Updated as system evolves

**Update Frequency**: Weekly to monthly (as services evolve)

**Authority**: Technical lead approval (Tony currently)

---

## What Goes Here

- Cross-service architecture documentation
- Service designs (before implementation)
- Best practices research and validation
- Technical standards and patterns
- Infrastructure design documentation

## What Doesn't Go Here

- **Governance decisions** → Use `governance/` (ADRs, PDRs, POLs)
- **Process guides** → Use `process/` (how-to guides, runbooks)
- **Audit trails** → Use `compliance/` (session summaries, gap tracking)
- **Public documentation** → Use `external/` (customer-facing docs)

---

## Directory Structure

```
technical/
├── README.md (this file)
├── architecture/         # Cross-service architecture
├── services/            # Service design documents (pre-implementation)
│   ├── entity-management/
│   └── provisioning-service/
├── best-practices/      # Research and validation
│   ├── architecture/
│   └── development/
├── infrastructure/      # Infrastructure design (future)
└── examples/           # Reference implementations (future)
```

---

## Current Contents

- **services/entity-management/** - Complete service design (18 files, 5 features)
- **services/provisioning-service/** - Vision charter stub
- **best-practices/** - Architecture and development research (8 documents)

---

## Related Layers

- **Governance** (`governance/`) - References architectural best practices to validate ADRs
- **Process** (`process/`) - Developer guides reference service designs and architecture
- **Compliance** (`compliance/`) - Audit trails reference architectural decisions

---

**See**: [ADR-0009: Documentation Architecture Strategy](../governance/ADRs/ADR-0009-documentation-architecture.md) for complete layer definitions
