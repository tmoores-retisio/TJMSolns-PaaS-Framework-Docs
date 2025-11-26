# Governance-Feature Inference Map

**Purpose**: Track bidirectional relationships between architectural/process governance and implemented features

**Status**: Active - Phase 0 Complete  
**Last Updated**: 2025-11-26  
**Governance**: [PDR-0008: Feature Documentation Standard](./governance/PDRs/PDR-0008-feature-documentation-standard.md)

---

## Overview

This document tracks the **bidirectional inference relationship** between governance decisions (ADRs, PDRs, POLs) and service features:

- **Governance → Features**: Which features validate/prove this governance decision?
- **Features → Governance**: Which governance decisions does this feature require/invoke?

**Strategic Value**:
- ✅ **Living Governance**: Features validate that ADRs/PDRs/POLs work in practice (not just theory)
- ✅ **Feature Traceability**: Features show clear architectural justification (not ad-hoc)
- ✅ **Gap Detection**: Identifies orphaned governance (unused ADRs) or ungoverned features (missing ADRs)
- ✅ **Onboarding**: New developers see "how we apply decisions in real code"
- ✅ **Compliance**: Complete chain from decision → feature → code → test

---

## Governance → Features (What Features Validate This Decision?)

### Architectural Decisions (ADRs)

#### ADR-0004: Scala 3 Technology Stack

**Decision Summary**: Scala 3 with functional programming as primary stack

**Features That Validate This**:
- *To be documented in Phase 1 (Governance Inference Analysis)*
- Expected: All features use Scala 3, functional patterns (immutability, pure functions, effects)

**Validation Status**: ⏳ Pending Phase 1 Analysis

**Gap Assessment**: 
- **Orphaned?**: TBD in Phase 1 (if no features use Scala 3, ADR not validated)
- **Compliance**: TBD (% features following functional programming patterns)

---

#### ADR-0005: Reactive Manifesto Alignment

**Decision Summary**: Responsive, resilient, elastic, message-driven systems

**Features That Validate This**:
- *To be documented in Phase 1*
- Expected: Features with < 200ms p95 response times, non-blocking operations, backpressure handling

**Validation Status**: ⏳ Pending Phase 1 Analysis

**Gap Assessment**:
- **Responsive**: TBD (which features meet SLA?)
- **Resilient**: TBD (which features handle failures gracefully?)
- **Elastic**: TBD (which features scale horizontally?)
- **Message-Driven**: TBD (which features use actors/events?)

---

#### ADR-0006: Agent-Based Service Patterns (Actor Model)

**Decision Summary**: Use actor model for concurrency and state management

**Features That Validate This**:
- *To be documented in Phase 1*
- Expected: Stateful features (cart, order, session) use actors with supervision

**Validation Status**: ⏳ Pending Phase 1 Analysis

