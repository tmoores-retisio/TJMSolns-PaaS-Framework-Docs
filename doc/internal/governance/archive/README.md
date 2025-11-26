# Governance Document Archive

This directory contains archived governance documents (ADRs, PDRs, POLs) that have been superseded or deprecated. These documents are preserved for historical reference and audit trail purposes.

## Purpose

The archive serves to:
- Preserve decision history
- Maintain audit trail
- Enable understanding of decision evolution
- Support compliance requirements
- Keep active directories focused on current guidance

## Archive Policy

Documents are moved to archive when:
- **Superseded**: Immediately upon acceptance of superseding document
- **Deprecated**: After 90 days in deprecated state OR when replaced
- **Rejected** (optional): If historically valuable

See [PDR-0003: Governance Document Lifecycle](../PDRs/PDR-0003-governance-document-lifecycle.md) for complete archival process.

## Structure

```text
archive/
├── README.md      # This file
├── ADRs/          # Archived Architectural Decision Records
├── PDRs/          # Archived Process Decision Records
└── POLs/          # Archived Policies
```

## Using Archived Documents

### Finding Archived Documents

Archived documents are indexed below and linked from:
- Superseding documents (in "Supersedes" section)
- Original active directory README (with archive reference)
- This archive index

### Referencing Archived Documents

When referencing archived documents:
- Note that document is archived
- Link to archive location
- Reference superseding document if applicable
- Explain historical context

Example:
> Originally decided in [ADR-0001 (archived)](./archive/ADRs/ADR-0001-title.md), 
> now superseded by [ADR-0005](./ADRs/ADR-0005-title.md).

### Document Immutability

Archived documents are **immutable** and must not be modified except for:
- Adding superseded-by references
- Updating archive location references
- Fixing broken links

See [PDR-0003](../PDRs/PDR-0003-governance-document-lifecycle.md) for complete immutability rules.

## Archive Indexes

### Archived ADRs

| ADR # | Title | Original Date | Archive Date | Reason | Superseded By |
|-------|-------|---------------|--------------|--------|---------------|
| -     | -     | -             | -            | -      | -             |

*No ADRs archived yet.*

### Archived PDRs

| PDR # | Title | Original Date | Archive Date | Reason | Superseded By |
|-------|-------|---------------|--------------|--------|---------------|
| -     | -     | -             | -            | -      | -             |

*No PDRs archived yet.*

### Archived POLs

| Category | Policy | Effective Date | Archive Date | Reason | Superseded By |
|----------|--------|----------------|--------------|--------|---------------|
| -        | -      | -              | -            | -      | -             |

*No policies archived yet.*

## Maintenance

### Archive Curator Responsibilities

The archive curator (Tony Moores) is responsible for:
- Moving documents to archive following superseding/deprecation
- Updating archive indexes
- Ensuring cross-references remain valid
- Verifying document immutability respected
- Organizing archive for easy reference

### Archive Organization

Documents in archive:
- Retain original filename
- Retain all original content (immutable)
- Include updated status and superseded-by references
- Maintain original structure and formatting

### Periodic Review

Archive reviewed:
- **Quarterly**: Verify organization and cross-references
- **Annually**: Assess if archive structure still appropriate
- **When compliance requires**: Support audit requests

## Related Documents

- [PDR-0003: Governance Document Lifecycle](../PDRs/PDR-0003-governance-document-lifecycle.md) - Defines lifecycle and archival process
- [PDR-0002: Governance Decision Framework](../PDRs/PDR-0002-governance-framework.md) - Defines governance framework
- [Governance README](../README.md) - Overview of governance structure

## Notes

This archive is not a graveyard—it's a living history. Archived documents provide context for current decisions and demonstrate how thinking evolved. They're valuable resources for understanding why we do things the way we do them now.

When in doubt, preserve history. Archive documents rather than delete them.
