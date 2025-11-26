# PDR-0003: Governance Document Lifecycle and Immutability

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Affects**: All governance documents (ADRs, PDRs, POLs)

## Context

TJMPaaS governance documents (ADRs, PDRs, POLs) serve as historical records of decisions. The immutability and lifecycle management of these documents impacts:

- Decision traceability and audit trail
- Historical accuracy and integrity
- Ability to understand decision evolution
- Compliance and accountability
- Knowledge transfer effectiveness

### Current State

- Governance framework established (PDR-0002)
- Initial documents created
- Need clarity on document lifecycle
- Need archival process

### Challenges

- Documents may need correction (typos, formatting)
- Decisions may need to evolve or be reversed
- Must preserve historical record
- Need clear distinction between corrections vs. changes
- Archive management needed

### Objectives

- Establish clear immutability rules
- Define what constitutes "material change"
- Create archival process
- Maintain decision history integrity
- Enable decision evolution without losing history

## Decision

**Governance documents (ADRs, PDRs, POLs) are immutable historical records once accepted.** Material changes require new documents that supersede originals. Deprecated or superseded documents move to archive with preserved content and updated status.

### Document Immutability Rules

#### Acceptable Changes (Minor Corrections)

The following changes MAY be made to accepted documents:

1. **Typo Corrections**: Spelling, grammar fixes
2. **Formatting**: Markdown formatting improvements
3. **Broken Links**: Updating links that have moved
4. **Clarifications**: Adding notes that don't change decision
5. **Status Updates**: Updating status field (Accepted → Deprecated/Superseded)
6. **Revision History**: Adding entries to revision history table
7. **Cross-References**: Adding links to related or superseding documents

These changes must NOT alter the substance of the decision, rationale, or consequences.

#### Material Changes (Require New Document)

The following changes REQUIRE creating a new superseding document:

1. **Decision Change**: Different technical or process choice
2. **Rationale Change**: Significant change in reasoning
3. **Scope Change**: Expanding or narrowing what decision covers
4. **Requirements Change**: Different mandatory requirements (POLs)
5. **Alternatives Re-evaluation**: Choosing previously rejected alternative
6. **Consequences Update**: Significantly different outcomes than predicted

When material change needed:
1. Create new document with next sequential number
2. Document what changed and why in new document
3. Update original document status to "Superseded"
4. Add cross-reference in both documents
5. Move original to archive

### Document Lifecycle

```
Draft → Proposed → Accepted → [Active Use] → Deprecated → Archived
                          ↓
                      Superseded → Archived
                          ↓
                      Rejected → (Optional Archive)
```

#### States

- **Draft**: Work in progress, not committed
- **Proposed**: Under review/consideration
- **Accepted**: Approved and active (ADRs, PDRs)
- **Active**: Enforced policy (POLs only)
- **Deprecated**: No longer recommended, not yet replaced
- **Superseded**: Replaced by newer document
- **Rejected**: Proposed but not adopted
- **Archived**: Moved to archive directory

#### Archival Triggers

Move to archive when status becomes:

- **Superseded**: Immediately upon superseding document acceptance
- **Deprecated**: After 90 days in deprecated state OR when replaced
- **Rejected** (optional): If valuable for historical context

### Archival Process

#### Step 1: Update Original Document

Before archiving, update the original document:

```markdown
**Status**: Superseded  
**Superseded By**: [ADR-NNNN: New Decision](../ADRs/ADR-NNNN-new-decision.md)  
**Superseded Date**: YYYY-MM-DD  
**Archive Location**: [Archived version](../archive/ADRs/ADR-OOOO-original.md)
```

Add note at top of document:

```markdown
> **⚠️ SUPERSEDED**: This decision has been superseded by [ADR-NNNN](link). 
> See the new decision for current guidance. This document is preserved for 
> historical reference.
```

#### Step 2: Move to Archive

```bash
# Move file to archive
mv doc/internal/governance/ADRs/ADR-NNNN-title.md \
   doc/internal/governance/archive/ADRs/ADR-NNNN-title.md

# Update indexes
# - Remove from active README index
# - Add to archive README index
```

#### Step 3: Update Cross-References

