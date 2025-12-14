# Process Documentation Layer

**Purpose**: How to work in TJMPaaS - workflows, procedures, guides for team operations

**Audience**: Developers, operations engineers, new team members

**Lifecycle**: Draft → Team Review → Published → Updated based on feedback

**Update Frequency**: Monthly or as processes change

**Authority**: Team consensus (Tony currently)

---

## What Goes Here

- Developer guides (how to create a service, how to deploy)
- Operational runbooks (incident response, maintenance)
- Onboarding documentation (for future team)
- Tool setup guides (IDE, development environment)
- Workflow documentation (code review, testing, CI/CD)
- Project management (charter, roadmap)

## What Doesn't Go Here

- **Architecture decisions** → Use `governance/` (ADRs)
- **Technical designs** → Use `technical/` (service designs, architecture)
- **Audit trails** → Use `compliance/` (session summaries)
- **Customer guides** → Use `external/` (public documentation)

---

## Directory Structure

```
process/
├── README.md (this file)
├── project-charter.md   # Project mission and scope (keep at root or here)
├── project-roadmap.md   # Timeline and milestones (keep at root or here)
├── development/         # Developer workflows
│   └── local-setup.md
├── operations/          # Operational procedures
│   └── runbooks/
├── onboarding/          # New team member guides (future)
├── tools/              # Tool setup and usage
│   └── copilot-references/
```

---

## Current Contents

- **CHARTER.md** (at `doc/internal/` root) - Project mission and scope
- **ROADMAP.md** (at `doc/internal/` root) - Timeline and milestones
- **LOCAL-DEVELOPMENT-GUIDE.md** (to move here as `development/local-setup.md`)
- **copilot-references/** (to move here as `tools/copilot-references/`)

---

## Related Layers

- **Governance** (`governance/`) - Process decisions (PDRs) define workflows
- **Technical** (`technical/`) - Guides reference service designs and architecture
- **Compliance** (`compliance/`) - Processes must support audit requirements

---

**See**: [ADR-0009: Documentation Architecture Strategy](../governance/ADRs/ADR-0009-documentation-architecture.md) for complete layer definitions
