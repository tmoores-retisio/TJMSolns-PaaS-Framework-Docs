# Compliance Documentation Layer

**Purpose**: Audit trails, regulatory compliance, legal requirements, retention policies

**Audience**: Compliance officers, legal team, auditors, regulators

**Lifecycle**: Created → Reviewed → Immutable (append-only for audit)

**Update Frequency**: Per event (session summaries), quarterly (compliance reviews)

**Authority**: Compliance officer approval (Tony currently, legal/compliance future)

**Retention**: Never deleted (retained per retention policy)

---

## What Goes Here

- Session summaries (audit trail of decisions)
- Standards gaps tracking
- Compliance checklists
- Regulatory documentation (GDPR, SOC2, etc.)
- Data retention policies
- Incident reports
- Legacy/archived documentation

## What Doesn't Go Here

- **Current decisions** → Use `governance/` (ADRs, PDRs, POLs)
- **Active technical docs** → Use `technical/` (service designs)
- **Active process guides** → Use `process/` (developer guides)
- **Working documents** → Use `working/` (temporary drafts)

---

## Directory Structure

```
compliance/
├── README.md (this file)
├── audit/              # Audit trail and session summaries
│   ├── SESSION-SUMMARY-TEMPLATE.md
│   └── session-*.md
├── gaps/              # Standards and compliance gaps tracking
│   ├── STANDARDS-GAPS.md
│   ├── GAPS-REMEDIATION-PLAN.md
│   └── GAPS-EXECUTION-TRACKER.md
├── regulatory/        # Regulatory compliance (future)
│   ├── gdpr-compliance.md
│   └── soc2-readiness.md
├── incidents/         # Incident reports (future)
└── archive/          # Archived documentation
    └── legacy/       # From previous projects
```

---

## Current Contents

- **audit/** (to move from `doc/internal/audit/`) - Session summaries
- **gaps/** (to move from `doc/internal/gaps/`) - Standards gaps tracking
- **archive/legacy/** (to move from `doc/internal/archive/legacy/`) - Previous project templates

---

## Immutability Policy

**Compliance documents are append-only**:
- Session summaries are never edited after creation (corrections in new entry)
- Gap tracking updated but changes tracked (status transitions logged)
- Incident reports immutable after filing
- Archive documents never modified

**Retention Policy** (future):
- Session summaries: 7 years
- Gap tracking: Permanent (project history)
- Incident reports: 7 years
- Regulatory compliance: Per regulation requirements

---

## Related Layers

- **Governance** (`governance/`) - Decisions recorded in audit trail
- **Technical** (`technical/`) - Architecture changes tracked in audit
- **Process** (`process/`) - Process changes tracked in audit

---

**See**: [ADR-0009: Documentation Architecture Strategy](../governance/ADRs/ADR-0009-documentation-architecture.md) for complete layer definitions
