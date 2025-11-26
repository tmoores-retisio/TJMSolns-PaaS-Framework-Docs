# PDR-0007: Documentation Asset Management and Organization

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Technical Story**: Phase 0 - Foundation, documentation cleanup

## Context

The TJMPaaS repository contains documentation assets from multiple sources and purposes:
- TJMPaaS-specific templates and governance (current project)
- Legacy templates from previous projects (doc/tmp/)
- External vs internal documentation
- Templates, examples, and working documents

Without clear organization standards, documentation assets can become cluttered, outdated templates may be used accidentally, and it becomes unclear which assets are authoritative.

### Problem Statement

Establish clear organization and management standards for documentation assets to:
- Separate active templates from legacy/deprecated content
- Distinguish authoritative templates from examples
- Prevent accidental use of outdated templates
- Maintain clean, navigable documentation structure
- Support future archival and cleanup processes

### Goals

- Clear directory structure for documentation assets
- Explicit status for all templates and examples
- Easy identification of authoritative vs legacy content
- Simple archival process for outdated materials
- Prevent confusion about which templates to use

### Constraints

- Solo developer initially (simple process required)
- Must work with existing directory structure (doc/internal/, doc/external/)
- Git history must be preserved
- Templates referenced in governance docs must remain stable

## Decision

**Adopt structured documentation asset management** with:

1. **Standardized Directory Structure** for non-service documentation assets
2. **Co-Location Strategy** for templates (templates near usage context for Copilot optimization)
3. **Template Index** (TEMPLATES-GUIDE.md) for human discoverability
4. **Status Markers** in all templates and examples
5. **Archival Process** for legacy/deprecated content
6. **Template Authority** clearly documented
7. **Cleanup Schedule** for temporary/working documents

## Rationale

### Co-Location Strategy for Templates

**Why Co-Locate Templates with Usage Context**:

Copilot (and AI assistants generally) have context limitations:
- **Limited context window**: Can't always see distant files
- **Proximity search**: Search near current file location first
- **Better suggestions**: Templates in same directory = more accurate suggestions
- **Reduced drift**: Local conventions more reliable than global search

**Real-world example**:
- Working in `doc/internal/governance/ADRs/`
- Template: `doc/internal/governance/ADRs/ADR-TEMPLATE.md`
- Copilot finds template immediately (same directory)
- If template was in `doc/internal/templates/`, Copilot likely wouldn't find it

**DRY Compliance**:
- Still maintain single template per type (no duplication)
- Templates are strategically placed, not scattered
- TEMPLATES-GUIDE.md provides master index for human discoverability

**Benefits**:
- ✅ Copilot finds templates reliably
- ✅ DRY principles maintained (single source per type)
- ✅ Human discoverable (index + natural location)
- ✅ Lower cognitive load ("template is where the documents are")

### Clear Directory Structure

**Active Templates** (co-located with usage context):
- Authoritative templates for TJMPaaS
- Located near where they're used (Copilot optimization)
- Referenced by governance documents
- Maintained and updated
- Examples: ADR-TEMPLATE.md in ADRs/, PDR-TEMPLATE.md in PDRs/, SERVICE-CANVAS.md in governance/templates/

**Template Index** (doc/internal/TEMPLATES-GUIDE.md):
- Master index of all template locations
- Provides map for human discoverability
- Documents co-location strategy rationale
- Updated when templates added/moved

**Examples** (doc/internal/examples/):
- Completed examples showing template usage
- Read-only reference (not templates)
- Examples: CartService-CANVAS-example.md

**Legacy/Archive** (doc/internal/archive/legacy/):
- Templates from previous projects
- Kept for reference but not for use
- Clearly marked as legacy
- Examples: Previous project canvas formats

**Temporary Working Documents** (doc/tmp/ or doc/internal/working/):
- Drafts, scratch work, research notes
- Not authoritative
- Subject to cleanup
- Should be moved to permanent location or deleted

### Status Markers

Every template/example should have clear status frontmatter:

```markdown
**Status**: [Active Template / Example / Legacy / Deprecated / Working Draft]  
**Authority**: [TJMPaaS Official / Previous Project / Reference Only]  
**Last Updated**: YYYY-MM-DD  
**Supersedes**: [Link to superseded document if applicable]
```

### Benefits

1. **Clarity**: Immediately obvious which templates are authoritative
2. **Safety**: Prevents accidental use of outdated templates
3. **History**: Legacy templates preserved for reference
4. **Cleanliness**: Clear criteria for what belongs where
5. **Scalability**: Structure supports growth

## Process Description

### Directory Structure

