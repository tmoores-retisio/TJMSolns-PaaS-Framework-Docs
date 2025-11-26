# PDR-0001: Documentation Structure and Standards

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Affects**: All project documentation, development workflow

## Context

TJMPaaS adopts a documentation-first approach (ADR-0002). This PDR defines the specific structure, standards, and processes for creating and maintaining that documentation.

### Current State

- Project initialized with basic README
- Initial thoughts captured in `initial-thoughts.md`
- Need formal documentation structure

### Challenges

- Solo developer needs sustainable documentation process
- Must support multiple document types (technical, process, policy)
- Need to maintain DRY principle (single source of truth)
- Structure must scale as project grows
- Documentation must be knowledge-base ready

### Objectives

- Establish clear documentation structure
- Define markdown standards
- Implement DRY principle
- Create sustainable documentation workflow
- Support future knowledge-base conversion

## Decision

Adopt the following documentation structure and standards:

### Directory Structure

```text
doc/
├── external/              # Public-facing documentation
└── internal/
    ├── CHARTER.md         # Project mission and scope
    ├── ROADMAP.md         # Timeline and milestones
    ├── initial-thoughts.md # Historical reference (immutable)
    ├── audit/             # Conversation logs and session summaries
    │   └── sessions/      # Dated work sessions
    ├── governance/
    │   ├── ADRs/          # Architectural Decision Records
    │   ├── PDRs/          # Process Decision Records
    │   └── POLs/          # Policies
    ├── architecture/      # System design docs
    ├── services/          # Service-specific documentation
    └── operations/        # Operational procedures
```

### Markdown Standards

All documentation must:
1. Follow markdown best practices and common linting rules
2. Use proper heading hierarchy (h1 → h2 → h3)
3. Include relative links for internal references
4. Use code blocks with language specification
5. Include frontmatter where helpful (date, author, status)
6. Follow DRY principle strictly

### Document Organization

1. **One Topic Per File**: Each file addresses single topic/purpose
2. **Descriptive Names**: Use clear, topic-based file/folder names
3. **Hierarchical**: Organize in directories by topic/purpose
4. **Cross-Reference**: Complex topics may reference other files
5. **Refactor**: Periodically adjust structure as complexity grows

### Key Document Types

| Type | Purpose | Location | Naming |
|------|---------|----------|--------|
| ADR | Architectural decisions | `governance/ADRs/` | `ADR-NNNN-title.md` |
| PDR | Process decisions | `governance/PDRs/` | `PDR-NNNN-title.md` |
| POL | Policies | `governance/POLs/` | `POL-category-name.md` |
| Session Summary | Work session logs | `audit/sessions/` | `YYYY-MM-DD-topic.md` |
| Service Docs | Service details | `services/service-name/` | Multiple files |
| Architecture | System design | `architecture/` | Topic-based |
| Operations | Procedures | `operations/` | Topic-based |

## Rationale

### DRY Principle

Single source of truth:
- Reduces maintenance burden
- Eliminates conflicting information
- Makes refactoring manageable
- Supports knowledge-base requirements

### Hierarchical Structure

Topic-based organization:
- Intuitive navigation
- Scales with complexity
- Supports refactoring
- Clear ownership of content

### Markdown Choice

Text-based format:
- Version control friendly
- Works with any editor
- No proprietary formats
- AI-friendly (Copilot can help)
- Export/import friendly
- Fast and lightweight

### Governance Separation

Distinct document types:
- ADRs: Technical decisions and rationale
- PDRs: Process and workflow decisions
- POLs: Enforceable standards and rules
- Clear purpose for each type

### Audit Trail

Session summaries:
- Capture decision context
- Enable project history reconstruction
- Support knowledge transfer
- Provide documentation narrative

## Process Description

### Overview

Documentation is created and maintained as an integral part of development workflow, not as an afterthought.

### Creating New Documentation

#### Step 1: Identify Documentation Need

When to document:
- Making architectural decision → ADR
- Establishing process → PDR
- Creating policy/standard → POL
- Completing significant work → Session Summary
- Creating service → Service documentation
- Designing architecture → Architecture docs

#### Step 2: Choose Document Type and Location

Use decision tree:
- Technical decision about system? → ADR in `governance/ADRs/`
- Process or workflow decision? → PDR in `governance/PDRs/`
- Mandatory standard/rule? → POL in `governance/POLs/`
- Work session log? → Session summary in `audit/sessions/`
- Service-specific? → Service docs in `services/service-name/`
- System design? → Architecture in `architecture/`
- Operational procedure? → Operations in `operations/`

#### Step 3: Use Template

- Copy appropriate template from governance folder
- Use GitHub Copilot to help fill in sections
- Follow template structure

#### Step 4: Apply Standards

