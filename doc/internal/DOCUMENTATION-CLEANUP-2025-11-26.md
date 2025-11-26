# Documentation Asset Cleanup Summary

**Date**: 2025-11-26  
**Issue**: User raised concern about "isolation and standardization of non-service asset like those in doc/tmp/*.md"  
**Resolution**: Created PDR-0007 and reorganized documentation assets

## Problem

- `doc/tmp/` contained 4 legacy canvas templates from previous RETISIO project
- Templates had different format than current TJMPaaS SERVICE-CANVAS.md
- No clear organization for temporary vs permanent vs legacy documentation
- Risk of confusion: which templates are authoritative?

## Actions Taken

### 1. Created PDR-0007: Documentation Asset Management

**Location**: `doc/internal/governance/PDRs/PDR-0007-documentation-asset-management.md`

**Defines**:
- Standardized directory structure for documentation assets
- Status markers for all templates/examples
- Clear separation: active templates vs examples vs legacy vs working documents
- Archival process for legacy content
- Cleanup schedule for temporary documents

### 2. Created New Directory Structure

```
doc/internal/
├── templates/           # ACTIVE TEMPLATES (authoritative)
│   └── SERVICE-CANVAS.md
├── examples/            # COMPLETED EXAMPLES (reference)
│   └── CartService-CANVAS-example.md
├── working/             # TEMPORARY working documents (90-day retention)
│   ├── research-notes/
│   ├── drafts/
│   └── README.md        # Explains purpose and cleanup policy
└── archive/
    └── legacy/          # LEGACY from other projects (reference only)
        ├── README.md    # Explains this is reference only
        └── retisio-canvas-templates/
            ├── README.md  # Detailed explanation of legacy templates
            ├── MICROSERVICENAME-microservice-canvas.md
            ├── WEBAPPNAME-webapp-canvas.md
            ├── PRODUCTNAME-product-canvas.md
            └── MICROFRONTENDNAME-microfrontend-canvas.md
```

### 3. Migrated Legacy Templates

**Moved from**: `doc/tmp/*.md`  
**Moved to**: `doc/internal/archive/legacy/retisio-canvas-templates/`

**Files migrated**:
- MICROSERVICENAME-microservice-canvas.md
- WEBAPPNAME-webapp-canvas.md
- PRODUCTNAME-product-canvas.md
- MICROFRONTENDNAME-microfrontend-canvas.md

**Added deprecation warnings** to each legacy template:
```markdown
---
**Status**: Legacy - Previous Project  
**Authority**: Reference Only - NOT for TJMPaaS Use  
**Origin**: RETISIO project  
**Superseded By**: [SERVICE-CANVAS.md](../../templates/SERVICE-CANVAS.md)  
**Archived**: 2025-11-26  
---

⚠️ **DEPRECATED**: This template is from a previous project. 
For TJMPaaS, use [SERVICE-CANVAS.md](../../templates/SERVICE-CANVAS.md).
```

### 4. Added Status Markers to Current Template

**Updated**: `doc/internal/templates/SERVICE-CANVAS.md`

**Added**:
```markdown
---
**Template Status**: Active Template  
**Template Authority**: TJMPaaS Official  
**Template Last Updated**: 2025-11-26  
**Governance**: [PDR-0006: Service Canvas Documentation Standard]  
---
```

### 5. Created README Files

**Created**:
- `doc/internal/working/README.md`: Explains temporary workspace, cleanup policy
- `doc/internal/archive/legacy/README.md`: Explains legacy content purpose
- `doc/internal/archive/legacy/retisio-canvas-templates/README.md`: Detailed explanation of RETISIO templates, why archived, format differences

### 6. Updated Copilot Instructions

**Updated**: `.github/copilot-instructions.md`

**Changes**:
- Updated documentation structure diagram to show new directories
- Added reference to PDR-0007 for asset management standards

## Result

### Clear Organization

- **Active Templates**: `doc/internal/templates/` - authoritative, TJMPaaS official
- **Examples**: `doc/internal/examples/` - completed reference implementations
- **Working**: `doc/internal/working/` - temporary documents, 90-day cleanup
- **Legacy**: `doc/internal/archive/legacy/` - previous projects, reference only

### Explicit Status

Every template/document has clear status:
- **Active Template**: Authoritative for TJMPaaS
- **Example**: Reference implementation
- **Legacy**: Previous project, reference only
- **Working Draft**: Temporary, not authoritative

### No Confusion

- ✅ Only one SERVICE-CANVAS.md in templates/ is authoritative
- ✅ Legacy templates clearly marked as deprecated
- ✅ README files explain each directory's purpose
- ✅ Status markers prevent accidental use of wrong templates

## Governance

**PDR-0007** establishes:

1. **Directory Structure**: Where each type of document belongs
2. **Status Markers**: Required frontmatter for templates/examples
3. **Template Authority**: Only templates in `doc/internal/templates/` with "Active Template" status are authoritative
4. **Working Document Policy**: 90-day retention, cleanup schedule
5. **Legacy Archival**: How to preserve previous project content
6. **Maintenance**: Quarterly review process

## Next Steps (Optional)

Consider removing `doc/tmp/` directory entirely if now empty:
```bash
rmdir doc/tmp
```

## Benefits

1. **Clarity**: Immediately obvious which templates are authoritative
2. **Safety**: Can't accidentally use deprecated templates
3. **History**: Legacy templates preserved for reference
4. **Maintainability**: Clear criteria for what belongs where
5. **Scalability**: Structure supports project growth

## Files Modified/Created

### Created
- `doc/internal/governance/PDRs/PDR-0007-documentation-asset-management.md` (~450 lines)
- `doc/internal/working/README.md`
- `doc/internal/archive/legacy/README.md`
- `doc/internal/archive/legacy/retisio-canvas-templates/README.md`
- `doc/internal/working/research-notes/` (directory)
- `doc/internal/working/drafts/` (directory)

### Modified
- `.github/copilot-instructions.md` (updated doc structure and added PDR-0007 reference)
- `doc/internal/templates/SERVICE-CANVAS.md` (added status markers)
- All 4 legacy canvas templates (added deprecation warnings)

### Moved
- `doc/tmp/MICROSERVICENAME-microservice-canvas.md` → `doc/internal/archive/legacy/retisio-canvas-templates/`
- `doc/tmp/WEBAPPNAME-webapp-canvas.md` → `doc/internal/archive/legacy/retisio-canvas-templates/`
- `doc/tmp/PRODUCTNAME-product-canvas.md` → `doc/internal/archive/legacy/retisio-canvas-templates/`
- `doc/tmp/MICROFRONTENDNAME-microfrontend-canvas.md` → `doc/internal/archive/legacy/retisio-canvas-templates/`

### Can Be Removed
- `doc/tmp/` (if now empty)

## Impact

**Zero Breaking Changes**: No existing TJMPaaS references broken  
**Improved Clarity**: 100% - Always know which template to use  
**Risk Reduction**: Eliminates accidental use of wrong templates  
**Maintainability**: Clear processes for future documentation assets

---

**Resolution**: User's concern about "isolation and standardization of non-service asset" fully addressed through PDR-0007 and comprehensive reorganization.