```
doc/
├── external/                          # Public-facing documentation
│   └── ...
├── internal/
│   ├── TEMPLATES-GUIDE.md            # MASTER TEMPLATE INDEX
│   ├── governance/
│   │   ├── ADRs/
│   │   │   ├── ADR-TEMPLATE.md       # Template co-located with ADRs
│   │   │   └── ADR-*.md
│   │   ├── PDRs/
│   │   │   ├── PDR-TEMPLATE.md       # Template co-located with PDRs
│   │   │   └── PDR-*.md
│   │   ├── POLs/
│   │   │   ├── POL-TEMPLATE.md       # Template co-located with POLs
│   │   │   └── POL-*.md
│   │   └── templates/
│   │       └── SERVICE-CANVAS.md     # Service canvas template
│   ├── best-practices/
│   │   ├── BEST-PRACTICE-TEMPLATE.md # Template co-located with research
│   │   └── architecture/
│   ├── audit/
│   │   ├── SESSION-SUMMARY-TEMPLATE.md # Template co-located with summaries
│   │   └── session-*.md
│   ├── examples/                      # COMPLETED EXAMPLES (reference)
│   │   ├── CartService-CANVAS-example.md
│   │   └── ...
│   ├── working/                       # TEMPORARY WORKING DOCUMENTS
│   │   ├── research-notes/
│   │   ├── drafts/
│   │   └── README.md                 # Explains this is temporary workspace
│   ├── archive/
│   │   ├── legacy/                    # LEGACY FROM OTHER PROJECTS
│   │   │   ├── README.md             # Explains origin and purpose
│   │   │   └── retisio-canvas-templates/  # Previous project templates
│   │   └── ...
│   ├── governance/                    # Governance documents (ADRs, PDRs, POLs)
│   ├── architecture/                  # Architecture documentation
│   ├── best-practices/                # Best practices research
│   └── ...
└── tmp/                               # DEPRECATED - move contents to internal/working/ or archive/legacy/
```

### Template Status Requirements

**Active Templates** (co-located with usage context):
- Status: "Active Template"
- Authority: "TJMPaaS Official"
- Located near where they're used (Copilot optimization)
- Listed in TEMPLATES-GUIDE.md master index
- Must be referenced by governance documents where applicable
- Updated as project evolves
- Reviewed during governance reviews

**Examples** (doc/internal/examples/):
- Status: "Example" or "Reference Implementation"
- Authority: "TJMPaaS Official"
- Shows completed usage of templates
- Not modified after creation (unless corrections needed)

**Legacy Content** (doc/internal/archive/legacy/):
- Status: "Legacy" or "Previous Project"
- Authority: "Reference Only - Not for Use"
- Preserved for historical context
- README explains origin and why archived

**Working Documents** (doc/internal/working/):
- Status: "Working Draft" or "Temporary"
- Authority: "Not Authoritative"
- Subject to deletion after 90 days unused
- Should be promoted to permanent location or deleted

### Migration Process (Current Cleanup)

**Immediate Actions**:

1. **Archive doc/tmp/ legacy templates**:
   - Move doc/tmp/MICROSERVICENAME-microservice-canvas.md → doc/internal/archive/legacy/retisio-canvas-templates/
   - Move doc/tmp/WEBAPPNAME-webapp-canvas.md → doc/internal/archive/legacy/retisio-canvas-templates/
   - Move doc/tmp/PRODUCTNAME-product-canvas.md → doc/internal/archive/legacy/retisio-canvas-templates/
   - Move doc/tmp/MICROFRONTENDNAME-microfrontend-canvas.md → doc/internal/archive/legacy/retisio-canvas-templates/
   - Add README.md in archive/legacy/ explaining these are from previous project

