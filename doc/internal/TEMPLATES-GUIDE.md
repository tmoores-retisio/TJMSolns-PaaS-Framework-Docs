# TJMPaaS Template Guide

**Purpose**: Master index of all templates in TJMPaaS governance repository

**Strategy**: Templates are co-located with their usage context for optimal Copilot discoverability while maintaining DRY principles (single template per type).

**Last Updated**: 2025-11-26

---

## Why Co-Location Strategy?

**Copilot Optimization**: Templates are located near their usage context because:
- Copilot searches near current file location first (limited context window)
- Proximity dramatically improves template discovery and suggestion accuracy
- Local conventions are more reliable than requiring global search
- Reduces cognitive load - "template is where the documents are"

**DRY Compliance**: Single authoritative template per type, strategically placed rather than centrally clustered.

**Human Discoverability**: This index provides the map when you need to find a template quickly.

---

## Template Locations

### Governance Document Templates

| Template | Location | Purpose | Status |
|----------|----------|---------|--------|
| [ADR-TEMPLATE.md](governance/ADRs/ADR-TEMPLATE.md) | `doc/internal/governance/ADRs/` | Architectural Decision Records | Active Template |
| [PDR-TEMPLATE.md](governance/PDRs/PDR-TEMPLATE.md) | `doc/internal/governance/PDRs/` | Process Decision Records | Active Template |
| [POL-TEMPLATE.md](governance/POLs/POL-TEMPLATE.md) | `doc/internal/governance/POLs/` | Policy Documents | Active Template |

**Usage**: When creating new governance document, template is in same directory - just copy and rename.

### Service Documentation Templates

| Template | Location | Purpose | Status |
|----------|----------|---------|--------|
| [SERVICE-CANVAS.md](governance/templates/SERVICE-CANVAS.md) | `doc/internal/governance/templates/` | Service canvas for all TJMPaaS services | Active Template |
| [FEATURE-TEMPLATE.md](governance/templates/FEATURE-TEMPLATE.md) | `doc/internal/governance/templates/` | Feature documentation for all TJMPaaS features | Active Template |

**Usage**: 
- SERVICE-CANVAS.md copied to service repository root when creating new service
- FEATURE-TEMPLATE.md copied to service `features/` directory for per-feature documentation

**Governance**: [PDR-0006: Service Canvas Documentation Standard](governance/PDRs/PDR-0006-service-canvas-standard.md)

### Research and Analysis Templates

| Template | Location | Purpose | Status |
|----------|----------|---------|--------|
| [BEST-PRACTICE-TEMPLATE.md](best-practices/BEST-PRACTICE-TEMPLATE.md) | `doc/internal/best-practices/` | Best practices research documents | Active Template |

**Usage**: Copy to appropriate subdirectory (`architecture/`, `development/`, etc.) and fill in research findings.

### Conversation and Audit Templates

| Template | Location | Purpose | Status |
|----------|----------|---------|--------|
| [SESSION-SUMMARY-TEMPLATE.md](audit/SESSION-SUMMARY-TEMPLATE.md) | `doc/internal/audit/` | Session summary documentation | Active Template |

**Usage**: Document significant work sessions, decisions, and outcomes for project history.

### Examples (Reference Implementations)

| Example | Location | Purpose |
|----------|----------|---------|
| [CartService-CANVAS-example.md](examples/CartService-CANVAS-example.md) | `doc/internal/examples/` | Completed service canvas showing best practices |

**Note**: Examples are reference implementations, not templates to copy.

---

## Template Status and Authority

All templates include status frontmatter:

```markdown
---
**Status**: Active Template
**Authority**: TJMPaaS Official
**Last Updated**: YYYY-MM-DD
**Governance**: [Link to PDR/ADR if applicable]
---
```

**Active Template** = Authoritative for TJMPaaS use
- Only one per type (DRY compliant)
- Maintained and updated as project evolves
- Referenced by governance documents where applicable

---

## Using Templates

### For Governance Documents (ADRs, PDRs, POLs)

1. **Navigate to appropriate directory**:
   ```bash
   cd doc/internal/governance/ADRs/   # or PDRs/ or POLs/
   ```

2. **Copy template file**:
   ```bash
   cp ADR-TEMPLATE.md ADR-NNNN-short-title.md
   ```

3. **Fill in template sections** following the structure

4. **Copilot will find template automatically** when working in same directory

### For Service Canvas

1. **Template location**: `doc/internal/governance/templates/SERVICE-CANVAS.md`

2. **When creating new service**:
   ```bash
   # In new service repository
   cp /path/to/TJMPaaS/doc/internal/governance/templates/SERVICE-CANVAS.md ./SERVICE-CANVAS.md
   ```

3. **Fill in service-specific details**

4. **Service canvas lives in service repo** (not governance repo)

5. **Governance**: [PDR-0006](governance/PDRs/PDR-0006-service-canvas-standard.md)

### For Feature Documentation

1. **Template location**: `doc/internal/governance/templates/FEATURE-TEMPLATE.md`

2. **When creating new feature**:
   ```bash
   # In service repository features/ directory
   cp /path/to/TJMPaaS/doc/internal/governance/templates/FEATURE-TEMPLATE.md \
      ./features/<feature-name>.md
   ```