- Update indexes in README files
- Check related documents for references
- Update any links to archived document

#### Step 4: Document in Superseding Document

New document must include:

```markdown
## Supersedes

This decision supersedes [ADR-NNNN: Original Title](../archive/ADRs/ADR-NNNN-title.md).

### What Changed

[Explain what's different and why]

### Why Superseded

[Explain why original decision no longer appropriate]
```

### Archive Structure

```text
doc/internal/governance/
├── ADRs/              # Active architectural decisions
├── PDRs/              # Active process decisions
├── POLs/              # Active policies
└── archive/
    ├── README.md      # Archive index and explanation
    ├── ADRs/          # Archived architectural decisions
    ├── PDRs/          # Archived process decisions
    └── POLs/          # Archived policies
```

## Rationale

### Historical Integrity

Immutable documents ensure:
- Accurate historical record
- Audit trail preserved
- Context never lost
- Can understand "why we did it that way then"

### Decision Evolution

Superseding process enables:
- Decisions to evolve appropriately
- Clear lineage of decision changes
- Understanding of how thinking changed
- Learning from past decisions

### Compliance and Accountability

Document immutability supports:
- Audit requirements
- Compliance verification
- Accountability tracking
- Regulatory needs (future)

### Knowledge Management

Clear lifecycle helps:
- Distinguish active from historical
- Find current decisions quickly
- Understand decision evolution
- Onboard new team members

## Process Description

### Overview

Governance documents progress through defined lifecycle with clear rules for modifications, superseding, and archival.

### Making Minor Corrections

#### When Needed

- Typos discovered
- Broken links found
- Formatting improvements
- Clarifications needed

#### Process

1. Make correction directly in document
2. Add entry to Revision History table
3. Commit with message: `docs: fix [type] in [document]`
4. No status change needed

### Superseding a Decision

#### When Needed

- Decision no longer appropriate
- Better alternative identified
- Requirements changed
- Technology evolved
- Process not working

#### Process

1. **Draft New Document**:
   - Copy template for new document
   - Use next sequential number
   - Fill in all sections
   - Include "Supersedes" section explaining changes

2. **Reference Original**:
   - Link to original document
   - Explain what changed and why
   - Document why original approach insufficient

3. **Accept New Document**:
   - Review and approve new document
   - Commit new document

4. **Update Original**:
   - Change status to "Superseded"
   - Add superseded-by reference
   - Add warning note at top
   - Add archive location reference
   - Update revision history

5. **Archive Original**:
   - Move to archive directory
   - Update both README indexes (remove from active, add to archive)
   - Commit with message: `docs: archive [document] superseded by [new]`

6. **Verify Cross-References**:
   - Check for references in other documents
   - Update links to point to active or archived as appropriate

### Deprecating Without Replacement

#### When Appropriate

- Decision no longer applicable
- Technology no longer used
- Process discontinued
- Not yet replaced

#### Process

1. **Update Status**: Change to "Deprecated"
2. **Add Note**: Explain why deprecated
3. **Set Timer**: After 90 days OR when replaced, archive
4. **Archive**: Follow archival process when timer expires

### Handling Rejected Proposals

#### When to Archive

- Proposal has historical value
- Decision context valuable
- Alternatives considered useful reference

#### Process

1. Mark status as "Rejected"
2. Optionally move to archive immediately
3. Or leave in place if very recent

### Roles and Responsibilities

| Role | Responsibilities |
|------|-----------------|
| Document Author | Create new superseding documents; propose deprecation |
| Owner (Tony) | Approve superseding; execute archival; update indexes |
| Archive Curator (Tony) | Maintain archive organization; ensure cross-references correct |

### Tools and Resources

- Git for version control
- Standard archival commands (git mv)
- README index templates
- Archive README

## Alternatives Considered

### Alternative 1: Mutable Documents

**Description**: Allow documents to be edited in place with revision history

**Pros**:
- Simpler process
- Fewer documents
- All changes in one place

**Cons**:
- Historical context lost
- Hard to see decision evolution
- Audit trail unclear
- Can't reference "decision as of date X"

**Reason for rejection**: Loses historical integrity; defeats purpose of decision records

