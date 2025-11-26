# PDR-0002: Governance Decision Framework

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Affects**: All decision-making processes, documentation workflow

## Context

TJMPaaS uses a governance framework with three document types: ADRs (Architectural Decision Records), PDRs (Process Decision Records), and POLs (Policies). Clear guidelines are needed for:

- When to create each document type
- What belongs in each
- Approval and review processes
- How decisions evolve over time

### Current State

- Governance structure established
- Templates created
- Initial documents in progress
- Need process clarity

### Challenges

- Solo developer - need lightweight but effective governance
- Multiple decision types can create confusion
- Must balance rigor with agility
- Need clear triggers for documentation

### Objectives

- Clear criteria for document type selection
- Sustainable governance for solo developer
- Maintain decision quality and traceability
- Enable future team expansion

## Decision

Adopt the following governance decision framework:

### Document Type Selection

Use this decision tree to determine document type:

```
Is it a mandatory requirement/rule?
├─ YES → POL (Policy)
└─ NO → Is it about system/technical design?
          ├─ YES → ADR (Architectural Decision Record)
          └─ NO → Is it about process/workflow?
                    ├─ YES → PDR (Process Decision Record)
                    └─ NO → Consider if documentation needed
```

### Document Type Definitions

#### ADR (Architectural Decision Record)

**Use When**:
- Choosing technologies, frameworks, or platforms
- Defining system architecture or design patterns
- Making infrastructure decisions
- Selecting between technical alternatives
- Making decisions that affect system design

**Examples**:
- Cloud provider selection
- Database technology choice
- Container orchestration approach
- API design patterns
- Security architecture decisions

**Key Question**: "What technical approach will we use and why?"

#### PDR (Process Decision Record)

**Use When**:
- Establishing development workflows
- Defining operational procedures
- Changing team processes
- Adopting new methodologies
- Making decisions about how we work

**Examples**:
- Documentation structure
- Git branching strategy
- Code review process
- Deployment procedures
- Meeting cadences (when team expands)

**Key Question**: "How will we work and why?"

#### POL (Policy)

**Use When**:
- Establishing mandatory requirements
- Defining compliance obligations
- Setting quality gates
- Creating security standards
- Establishing enforceable rules

**Examples**:
- Security baseline requirements
- Code quality standards
- Data retention policies
- Access control rules
- Testing requirements

**Key Question**: "What MUST we do and why?"

### When Documentation Is Optional

Not everything needs formal governance documentation:

**Document When**:
- Decision has lasting impact
- Decision affects multiple services/components
- Need to explain rationale to future contributors
- Decision could be questioned or revisited
- Compliance or audit requirements

**Skip Documentation When**:
- Purely tactical implementation detail
- Decision easily reversible
- Impact limited to single small component
- Decision is obvious or standard practice
- Time-sensitive hotfix (document after if needed)

### Approval Process

#### Solo Developer Phase (Current)

- **Creator**: Tony
- **Reviewer**: Tony
- **Approver**: Tony
- **Process**: 
  1. Draft document using template
  2. Review for completeness and clarity
  3. Mark status as "Accepted"
  4. Commit to repository

#### Future Team Phase

When team expands:
- **ADRs**: Technical lead review + approval
- **PDRs**: Team discussion + consensus
- **POLs**: Owner approval (compliance implications)

### Status Lifecycle

Documents progress through statuses:

```
Proposed → Accepted → [Deprecated] → [Superseded]
         ↘ Rejected
```

- **Proposed**: Under consideration, seeking feedback
- **Accepted**: Approved and active
- **Deprecated**: No longer recommended, but not replaced
- **Superseded**: Replaced by newer decision (link to replacement)
- **Rejected**: Considered but not adopted (preserve rationale)

### Review Schedule

| Document Type | Review Frequency | Trigger Events |
|---------------|------------------|----------------|
| ADRs | Annually or when tech changes | Technology obsolescence, performance issues |
| PDRs | Quarterly | Process friction, team feedback |
| POLs | Annually or when regulations change | Compliance changes, security incidents |

## Rationale

### Clear Boundaries

Distinct document types prevent confusion:
- ADRs focus on "what we're building"
- PDRs focus on "how we're working"
- POLs focus on "what we must do"

### Lightweight but Rigorous

Solo developer process is lightweight:
- No multi-person approvals
- No meetings required
- But maintains discipline and traceability

### Evolution Support

Status lifecycle supports change:
- Decisions can be revisited
- Superseded decisions preserve history
- Deprecated decisions guide migration

### Future-Ready

Framework scales:
- Solo → team governance defined
- Can add review boards if needed
- Approval processes can formalize

## Process Description

### Overview

Governance documents are created when decisions warrant documentation, following a consistent process regardless of solo or team context.

### Creating Governance Documents

#### Step 1: Identify Decision

Recognize when a decision needs documentation using triggers and decision tree.

#### Step 2: Select Document Type

Use decision tree:
- Mandatory requirement → POL
- Technical design → ADR
- Process/workflow → PDR

#### Step 3: Draft Document

1. Copy appropriate template
2. Fill in all sections thoughtfully
3. Consider alternatives seriously
4. Document rationale clearly
5. Identify consequences honestly

#### Step 4: Review (Solo Phase)

Self-review checklist:
- [ ] All template sections completed
- [ ] Rationale is clear and compelling
- [ ] Alternatives genuinely considered
- [ ] Consequences realistic
- [ ] Related decisions linked
- [ ] References included
- [ ] Markdown standards followed

#### Step 5: Accept and Publish

1. Mark status as "Accepted"
2. Update relevant README index
3. Link from related documents
4. Commit with descriptive message

