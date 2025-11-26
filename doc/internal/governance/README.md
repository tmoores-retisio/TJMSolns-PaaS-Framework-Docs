# Governance Documentation

This directory contains the governance framework for TJMPaaS, including decision records and policies that guide project development and operations.

## Structure

```text
governance/
├── ADRs/          # Architectural Decision Records
├── PDRs/          # Process Decision Records
├── POLs/          # Policies
└── archive/       # Superseded and deprecated documents
    ├── ADRs/
    ├── PDRs/
    └── POLs/
```

## Document Types

### Architectural Decision Records (ADRs)

**Purpose**: Document significant architectural and technical decisions

**Location**: `ADRs/`

**Naming Convention**: `ADR-NNNN-short-title.md`

**When to Create**:
- Choosing technologies, frameworks, or platforms
- Defining system architecture or design patterns
- Making infrastructure decisions
- Selecting between technical alternatives

**Template**: See `ADRs/TEMPLATE.md`

### Process Decision Records (PDRs)

**Purpose**: Document process, workflow, and methodology decisions

**Location**: `PDRs/`

**Naming Convention**: `PDR-NNNN-short-title.md`

**When to Create**:
- Establishing development workflows
- Defining operational procedures
- Changing team processes
- Adopting new methodologies

**Template**: See `PDRs/TEMPLATE.md`

### Policies (POLs)

**Purpose**: Establish enforceable rules, standards, and guidelines

**Location**: `POLs/`

**Naming Convention**: `POL-category-policy-name.md`

**When to Create**:
- Security requirements
- Compliance standards
- Quality gates
- Access control rules
- Data governance

**Categories**:
- `security-` - Security policies
- `compliance-` - Regulatory/compliance policies
- `quality-` - Quality assurance policies
- `operational-` - Operations policies
- `data-` - Data governance policies

## Governance Principles

1. **Transparency**: All significant decisions should be documented
2. **Traceability**: Link decisions to outcomes and related documents
3. **Accountability**: Clearly state who made the decision and when
4. **Reversibility**: Document what would trigger reconsidering a decision
5. **Learning**: Capture consequences and lessons learned
6. **Immutability**: Once accepted, documents become historical records (see [PDR-0003](PDRs/PDR-0003-governance-document-lifecycle.md))

## Review Process

- **ADRs**: Review when technology landscape changes or issues arise
- **PDRs**: Review quarterly or when process friction is identified
- **POLs**: Review annually or when compliance requirements change

## Status Values

All governance documents should include a status:

- **Proposed**: Under consideration
- **Accepted**: Approved and active (ADRs, PDRs)
- **Active**: Enforced policy (POLs only)
- **Deprecated**: No longer recommended but not yet replaced
- **Superseded**: Replaced by a newer decision (reference the new document)
- **Rejected**: Considered but not adopted

See [PDR-0003: Governance Document Lifecycle](PDRs/PDR-0003-governance-document-lifecycle.md) for complete lifecycle and archival process.

## Document Immutability

Governance documents are **immutable historical records** once accepted. Material changes require creating new superseding documents. Superseded and deprecated documents are moved to the [archive](archive/) with preserved content.

**Acceptable Minor Changes**:
- Typo corrections
- Formatting improvements
- Broken link fixes
- Status updates
- Cross-reference additions

**Material Changes Require New Document**:
- Decision changes
- Rationale changes
- Scope changes
- Requirement changes

See [PDR-0003](PDRs/PDR-0003-governance-document-lifecycle.md) for complete rules.

## Related Documents

- [PDR-0003: Governance Document Lifecycle](PDRs/PDR-0003-governance-document-lifecycle.md) - Document immutability and archival
- [PDR-0002: Governance Decision Framework](PDRs/PDR-0002-governance-framework.md) - When to create which document type
- [Archive](archive/) - Superseded and deprecated documents
- [Project Charter](../CHARTER.md) - Overall project scope and mission
- [Roadmap](../ROADMAP.md) - Timeline and milestones
- [Architecture](../architecture/) - System design documentation