### Alternative 2: Version Numbers Instead of New Documents

**Description**: Use semantic versioning (v1.0, v2.0) for same document

**Pros**:
- Fewer files
- Same filename over time
- Clear version progression

**Cons**:
- Git history required to see old versions
- Can't easily reference specific version
- Confusing which version applies when
- Archive process unclear

**Reason for rejection**: Less clear than separate documents; harder to reference specific versions

### Alternative 3: Never Archive (Keep All in Active Directory)

**Description**: Mark as superseded but leave in main directory

**Pros**:
- Simpler (no moving files)
- All documents in one place
- Easier to browse all decisions

**Cons**:
- Active directory cluttered
- Hard to find current decisions
- Index becomes unwieldy
- No clear separation of active vs historical

**Reason for rejection**: Makes finding current guidance difficult; clutters active workspace

### Alternative 4: Delete Superseded Documents

**Description**: Remove superseded documents entirely

**Pros**:
- Clean active directory
- No confusion about what's current
- Simple process

**Cons**:
- History lost
- Can't understand decision evolution
- No audit trail
- Knowledge destroyed

**Reason for rejection**: Completely defeats purpose of decision records; unacceptable loss of history

## Consequences

### Expected Benefits

- **Historical Integrity**: Accurate record of decisions preserved
- **Clear Status**: Easy to identify current vs superseded
- **Audit Trail**: Complete decision history for compliance
- **Evolution Visibility**: Can trace how decisions changed over time
- **Knowledge Preservation**: Context never lost
- **Reduced Confusion**: Archive separates active from historical

### Potential Challenges

- **Process Overhead**: Archival process takes time
- **Discipline Required**: Must follow process consistently
- **Link Management**: Must update cross-references
- **Archive Growth**: Archive will grow over time (acceptable)

### Required Changes

- Create archive directory structure
- Update copilot instructions (completed)
- Follow immutability rules for all documents
- Execute archival process when superseding

## Implementation

### Rollout Plan

1. ✅ Define lifecycle and immutability rules (this PDR)
2. 🔄 Create archive directory structure
3. 🔜 Update existing documents with immutability notes
4. 🔜 Apply to all future governance documents

### Training Needs

- Review this PDR thoroughly
- Understand material vs minor changes
- Practice archival process
- Learn to write superseding documents

### Timeline

- **2025-11-26**: Lifecycle defined, archive structure created
- **Ongoing**: Apply immutability rules to all documents
- **As needed**: Execute superseding and archival processes

### Success Criteria

- All governance documents respect immutability
- Superseding documents properly reference originals
- Archive maintained with clear indexes
- Decision history traceable
- No confusion about current vs historical

## Monitoring and Review

### Metrics

- Number of superseding documents created
- Time from supersede to archive
- Completeness of cross-references
- Archive organization quality

### Review Schedule

- **Quarterly**: Ensure process followed consistently
- **Annually**: Evaluate if lifecycle still appropriate
- **When issues arise**: Refine process as needed

### Adjustment Triggers

Revise lifecycle when:
- Process proves too burdensome
- Archive becomes unmanageable
- Cross-referencing breaks down
- Compliance requirements change

## Related Decisions

- [PDR-0002: Governance Decision Framework](./PDR-0002-governance-framework.md) - Established governance framework this lifecycle applies to
- [PDR-0001: Documentation Standards](./PDR-0001-documentation-standards.md) - General documentation approach
- [ADR-0002: Documentation-First Approach](../ADRs/ADR-0002-documentation-first-approach.md) - Why documentation matters

## References

- [Architecture Decision Records](https://adr.github.io/)
- [Semantic Versioning](https://semver.org/) - Considered but rejected
- [Git Best Practices](https://git-scm.com/book/en/v2)

## Notes

This PDR itself is subject to the lifecycle it defines. If this process needs material change, a new PDR will supersede this one, and this PDR will move to archive with updated status.

The key principle: **governance documents are historical artifacts that must not be altered in ways that change their meaning**. We can correct mistakes, but we cannot rewrite history.

Think of governance documents like legal contracts or published papers—once accepted, they stand as written, and new versions are created to update or replace them.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