#### Step 6: Communicate

- Session summary if part of larger work
- Update ROADMAP if milestone achieved
- Update CHARTER if scope affected

### Revisiting Decisions

#### When to Revisit

- Technology obsolescence
- Performance problems
- Process friction
- Compliance changes
- Better alternatives emerge
- Business needs change

#### Process for Changing Decision

1. **Don't Edit Original**: Original decision is historical record
2. **Create New Document**: New ADR/PDR/POL superseding old one
3. **Update Original**: Mark as "Superseded" with link to new decision
4. **Explain Evolution**: New document explains what changed and why

### Roles and Responsibilities

#### Solo Developer Phase

| Role | Responsibilities |
|------|-----------------|
| Tony | Create, review, approve, maintain all governance documents |
| GitHub Copilot | Assist with creation; prompt when documentation needed; enforce standards |

#### Future Team Phase

| Role | Responsibilities |
|------|-----------------|
| Technical Lead | Review/approve ADRs |
| Team Members | Participate in PDR discussions |
| Owner | Approve POLs; final authority |

### Tools and Resources

- **Templates**: `doc/internal/governance/*/TEMPLATE.md`
- **Examples**: Initial ADRs, PDRs, POLs
- **Decision Tree**: Embedded in this document
- **Copilot**: Assists with document creation

## Alternatives Considered

### Alternative 1: Single Document Type

**Description**: Use only one type of decision document

**Pros**:
- Simpler
- No type selection needed
- Less to learn

**Cons**:
- Mixes concerns (technical, process, policy)
- Harder to find specific types
- Loses semantic meaning

**Reason for rejection**: Distinct types provide clarity and organization

### Alternative 2: Heavyweight Approval Process

**Description**: Require formal reviews even for solo developer

**Pros**:
- More rigorous
- Catches errors
- Practice for future team

**Cons**:
- Artificial for solo developer
- Slows down unnecessarily
- Can discourage documentation

**Reason for rejection**: Over-engineering for current needs; can evolve later

### Alternative 3: No Formal Framework

**Description**: Document decisions ad-hoc without framework

**Pros**:
- Maximum flexibility
- No overhead
- Fast

**Cons**:
- Inconsistent
- Hard to find decisions
- No clear triggers
- Poor governance

**Reason for rejection**: Defeats purpose of governance

### Alternative 4: Approval by Committee

**Description**: External review required for decisions

**Pros**:
- External perspective
- Error catching
- Accountability

**Cons**:
- Solo project makes this impractical
- Significant overhead
- Slows decisions

**Reason for rejection**: Inappropriate for solo developer

## Consequences

### Expected Benefits

- **Clarity**: Clear when to create each document type
- **Consistency**: All decisions follow same framework
- **Efficiency**: Lightweight process for solo developer
- **Scalability**: Framework supports team growth
- **Quality**: Thoughtful decision-making process
- **Traceability**: Clear decision history

### Potential Challenges

- **Overhead**: Documentation takes time
- **Discipline**: Easy to skip when rushed
- **Type Confusion**: May initially struggle with classification
- **Evolution**: Framework may need refinement

### Required Changes

- Follow decision tree for all decisions
- Use appropriate templates
- Update indexes when creating documents
- Review periodically

## Implementation

### Rollout Plan

1. ✅ Define framework in this PDR
2. ✅ Create initial governance documents
3. 🔜 Apply framework going forward
4. 🔜 Review quarterly for effectiveness

### Training Needs

- Review this PDR thoroughly
- Practice using decision tree
- Review template examples
- Understand status lifecycle

### Timeline

- **2025-11-26**: Framework established
- **Ongoing**: Applied to all decisions
- **Quarterly**: Framework reviewed

### Success Criteria

- All significant decisions documented
- Correct document type used consistently
- Decision history clear and traceable
- Framework feels sustainable
- Can onboard future team members using documents

## Monitoring and Review

### Metrics

- Number of governance documents created
- Time from decision to documentation
- Correct document type usage rate
- Frequency of revisiting decisions

### Review Schedule

- **Quarterly**: Framework effectiveness review
- **Annually**: Major framework assessment
- **When team grows**: Update approval processes

### Adjustment Triggers

Revise framework when:
- Consistent confusion about document types
- Process feels too heavy or too light
- Team expansion changes needs
- Compliance requirements change

## Related Decisions

- [ADR-0002: Documentation-First Approach](../ADRs/ADR-0002-documentation-first-approach.md) - Why we document
- [PDR-0001: Documentation Structure and Standards](./PDR-0001-documentation-standards.md) - How we organize docs
- [PDR-0003: Governance Document Lifecycle](./PDR-0003-governance-document-lifecycle.md) - Document immutability and archival
- [Governance README](../README.md) - Overview of governance framework

## References

- [Architecture Decision Records](https://adr.github.io/)
- [Decision Making Frameworks](https://en.wikipedia.org/wiki/Decision-making)

## Notes

This framework is intentionally lightweight for solo development while providing structure that scales. The key principle: **document decisions that matter, with appropriate rigor, using the right format**.

The decision tree and status lifecycle provide enough structure to maintain discipline without creating artificial bureaucracy.

As the project and team grow, this framework can evolve—adding approval boards, review meetings, or additional document types as needed. The foundation is solid and extensible.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
| 2025-11-26 | Added reference to PDR-0003 on document lifecycle | Tony Moores |

---

**Note**: This document is subject to immutability rules defined in [PDR-0003: Governance Document Lifecycle](./PDR-0003-governance-document-lifecycle.md). Material changes require a new superseding PDR.