3. **Create Gherkin file**: `features/<feature-name>.feature` (BDD scenarios)

4. **Fill in feature-specific details** following template structure

5. **Update SERVICE-CANVAS.md** with feature entry in Features section

6. **Governance**: [PDR-0008](governance/PDRs/PDR-0008-feature-documentation-standard.md)

### For Best Practices Research

1. **Template location**: `doc/internal/best-practices/BEST-PRACTICE-TEMPLATE.md`

2. **Copy to appropriate subdirectory**:
   ```bash
   cp doc/internal/best-practices/BEST-PRACTICE-TEMPLATE.md \
      doc/internal/best-practices/architecture/new-topic.md
   ```

3. **Fill in research findings** following structure

### For Session Summaries

1. **Template location**: `doc/internal/audit/SESSION-SUMMARY-TEMPLATE.md`

2. **Copy with date-based naming**:
   ```bash
   cp doc/internal/audit/SESSION-SUMMARY-TEMPLATE.md \
      doc/internal/audit/session-2025-11-26-topic.md
   ```

3. **Document session outcomes**

---

## Copilot Discovery Behavior

### How Copilot Finds Templates

1. **Current directory first** - Checks where you're working (e.g., ADRs/ has ADR-TEMPLATE.md)
2. **Parent directory** - Looks one level up if not in current directory
3. **Context search** - Limited search based on open files and recent activity
4. **Rarely finds distant files** - Templates far from context often missed

### Why Co-Location Works

**Example**: Creating a new ADR
- Working in: `doc/internal/governance/ADRs/`
- Template: `doc/internal/governance/ADRs/ADR-TEMPLATE.md`
- Copilot sees template immediately (same directory)
- Suggestions based on template structure
- No need to search elsewhere

**Counter-Example**: If template was in `doc/internal/templates/`
- Copilot likely wouldn't find it (too far from context)
- Would need explicit prompt to locate template
- Higher chance of inconsistent formatting

---

## Directory Structure Reference

```
doc/internal/
├── TEMPLATES-GUIDE.md              ← You are here (master index)
│
├── governance/
│   ├── ADRs/
│   │   ├── ADR-TEMPLATE.md         ← Template for ADRs
│   │   ├── ADR-0001-*.md
│   │   └── ...
│   ├── PDRs/
│   │   ├── PDR-TEMPLATE.md         ← Template for PDRs
│   │   ├── PDR-0001-*.md
│   │   └── ...
│   ├── POLs/
│   │   ├── POL-TEMPLATE.md         ← Template for policies
│   │   └── ...
│   └── templates/
│       └── SERVICE-CANVAS.md       ← Service canvas template
│
├── best-practices/
│   ├── BEST-PRACTICE-TEMPLATE.md   ← Template for research docs
│   ├── architecture/
│   ├── development/
│   └── ...
│
├── audit/
│   ├── SESSION-SUMMARY-TEMPLATE.md ← Template for session summaries
│   └── ...
│
├── examples/
│   └── CartService-CANVAS-example.md ← Reference implementation
│
├── working/                         ← Temporary documents (90-day retention)
│   ├── research-notes/
│   └── drafts/
│
└── archive/
    └── legacy/                      ← Previous project templates (reference only)
```

---

## Adding New Templates

When creating a new template type:

1. **Determine optimal location**:
   - Where will documents using this template live?
   - Co-locate template with its usage context

2. **Create template with status markers**:
   ```markdown
   ---
   **Status**: Active Template
   **Authority**: TJMPaaS Official
   **Last Updated**: 2025-11-26
   ---
   ```

3. **Update this guide**:
   - Add entry to appropriate table
   - Document location and usage
   - Link to governance if applicable

4. **Update Copilot instructions** (optional):
   - If template is frequently used
   - Add to `.github/copilot-instructions.md`

---

## Governance

**Established by**: [PDR-0007: Documentation Asset Management](governance/PDRs/PDR-0007-documentation-asset-management.md)

**Template Strategy**: Co-location for Copilot optimization while maintaining DRY principles

**Key Principles**:
- Single authoritative template per type (DRY)
- Templates located near usage context (Copilot optimization)
- Clear status markers on all templates
- Master index for human discoverability

---

## See Also

- [PDR-0007: Documentation Asset Management](governance/PDRs/PDR-0007-documentation-asset-management.md) - Documentation organization standards
- [PDR-0006: Service Canvas Documentation Standard](governance/PDRs/PDR-0006-service-canvas-standard.md) - Service canvas requirements
- [PDR-0003: Governance Document Lifecycle](governance/PDRs/PDR-0003-governance-document-lifecycle.md) - ADR/PDR/POL lifecycle
- [Documentation Standards](.github/copilot-instructions.md#documentation-standards) - Copilot instructions

---

## Maintenance

**Quarterly Review**: Verify template locations, update this guide, check for unused templates

**When Templates Change**: Update status markers, document in template changelog, notify team (when team exists)

**Version Control**: Templates versioned with Git history; major changes may create new template version

---

**Last Reviewed**: 2025-11-26  
**Next Review**: 2026-02-26 (quarterly)