Ensure:
- Proper markdown syntax
- Clear heading hierarchy
- Relative links for references
- Code blocks with language tags
- Follows DRY (check for duplication)

#### Step 5: Update Indexes

- Update relevant README.md files
- Update cross-references
- Link from related documents

### Maintaining Documentation

#### Regular Maintenance

- **Weekly**: Review recent changes, ensure docs updated
- **Monthly**: Check for stale documentation
- **Quarterly**: Review and refactor structure if needed

#### When Code Changes

- Update affected documentation
- Note in commit message
- Create ADR/PDR if decision changed

#### When Superseding Decisions

- Don't delete old ADRs/PDRs
- Mark as "Superseded"
- Link to new decision
- Preserve historical context

### Documentation Review

Tony reviews all documentation:
- Before committing
- During quarterly reviews
- When structure feels cumbersome

### Roles and Responsibilities

| Role | Responsibilities |
|------|-----------------|
| Tony (Owner) | Create, review, approve all documentation; maintain structure; enforce standards |
| GitHub Copilot | Assist with documentation creation; enforce standards; prompt for documentation |

### Tools and Resources

- **Editor**: VS Code
- **AI Assistant**: GitHub Copilot (with project instructions)
- **Linting**: Markdown linting extensions
- **Version Control**: Git/GitHub
- **Templates**: In `governance/*/TEMPLATE.md`

## Alternatives Considered

### Alternative 1: Flat Structure

**Description**: All docs in single directory

**Pros**:
- Simple
- Easy to find files
- No nesting complexity

**Cons**:
- Doesn't scale
- Poor organization
- Violates DRY (hard to manage references)
- Not knowledge-base friendly

**Reason for rejection**: Doesn't support project scale or knowledge-base goals

### Alternative 2: By Date Structure

**Description**: Organize by creation date

**Pros**:
- Chronological history
- Clear timeline

**Cons**:
- Hard to find by topic
- Doesn't support DRY
- Poor for reference docs
- Not intuitive navigation

**Reason for rejection**: Works for blog, not for knowledge base

### Alternative 3: By Author Structure

**Description**: Organize by document creator

**Pros**:
- Clear ownership

**Cons**:
- Solo project makes this pointless
- Topic-based search harder
- Not scalable

**Reason for rejection**: Inappropriate for solo developer

## Consequences

### Expected Benefits

- **Consistency**: All docs follow same standards
- **Discoverability**: Clear structure makes docs easy to find
- **Maintainability**: DRY and structure make updates manageable
- **Knowledge Base**: Structure supports future KB conversion
- **Onboarding**: New contributors can understand system
- **Quality**: Standards maintain high-quality documentation

### Potential Challenges

- **Learning Curve**: Structure takes time to learn
- **Discipline**: Requires consistent application
- **Refactoring**: May need structure adjustments as project grows
- **Over-Engineering**: Risk of excessive structure

### Required Changes

- Adhere to structure for all new documentation
- Use templates consistently
- Update indexes when adding documents
- Refactor periodically to maintain organization

## Implementation

### Rollout Plan

1. ✅ Create directory structure
2. ✅ Create templates for each document type
3. ✅ Document standards in this PDR
4. ✅ Update Copilot instructions
5. 🔄 Seed initial governance documents
6. 🔜 Apply to all future documentation

### Training Needs

- Review this PDR
- Understand document type purposes
- Practice using templates
- Learn markdown best practices

### Timeline

- **2025-11-26**: Standards established
- **Ongoing**: Apply to all documentation

### Success Criteria

- All docs follow structure
- No orphaned or misplaced documents
- DRY principle maintained
- Easy to find relevant documentation
- Quarterly reviews show structure scales appropriately

## Monitoring and Review

### Metrics

- Documentation coverage (% of decisions documented)
- Time to find relevant documentation
- Number of stale documents
- Structure refactorings needed

### Review Schedule

- **Weekly**: Quick check during development
- **Monthly**: Documentation audit
- **Quarterly**: Structure review and refactoring

### Adjustment Triggers

Revise structure when:
- Hard to find documents consistently
- Significant duplication appears
- New document types needed
- Feedback indicates confusion

## Related Decisions

- [ADR-0002: Documentation-First Approach](../ADRs/ADR-0002-documentation-first-approach.md) - Why we document comprehensively
- [PDR-0002: Governance Decision Framework](./PDR-0002-governance-framework.md) - When to create which document type
- [Initial Thoughts](../../initial-thoughts.md) - Original documentation vision

## References

- [Markdown Guide](https://www.markdownguide.org/)
- [DRY Principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
- [Architecture Decision Records](https://adr.github.io/)

## Notes

This structure balances:
- Organization vs. simplicity
- Structure vs. flexibility
- Solo developer needs vs. future team needs
- Current scale vs. future growth

The key is maintaining discipline while allowing periodic refactoring to optimize as the project evolves.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