2. **Create doc/internal/working/** directory:
   - For temporary working documents
   - Add README.md explaining purpose and cleanup policy

3. **Remove doc/tmp/** directory (after migration):
   - No longer needed
   - Confusing "tmp" at doc/ root level

**Status Markers**:
- Add status frontmatter to all archived legacy templates
- Verify SERVICE-CANVAS.md has clear "Active Template" status

### Ongoing Maintenance

**Quarterly Review**:
- Review doc/internal/working/ for cleanup
- Delete documents unused > 90 days
- Promote useful documents to permanent location

**Template Updates**:
- When updating templates, document changes in template changelog
- Update "Last Updated" date
- If major changes, consider versioning (e.g., SERVICE-CANVAS-v2.md supersedes v1)

**New Template Creation**:
- Create in doc/internal/templates/
- Add status frontmatter
- Reference from governance document
- Create example in doc/internal/examples/ when first used

## Alternatives Considered

### Alternative 1: Leave doc/tmp/ as-is

**Description**: Accept doc/tmp/ with mixed content

**Pros**:
- No work required
- No file moves

**Cons**:
- Confusing which templates are authoritative
- Legacy templates may be used accidentally
- No clear organization
- Cluttered repository

**Reason for rejection**: Clarity and safety require proper organization

### Alternative 2: Delete All Legacy Content

**Description**: Delete doc/tmp/ entirely without archiving

**Pros**:
- Clean slate
- No legacy clutter

**Cons**:
- Lose historical context
- May need reference to legacy formats later
- Git history insufficient for context

**Reason for rejection**: Preserve history for reference; archive better than delete

### Alternative 3: Single "templates/" Directory

**Description**: Put all templates (active, examples, legacy) in one directory

**Pros**:
- Simple structure
- Everything in one place

**Cons**:
- Hard to distinguish authoritative vs reference vs legacy
- Risk of using wrong template
- No clear organization

**Reason for rejection**: Need clear separation of concerns

### Alternative 4: No Status Markers

**Description**: Organize by directory only, no status frontmatter

**Pros**:
- Less documentation overhead
- Simpler files

**Cons**:
- Unclear at file level what status is
- Must remember directory meanings
- Hard to validate status programmatically

**Reason for rejection**: Explicit status markers improve clarity

## Consequences

### Positive

- **Clarity**: Immediately obvious which templates are authoritative
- **Safety**: Prevents accidental use of outdated templates
- **Organization**: Clean, logical directory structure
- **History**: Legacy content preserved for reference
- **Maintainability**: Clear criteria for what belongs where
- **Scalability**: Structure supports project growth

### Negative

- **Initial Work**: Must migrate doc/tmp/ content
- **Discipline**: Must maintain status markers
- **File Paths**: Some paths change (doc/tmp → archive/legacy)

### Neutral

- **Git History**: File moves preserve history with git mv
- **Directory Count**: More directories but clearer purpose

## Implementation

### Step 1: Create New Directories

```bash
mkdir -p doc/internal/working/research-notes
mkdir -p doc/internal/working/drafts
mkdir -p doc/internal/archive/legacy/retisio-canvas-templates
```

### Step 2: Add README Files

Create `doc/internal/working/README.md`:
```markdown
# Working Documents Directory

**Purpose**: Temporary workspace for drafts, research notes, and work-in-progress documents.

**Policy**:
- Documents here are NOT authoritative
- Subject to cleanup (90-day retention for unused files)
- Promote useful documents to permanent locations
- Delete when no longer needed

**Structure**:
- research-notes/: Research and investigation notes
- drafts/: Document drafts before finalization

**Note**: Do not reference documents in this directory from governance or permanent documentation.
```

Create `doc/internal/archive/legacy/README.md`:
```markdown
# Legacy Documentation Archive

**Purpose**: Preserves templates and documentation from previous projects for reference.

**Authority**: Reference only - NOT for use in TJMPaaS

**Contents**:
- retisio-canvas-templates/: Canvas templates from previous RETISIO project

**Note**: These documents are preserved for historical context. For TJMPaaS templates, see `doc/internal/templates/`.
```

Create `doc/internal/archive/legacy/retisio-canvas-templates/README.md`:
```markdown
# RETISIO Canvas Templates (Legacy)

**Status**: Legacy - Previous Project  
**Authority**: Reference Only - NOT for TJMPaaS Use  
**Origin**: RETISIO project  
**Archived**: 2025-11-26

These canvas templates are from a previous project and are preserved for reference only.

**For TJMPaaS**, use: `doc/internal/templates/SERVICE-CANVAS.md`

## Files

- MICROSERVICENAME-microservice-canvas.md: Microservice canvas template
- WEBAPPNAME-webapp-canvas.md: Web app canvas template  
- PRODUCTNAME-product-canvas.md: Product canvas template
- MICROFRONTENDNAME-microfrontend-canvas.md: Microfrontend canvas template

## Why Archived

TJMPaaS has adopted a unified Service Canvas format (PDR-0006) that supersedes these templates. These are preserved for:
- Historical reference
- Understanding previous project patterns
- Potential inspiration for future enhancements

## Do Not Use

⚠️ **Warning**: Do NOT use these templates for new TJMPaaS services. Use `SERVICE-CANVAS.md` from templates directory.
```

### Step 3: Add Status Markers to Legacy Templates

Add to top of each legacy template in doc/tmp/:
```markdown
---
**Status**: Legacy - Previous Project  
**Authority**: Reference Only - NOT for TJMPaaS Use  
**Origin**: RETISIO project  
**Superseded By**: [SERVICE-CANVAS.md](../../internal/templates/SERVICE-CANVAS.md)  
**Last Updated**: [Original date if known]  
**Archived**: 2025-11-26  
---

⚠️ **DEPRECATED**: This template is from a previous project. For TJMPaaS, use [SERVICE-CANVAS.md](../../internal/templates/SERVICE-CANVAS.md).

---
```

### Step 4: Move Files

```bash
# Move legacy templates to archive
git mv doc/tmp/MICROSERVICENAME-microservice-canvas.md doc/internal/archive/legacy/retisio-canvas-templates/
git mv doc/tmp/WEBAPPNAME-webapp-canvas.md doc/internal/archive/legacy/retisio-canvas-templates/
git mv doc/tmp/PRODUCTNAME-product-canvas.md doc/internal/archive/legacy/retisio-canvas-templates/
git mv doc/tmp/MICROFRONTENDNAME-microfrontend-canvas.md doc/internal/archive/legacy/retisio-canvas-templates/

# Remove empty doc/tmp/ directory
rmdir doc/tmp
```

### Step 5: Move SERVICE-CANVAS.md to Governance Templates

Move SERVICE-CANVAS.md to governance area for consistency:
```bash
mkdir -p doc/internal/governance/templates
mv doc/internal/templates/SERVICE-CANVAS.md doc/internal/governance/templates/
```

Update `doc/internal/governance/templates/SERVICE-CANVAS.md` to ensure clear status:
```markdown
---
**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-26  
**Governance**: [PDR-0006: Service Canvas Documentation Standard](../governance/PDRs/PDR-0006-service-canvas-standard.md)  
---
```

### Step 6: Create TEMPLATES-GUIDE.md

Create master template index:
```bash
# See doc/internal/TEMPLATES-GUIDE.md
```

Index documents:
- All template locations (co-located with usage context)
- Usage instructions per template type
- Copilot discovery behavior explanation
- Rationale for co-location strategy

### Step 7: Update Documentation

Update `.github/copilot-instructions.md` to reference this PDR:
- Note the doc/internal/ directory structure
- Document template co-location strategy
- Reference TEMPLATES-GUIDE.md for template index
- Reference PDR-0007 for asset management

## Validation

Success criteria:

- doc/tmp/ no longer exists
- Legacy templates clearly marked and archived
- doc/internal/working/ created with README
- doc/internal/archive/legacy/ organized with READMEs
- All templates have status markers
- No confusion about which templates to use

Metrics:
- Zero references to doc/tmp/ in active documentation
- All templates have status frontmatter
- README files explain each directory's purpose

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Breaking links to doc/tmp/ | Low | Check for references; update if found |
| Git history confusion | Low | Use git mv to preserve history |
| Accidentally using legacy templates | Low | Clear status markers and warnings |
| Cleanup too aggressive | Low | 90-day retention; review before delete |

## Related Decisions

- [PDR-0003: Governance Document Lifecycle](./PDR-0003-governance-document-lifecycle.md) - Archival patterns
- [PDR-0006: Service Canvas Documentation Standard](./PDR-0006-service-canvas-standard.md) - Authoritative template
- [PDR-0001: Documentation Standards](./PDR-0001-documentation-standards.md) - Documentation organization

## References

- [How to organize documentation](https://documentation.divio.com/) - Documentation system
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) - Organization principles

## Notes

**Why Not Delete Legacy Templates?**

Preserving legacy templates provides:
- Historical context for design evolution
- Reference for alternative approaches
- Institutional knowledge preservation
- Potential inspiration for future enhancements

**Why Separate working/ from archive/?**

- **working/**: Active temporary documents, subject to cleanup
- **archive/**: Permanent preservation of historical content

Different purposes, different retention policies.

**Why Status Markers?**

Explicit status at file level:
- Works regardless of directory
- Searchable and programmatically verifiable
- Survives file moves
- Clear to anyone opening the file

**Template Authority and Co-Location**

Only templates with "Active Template" status listed in TEMPLATES-GUIDE.md are authoritative for TJMPaaS.

**Co-Location Strategy**: Templates are located near their usage context (e.g., ADR-TEMPLATE.md in ADRs/ directory) for optimal Copilot discoverability. This maintains DRY principles (single template per type) while improving AI assistant effectiveness.

**TEMPLATES-GUIDE.md**: Master index provides map of all template locations for human discoverability.

Everything else is reference or legacy.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |

---

**Note**: This PDR establishes documentation asset management for TJMPaaS. Apply these standards to all non-service documentation assets.