**Gap Assessment**:
- **Actor Usage**: TBD (which features use actors? which should but don't?)
- **Message Protocols**: TBD (are protocols type-safe and well-documented?)
- **Supervision**: TBD (are supervision strategies documented and tested?)

---

#### ADR-0007: CQRS and Event-Driven Architecture

**Decision Summary**: Separate command/query models, event sourcing, event-driven integration

**Features That Validate This**:
- *To be documented in Phase 1*
- Expected: Features declare CQRS maturity level (1/2/3), commands/queries separated, events published

**Validation Status**: ⏳ Pending Phase 1 Analysis

**Gap Assessment**:
- **CQRS Maturity**: TBD (how many features at each level? which need CQRS but don't have it?)
- **Event Sourcing**: TBD (which Level 3 features use event sourcing? audit trail complete?)
- **Event-Driven Integration**: TBD (which features publish/consume events? schemas versioned?)

---

### Process Decisions (PDRs)

#### PDR-0004: Repository Organization Strategy

**Decision Summary**: Multi-repo (one per service), TJMSolns-<ServiceName> naming

**Features That Validate This**:
- *To be documented in Phase 1*
- Expected: Each feature belongs to a service repo, features self-contained

**Validation Status**: ⏳ Pending Phase 1 Analysis

**Gap Assessment**:
- **Service Isolation**: TBD (do features cross service boundaries inappropriately?)
- **Repository Structure**: TBD (do service repos follow standard structure?)

---

#### PDR-0006: Service Canvas Documentation Standard

**Decision Summary**: SERVICE-CANVAS.md required for every service

**Features That Validate This**:
- *To be documented in Phase 1*
- Expected: All services have canvas, features section integrated

**Validation Status**: ⏳ Pending Phase 1 Analysis

**Gap Assessment**:
- **Canvas Completeness**: TBD (% services with canvas?)
- **Features Integration**: TBD (do canvases list features with status?)

---

#### PDR-0008: Feature Documentation Standard

**Decision Summary**: Feature documentation with BDD + technical .md files

**Features That Validate This**:
- *To be documented in Phase 2 (Core Service Features)*
- Expected: All documented features follow template structure

**Validation Status**: ⏳ Pending Phase 2 (first features being documented)

**Gap Assessment**:
- **Template Compliance**: TBD in Phase 2
- **Governance Cross-Refs**: TBD (do features reference applicable ADRs/PDRs/POLs?)

---

### Policies (POLs)

#### POL-security-baseline

**Decision Summary**: Security standards for authentication, authorization, data protection

**Features That Validate This**:
- *To be documented in Phase 1*
- Expected: All features handling sensitive data/operations comply with security baseline

**Validation Status**: ⏳ Pending Phase 1 Analysis

**Gap Assessment**:
- **Authentication**: TBD (which features require auth? implemented correctly?)
- **Authorization**: TBD (proper RBAC/ABAC enforcement?)
- **Data Protection**: TBD (PII encrypted? audit trails?)

---

## Features → Governance (What Governance Does This Feature Require?)

### CartService Features

#### Cart - Add Item

**Feature Summary**: *To be documented in Phase 2*

**Required Governance**:
- *To be documented when feature created*
- Expected: ADR-0006 (actor for cart state), ADR-0007 (command handling), POL-security (auth required)

**Governance Coverage**: ⏳ Pending Phase 2

**Inferred Missing Governance**: TBD (analysis in Phase 3)

---

#### Cart - Query Cart

**Feature Summary**: *To be documented in Phase 2*

**Required Governance**:
- *To be documented when feature created*
- Expected: ADR-0007 (query side), ADR-0005 (responsive < 100ms)

**Governance Coverage**: ⏳ Pending Phase 2

**Inferred Missing Governance**: TBD

---

#### Cart - Remove Item

**Feature Summary**: *To be documented in Phase 2*

**Required Governance**:
- *To be documented when feature created*

**Governance Coverage**: ⏳ Pending Phase 2

**Inferred Missing Governance**: TBD

---

#### Cart - Checkout

**Feature Summary**: *To be documented in Phase 2*

**Required Governance**:
- *To be documented when feature created*
- Expected: Saga pattern ADR (likely missing, will infer need in Phase 3)

**Governance Coverage**: ⏳ Pending Phase 2

**Inferred Missing Governance**: TBD (likely needs saga pattern ADR for distributed transaction)

---

#### Cart - Session Management

**Feature Summary**: *To be documented in Phase 2*

**Required Governance**:
- *To be documented when feature created*
- Expected: ADR-0006 (actor lifecycle), POL-session-security (likely missing)

**Governance Coverage**: ⏳ Pending Phase 2

**Inferred Missing Governance**: TBD (likely needs session security POL)

---

### OrderService Features

*To be documented in Phase 5 (Second Service Validation)*

---

## Gap Analysis

### Orphaned Governance (Decisions Without Features)

**Definition**: Governance documents (ADRs/PDRs/POLs) that are not validated by any implemented features

**Status**: ⏳ Analysis in Phase 1

**Process**:
1. Phase 1: Analyze each ADR/PDR/POL
2. Identify which should have features validating them
3. Flag orphaned governance (0 features)
4. Determine: Is governance premature? Or are features missing?

**Results**: TBD

---

### Ungoverned Features (Features Without ADRs/PDRs/POLs)

**Definition**: Implemented features that lack clear architectural justification or process compliance

**Status**: ⏳ Analysis in Phase 2-3

**Process**:
1. Phase 2: Document core features
2. Phase 3: Analyze features for governance references
3. Flag ungoverned features (0 or insufficient ADR/PDR/POL refs)
4. Determine: Is governance missing? Or feature incorrectly referenced?

**Results**: TBD

---

### Missing Governance (Inferred Needs)

**Definition**: Governance that should exist based on feature requirements but doesn't

**Status**: ⏳ Analysis in Phase 3 (Gap Analysis)

**Process**:
1. Phase 2: Document features with implementation details
2. Phase 3: Analyze features for architectural patterns used
3. Identify patterns without corresponding ADRs (e.g., saga pattern, circuit breaker)
4. Create ADRs for discovered patterns

**Expected Inferences** (from feature analysis):

| Feature Need | Missing Governance | Priority |
|--------------|-------------------|----------|
| Cart checkout saga | ADR: Saga Pattern for Distributed Transactions | High |
| Session timeout | POL: Session Security Policy | Medium |
| API rate limiting | POL: Rate Limiting Policy | Medium |
| Event schema evolution | PDR: Event Schema Versioning | High |
| Feature toggles | PDR: Feature Toggle Strategy | Low |

**Results**: TBD in Phase 3

---

### Missing Features (Governance Not Validated)

**Definition**: Governance decisions that should have features implementing them but don't

**Status**: ⏳ Analysis in Phase 1

**Process**:
1. Phase 1: Analyze ADR-0007 (CQRS) → Should have features at Level 2-3
2. Identify which features are implied but missing
3. Prioritize feature creation

**Expected Inferences** (from governance analysis):

| Governance | Implied Feature | Priority |
|------------|----------------|----------|
| ADR-0007 Level 3 CQRS/ES | Order event sourcing feature | High |
| ADR-0006 Actor patterns | Payment transaction actor feature | High |
| ADR-0005 Reactive (elastic) | Auto-scaling feature | Medium |
| POL-compliance-GDPR | Data deletion feature | High |

**Results**: TBD in Phase 1

---

## Metrics Dashboard

### Coverage Metrics

**Governance Validation Coverage**:
- **ADRs with Features**: 0 / 7 (0%) - ⏳ Pending Phase 1
- **PDRs with Features**: 0 / 8 (0%) - ⏳ Pending Phase 1
- **POLs with Features**: 0 / 2 (0%) - ⏳ Pending Phase 1

**Feature Governance Coverage**:
- **Features with ADR refs**: 0 / 0 (N/A) - ⏳ Pending Phase 2
- **Features with PDR refs**: 0 / 0 (N/A) - ⏳ Pending Phase 2
- **Features with POL refs**: 0 / 0 (N/A) - ⏳ Pending Phase 2

### Gap Metrics

- **Orphaned Governance**: TBD (target: 0)
- **Ungoverned Features**: TBD (target: 0)
- **Missing Governance Items**: TBD (will identify in Phase 3)
- **Missing Features**: TBD (will identify in Phase 1)

### Quality Metrics

- **Average ADR refs per feature**: TBD (target: 3-5)
- **Average features per ADR**: TBD (target: 3-10)
- **Inference discovery rate**: TBD (% governance gaps found)

---

## Validation Process

### Phase 1: Governance Inference Analysis (Week 1)

**Objective**: Analyze existing governance for implied features

**Activities**:
1. Read each ADR (ADR-0004 through ADR-0007)
2. For each ADR, ask: "What features would validate this decision?"
3. List 3-10 inferred features per ADR
4. Prioritize features (P0/P1/P2/P3)
5. Update "Governance → Features" sections above
6. Identify potential orphaned governance

**Deliverables**:
- 20-30 inferred features listed in this document
- Priority ranking of features
- Orphaned governance flagged (if any)

---

### Phase 2: Core Service Features (Week 2)

**Objective**: Document 5 CartService features using template

**Activities**:
1. Create features: Add Item, Query Cart, Remove Item, Checkout, Session Management
2. For each feature, identify applicable ADRs/PDRs/POLs
3. Update "Features → Governance" sections above
4. Test bidirectional inference tracking

**Deliverables**:
- 5 features documented (.feature + .md files)
- Features section added to CartService SERVICE-CANVAS.md
- This inference map populated with feature→governance links
- Template validation and refinement

---

### Phase 3: Gap Analysis (Week 3)

**Objective**: Identify missing governance and missing features

**Activities**:
1. Analyze features for patterns used but not governed (infer missing ADRs)
2. Analyze governance for features implied but not documented (infer missing features)
3. Flag ungoverned features (features with insufficient governance refs)
4. Document gaps in "Gap Analysis" section above
5. Create ADRs for discovered patterns

**Deliverables**:
- List of missing governance (ADRs/PDRs/POLs to create)
- List of missing features (features to document/implement)
- Ungoverned features flagged
- Effort estimates for gap closure

---

### Phase 7: Quarterly Validation (Ongoing)

**Objective**: Maintain inference map accuracy

**Activities**:
1. Review all governance → features links (still accurate?)
2. Review all features → governance links (complete?)
3. Update metrics dashboard
4. Identify new gaps
5. Validate gap closure

**Schedule**: Every quarter (Q1, Q2, Q3, Q4)

---

## Automation Opportunities

### Phase 6: Scripts and Tooling (Week 4-5)

**Potential Automation**:

1. **Governance Link Validator**:
   - Script: Validate all ADR/PDR/POL links in feature .md files
   - Alert: Broken links, invalid references
   - Report: Governance coverage per feature

2. **Inference Gap Detector**:
   - Script: Parse features for patterns (actor usage, CQRS level, events)
   - Compare: Patterns found vs ADRs referenced
   - Alert: Ungoverned patterns (e.g., actor used but ADR-0006 not referenced)

3. **Metrics Dashboard Generator**:
   - Script: Calculate coverage metrics automatically
   - Output: HTML dashboard with charts
   - Refresh: Weekly or on-demand

4. **Missing Feature Identifier**:
   - Script: Analyze ADRs for "should have" language (e.g., "services should use actors")
   - Compare: Actual features vs implied features
   - Report: Governance not validated by features

**Deliverables**: TBD in Phase 6

---

## Notes

### Bidirectional Inference Philosophy

**Why This Matters**:

Traditional approach:
- Write ADRs → Build features → Hope ADRs are followed
- No systematic validation
- ADRs become stale documentation
- Features built without architectural justification

**TJMPaaS approach**:
- Write ADRs → Document features → **Explicitly link them**
- Build features → Discover patterns → **Infer missing ADRs**
- Systematic validation via inference map
- Living governance validated by real code

**Benefits**:
- ✅ Governance is proven (not theoretical)
- ✅ Features are justified (not ad-hoc)
- ✅ Gaps are visible (both directions)
- ✅ Onboarding is clear (see how decisions apply)
- ✅ Compliance is traceable (decision → feature → code)

### Inference Discovery Examples

**Feature → Governance Inference**:

Scenario: Documenting "Cart Checkout" feature in Phase 2

Analysis:
- Checkout needs to: deduct inventory, reserve payment, create order, send confirmation
- This is a distributed transaction across 4 services
- No single database transaction possible
- Pattern used: Saga choreography (events coordinate)
- **Inference**: Need ADR for saga pattern (currently missing)
- **Action**: Flag in Phase 3, create ADR-0009: Saga Pattern for Distributed Transactions

**Governance → Feature Inference**:

Scenario: Analyzing ADR-0007 (CQRS) in Phase 1

Analysis:
- ADR-0007 defines CQRS maturity levels (1/2/3)
- Level 3 is "Full CQRS with Event Sourcing" for audit-critical domains
- Audit-critical domains: Orders, Payments, Inventory
- **Inference**: Should have features at Level 3 for these domains
- **Action**: Document "Order Event Sourcing" feature (inferred from ADR)

### Template Updates

As inference tracking evolves:

**FEATURE-TEMPLATE.md updates**:
- Add "Inferred Governance Needs" section (patterns used → missing ADRs)
- Add "Governance Validation" section (how this feature proves ADRs work)

**ADR/PDR/POL template updates**:
- "Related Features" section already added (Phase 0 complete)
- Consider "Validation Criteria" section (how to prove this decision works)

### Success Criteria

**Inference map is successful if**:
1. New developers can trace: ADR → Feature → Code → Test
2. Governance gaps found proactively (before problems arise)
3. No orphaned governance (all ADRs validated by features)
4. No ungoverned features (all features justified by ADRs)
5. Onboarding time reduced (clear examples of "how we apply decisions")

**Metrics to Track**:
- Time to onboard new developer (should decrease)
- Governance compliance rate (should increase)
- Architectural debt (should decrease - fewer ad-hoc patterns)
- Gap discovery rate (should be high initially, decrease over time)

---

**Maintained By**: TJMPaaS Governance  
**Next Review**: After Phase 3 (Gap Analysis complete)  
**Automation Target**: Phase 6 (Scripts and dashboard)
