# PDR-0008: Feature Documentation Standard

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Technical Story**: Phase 0 - Foundation, feature documentation framework

## Context

TJMPaaS services require granular, feature-level documentation that complements service-wide SERVICE-CANVAS.md documentation (PDR-0006). Features represent specific capabilities within services (e.g., "Add item to cart", "Process payment", "Reserve inventory") and require:

- Behavioral specifications (BDD/Gherkin scenarios)
- Technical implementation details
- Governance traceability (which ADRs/PDRs/POLs apply)
- Gap analysis (what's implemented vs planned)
- Stakeholder value propositions
- API examples and sequence diagrams

### Problem Statement

Establish a feature documentation standard that:
- Provides executable specifications via BDD
- Links features to architectural decisions (ADRs/PDRs/POLs)
- Enables bidirectional inference tracking (governance ↔ features)
- Supports gap analysis and implementation tracking
- Communicates value to multiple stakeholders
- Integrates with service canvas documentation
- Works within multi-repo strategy (PDR-0004)

### Goals

- Standardized feature documentation structure
- BDD test specifications (Gherkin + ScalaTest)
- Bidirectional governance linkage
- Gap visibility and tracking
- Value communication (commerce, customer, operator)
- Service canvas integration
- Template-based consistency

### Constraints

- Multi-repository structure (each service in own repo)
- Solo developer initially (practical overhead)
- Must integrate with existing governance (ADRs/PDRs/POLs)
- Must complement SERVICE-CANVAS.md (not duplicate)
- Must work with Scala 3 and functional programming
- Template co-location per PDR-0007 strategy

## Decision

**Adopt standardized feature documentation** with:

1. **Dual-Format Approach**: `.feature` (BDD/Gherkin) + `.md` (technical documentation)
2. **Per-Service Features Directory**: Each service has `features/` directory
3. **Feature Template**: Co-located template in governance repo templates
4. **Governance Cross-Referencing**: Features explicitly reference ADRs/PDRs/POLs
5. **Gap Analysis**: Cumulative `feature-gaps.md` per service
6. **Inference Tracking**: Bidirectional governance-feature relationship tracking
7. **Service Canvas Integration**: Features section in SERVICE-CANVAS.md

## Rationale

### Why Dual Format (`.feature` + `.md`)?

**Gherkin `.feature` Files**:
- **Executable Specifications**: ScalaTest + Cucumber integration
- **Business Language**: Given/When/Then readable by non-developers
- **Test Framework**: Direct mapping to automated tests
- **Scenario Coverage**: Ensures all cases documented and tested

**Markdown `.md` Files**:
- **Technical Details**: Implementation, architecture, APIs
- **Governance Links**: ADR/PDR/POL references
- **Stakeholder Communication**: Value propositions
- **Gap Analysis**: What's missing, effort estimates
- **Developer Guide**: How to implement/extend

**Rationale**: Gherkin is executable but limited; Markdown provides full technical context. Together they cover specification + implementation.

### Why Per-Service Features Directory?

**Aligns with Multi-Repo Strategy** (PDR-0004):
- Each service repository is self-contained
- Features travel with service code
- Independent versioning and deployment
- Clear service boundaries

**Structure**:
```
TJMSolns-CartService/
├── features/               # Feature documentation
│   ├── FEATURE-TEMPLATE.md # Template (copied from governance)
│   ├── cart-add-item.feature
│   ├── cart-add-item.md
│   ├── cart-checkout.feature
│   ├── cart-checkout.md
│   └── feature-gaps.md    # Cumulative gap tracking
├── SERVICE-CANVAS.md      # Service overview (links to features)
├── src/
│   └── test/scala/
│       └── features/      # Feature test implementations
└── ...
```

### Why Bidirectional Inference Tracking?

**Governance → Features**:
- ADR-0007 (CQRS) → Infers cart, order, payment features need command/query separation
- ADR-0006 (Actors) → Infers stateful features need actor implementation
- POL-security → Infers all features need authentication

**Features → Governance**:
- Cart checkout feature → Infers need for saga pattern ADR
- Event publishing feature → Infers need for event schema evolution PDR
- Session timeout → Infers need for session security POL

**Benefits**:
- **Living Governance**: Features validate ADRs work in practice
- **Gap Detection**: Find missing governance or missing features
- **Onboarding**: New developers see "how we apply decisions"
- **Traceability**: Complete chain from decision → feature → code → test

### Why Service Canvas Integration?

**Hierarchy**:
```
README.md              → Entry point, quick start
   ↓
SERVICE-CANVAS.md     → Service overview (links to features)
   ↓
features/*.md          → Detailed feature documentation
   ↓
docs/                  → Architecture, API, runbooks
```

**Canvas Features Section**:
- Summary table of all features
- Status indicators (implemented/partial/planned)
- Governance references
- Gap highlights
- Links to detailed feature docs

**Benefits**:
- Quick feature status visibility
- Single point of navigation
- Prevents documentation drift
- Shows service maturity at a glance

## Alternatives Considered

### Alternative 1: Only Gherkin (No Markdown)

**Description**: Use `.feature` files only, all documentation in comments

**Pros**:
- Single source of truth
- Forces executable specs
- Simpler structure

**Cons**:
- Gherkin comments ugly for technical details
- No governance cross-referencing
- No stakeholder value propositions
- Poor for API examples and diagrams

**Reason for rejection**: Gherkin excellent for behavior, poor for architecture/governance/value communication

### Alternative 2: Only Markdown (No BDD)

**Description**: Use `.md` files only with scenario descriptions

**Pros**:
- Flexible format
- Full technical detail
- Easy to write

**Cons**:
- Not executable
- No test framework integration
- Scenarios in prose (not structured)
- Harder to validate coverage

**Reason for rejection**: Missing BDD benefits; scenarios should be executable tests

### Alternative 3: Central Features Repository

**Description**: Single repo for all feature documentation

**Pros**:
- One place to find everything
- Easier cross-service feature search

**Cons**:
- Violates multi-repo strategy (PDR-0004)
- Features separated from code
- Version synchronization issues
- Deployment coupling

**Reason for rejection**: Must align with multi-repo architecture; features belong with services

### Alternative 4: No Feature-Level Documentation

**Description**: Only SERVICE-CANVAS.md and code comments

**Pros**:
- Less documentation overhead
- Simpler structure

**Cons**:
- No executable specifications
- No detailed feature tracking
- No gap visibility
- Poor governance traceability
- Harder to communicate value

**Reason for rejection**: SERVICE-CANVAS.md is overview; need feature-level detail for complex services

## Consequences

### Positive

- **Executable Specifications**: BDD scenarios map to automated tests
- **Governance Traceability**: Features link to ADRs/PDRs/POLs
- **Gap Visibility**: Know what's implemented vs planned
- **Stakeholder Communication**: Value propositions for different audiences
- **Onboarding**: New developers understand capabilities quickly
- **Living Documentation**: Features validated by implementation
- **Bidirectional Validation**: Governance proven by features, features justified by governance
- **Service Canvas Integration**: Overview links to details

### Negative

- **Documentation Overhead**: Two files per feature (`.feature` + `.md`)
- **Maintenance Burden**: Must keep features current with code
- **Learning Curve**: Developers must understand BDD + governance linking
- **Duplication Risk**: Some info in feature + canvas + code

### Neutral

- **Solo Developer**: Initially more work but pays off with clarity
- **Tool Requirements**: Need ScalaTest + Cucumber integration

## Implementation

### Requirements

**Feature Documentation Structure**:

Each feature consists of:

1. **`<feature-name>.feature`** - Gherkin scenarios
   - GitHub issue reference
   - Feature description
   - Background (setup)
   - Scenarios (Given/When/Then)
   - Tags (@feature, @core, @priority)

2. **`<feature-name>.md`** - Technical documentation
   - Value propositions (3 perspectives)
   - Applicable governance (ADRs/PDRs/POLs)
   - Service boundaries (own vs delegate)
   - Implementation status (endpoints, actors, events)
   - Gap analysis
   - Sequence diagrams
   - API examples
   - Implementation location (code references)
   - Testing strategy
   - CQRS maturity level
   - Related features

3. **`feature-gaps.md`** - Cumulative gap tracking
   - One per service
   - Lists all gaps across all features
   - Priority and effort estimates
   - Links to features with gaps

**Template Location**:
- Master template: `doc/internal/governance/templates/FEATURE-TEMPLATE.md`
- Copied to each service's `features/` directory when service created
- Co-located with features per PDR-0007 strategy

**Service Canvas Integration**:

SERVICE-CANVAS.md must include Features section:

```markdown
## Features

**Location**: [features/](./features/) directory

**Documentation Standard**: [PDR-0008](../../TJMPaaS/doc/internal/governance/PDRs/PDR-0008-feature-documentation-standard.md)

**Status Summary**: X features documented, Y implemented, Z planned

| Feature | Status | CQRS | Governance | Gaps |
|---------|--------|------|------------|------|
| [Feature Name](./features/feature-name.md) | 🟢/🟡/🔴 | Command/Query/N/A | ADR-X, PDR-Y | Summary |
| ... | ... | ... | ... | ... |

**Key**:
- 🟢 Implemented - Feature complete and tested
- 🟡 Partial - Feature partially implemented, gaps documented
- 🔴 Planned - Feature documented but not yet implemented
```

**Inference Tracking**:

Central tracking document: `doc/internal/GOVERNANCE-FEATURE-INFERENCE-MAP.md`

Tracks:
- Governance → Features (which features validate this governance?)
- Features → Governance (which governance does this feature require?)
- Gap analysis (orphaned governance, ungoverned features, missing items)
- Metrics (coverage percentages)

### Feature Creation Workflow

**Step 1: Planning** (before code):
1. Create `<feature-name>.feature` (Gherkin scenarios)
2. Create `<feature-name>.md` (from template)
3. Identify applicable governance (ADRs/PDRs/POLs)
4. Document gaps in `feature-gaps.md`
5. Update SERVICE-CANVAS.md features table

**Step 2: Implementation**:
1. Implement actors/routes/events
2. Write feature tests (ScalaTest + Cucumber)
3. Update `.md` with implementation details
4. Update status markers (🔴 → 🟡 → 🟢)

**Step 3: Review**:
1. Verify governance references correct
2. Check scenarios match implementation
3. Validate API examples work
4. Update SERVICE-CANVAS.md if needed

**Step 4: Maintenance**:
1. Keep features current with code changes
2. Update gap analysis as gaps closed
3. Quarterly review (validate accuracy)

### BDD Testing Integration

**ScalaTest + Cucumber**:

```scala
// src/test/scala/features/CartAddItemSpec.scala
import org.scalatest.featurespec.AnyFeatureSpec
import org.scalatest.GivenWhenThen
import org.scalatest.matchers.should.Matchers

class CartAddItemSpec extends AnyFeatureSpec with GivenWhenThen with Matchers {
  
  feature("Add item to shopping cart") {
    
    scenario("Customer adds available product to cart") {
      Given("a customer with an empty cart")
      val cart = testKit.spawn(ShoppingCartActor("cart-123"))
      
      When("they add a product to the cart")
      val probe = testKit.createTestProbe[CartResponse]()
      cart ! AddItem("prod-456", 2, probe.ref)
      
      Then("the item should be added successfully")
      probe.expectMessage(ItemAdded("item-789", "prod-456", 2))
      
      And("the cart should reflect the new item")
      cart ! GetCart(probe.ref)
      probe.expectMessage(Cart("cart-123", List(CartItem("item-789", "prod-456", 2))))
    }
  }
}
```

**Mapping**: `.feature` scenario → ScalaTest feature test → Actor implementation

### Governance Cross-Referencing

**In Feature `.md` Files**:

```markdown
## Applicable Governance

### ADRs (Architecture)
- [ADR-0004: Scala 3 Technology Stack](../../TJMPaaS/doc/internal/governance/ADRs/ADR-0004-scala3-technology-stack.md) - Functional programming patterns
- [ADR-0006: Agent-Based Service Patterns](../../TJMPaaS/doc/internal/governance/ADRs/ADR-0006-agent-patterns.md) - ShoppingCartActor message protocol
- [ADR-0007: CQRS and Event-Driven Architecture](../../TJMPaaS/doc/internal/governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) - Command handling

### PDRs (Process)
- [PDR-0006: Service Canvas Documentation Standard](../../TJMPaaS/doc/internal/governance/PDRs/PDR-0006-service-canvas-standard.md) - Feature integration
- [PDR-0008: Feature Documentation Standard](../../TJMPaaS/doc/internal/governance/PDRs/PDR-0008-feature-documentation-standard.md) - This standard

### POLs (Policy)
- [POL-security-baseline](../../TJMPaaS/doc/internal/governance/POLs/POL-security-baseline.md) - Authentication required
```

**In Governance Documents**:

Add "Related Features" section:

```markdown
## Related Features

This architectural decision is validated by the following features:

- [Shopping Cart - Add Item](../../TJMSolns-CartService/features/cart-add-item.md) - Actor message protocol
- [Shopping Cart - Session Management](../../TJMSolns-CartService/features/cart-session.md) - Actor lifecycle
- [Order - Saga Orchestration](../../TJMSolns-OrderService/features/order-saga.md) - Actor coordination
```

### Feature Prioritization

**When to Create Features**:

✅ **Create for**:
- Core capabilities (cart, order, payment, search)
- Complex workflows (checkout, saga patterns, fulfillment)
- Integration points (cross-service, external APIs)
- Compliance-critical (audit, data retention, security)
- Governance validation (proves ADR/PDR works)

❌ **Skip for**:
- Trivial utilities (format phone number, validate email)
- Framework boilerplate (health checks, metrics endpoints)
- Internal helpers (logging utilities, test fixtures)

**Priority Levels**:

1. **P0 (Foundational)**: Service cannot function without this
2. **P1 (Core)**: Major user-facing capability
3. **P2 (Enhanced)**: Valuable but not essential
4. **P3 (Future)**: Nice-to-have, low priority

### Documentation Standards

**Feature `.md` File Sections** (required):

1. **Header** - Feature name, status, dates, effort
2. **Value Propositions** - Digital commerce, customer, operator
3. **Applicable Governance** - ADRs, PDRs, POLs
4. **Service Boundaries** - Own vs delegate
5. **Implementation Status** - Endpoints, actors, events
6. **Gap Analysis** - Critical gaps with effort
7. **Sequence Diagrams** - Mermaid format
8. **API Examples** - curl + JSON responses
9. **Implementation Location** - Code file references
10. **Testing Strategy** - BDD + integration tests
11. **CQRS Maturity Level** - Level 1/2/3 (if applicable)
12. **Related Features** - Dependencies and relationships

**Gherkin `.feature` File Standards**:

```gherkin
# GitHub Issue: #XXX
# Labels: feature, core, priority
# Status: Todo/In Progress/Done
# Last Updated: YYYY-MM-DD

@feature @core @priority
Feature: <Feature Name>
  As a <role>
  I want <capability>
  So that <benefit>

  Background:
    Given <common setup>
    And <preconditions>

  Scenario: <Happy path scenario>
    Given <initial state>
    When <action>
    And <additional action>
    Then <expected outcome>
    And <verification>

  Scenario: <Error scenario>
    Given <initial state>
    When <error-inducing action>
    Then <error handling>
```

### Migration Path for Existing Services

**For Services Created Before PDR-0008**:

1. Create `features/` directory
2. Copy FEATURE-TEMPLATE.md from governance repo
3. Identify 3-5 core features to document first
4. Create `.feature` + `.md` files for core features
5. Add Features section to SERVICE-CANVAS.md
6. Update GOVERNANCE-FEATURE-INFERENCE-MAP.md
7. Document remaining features incrementally

**Priority**: Core capabilities first, then integration points, then enhancements

## Validation

Success criteria:

- Feature template created and accessible
- At least one service has 3+ features documented
- Features reference applicable governance correctly
- Governance documents reference features
- SERVICE-CANVAS.md integrates features section
- Feature tests executable via ScalaTest
- Gap analysis tracks implementation status
- Inference map shows bidirectional linkage

Metrics:
- Number of features documented per service
- Governance coverage (% features with ADR/PDR/POL refs)
- Feature implementation rate (% features fully implemented)
- Gap closure rate (gaps closed over time)
- Inference completeness (% governance validated by features)

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Documentation overhead too high | Medium | Start with core features only; use templates; automate where possible |
| Features drift from code | Medium | Quarterly reviews; CI validation; feature tests enforce accuracy |
| Governance cross-refs become stale | Low | Inference map validation script; automated link checking |
| Template too prescriptive | Low | Template is guide not mandate; adapt per service needs |
| Solo developer overwhelmed | Medium | Prioritize ruthlessly; document incrementally; automate repetitive tasks |
| BDD testing overhead | Medium | Feature tests are integration tests; replace some manual testing |

## Related Decisions

- [PDR-0006: Service Canvas Documentation Standard](./PDR-0006-service-canvas-standard.md) - Canvas integration
- [PDR-0004: Repository Organization Strategy](./PDR-0004-repository-organization.md) - Multi-repo structure
- [PDR-0007: Documentation Asset Management](./PDR-0007-documentation-asset-management.md) - Template co-location
- [ADR-0004: Scala 3 Technology Stack](../ADRs/ADR-0004-scala3-technology-stack.md) - ScalaTest integration
- [ADR-0006: Agent-Based Service Patterns](../ADRs/ADR-0006-agent-patterns.md) - Actor-based features
- [ADR-0007: CQRS and Event-Driven Architecture](../ADRs/ADR-0007-cqrs-event-driven-architecture.md) - CQRS maturity documentation

## Related Features

**Features That Validate This Decision**:

*To be documented in Phase 2 (Core Service Features)*

This is a meta-standard (defines how features are documented).

**Validation**:
- First features documented (Phase 2) will validate template usability
- Features should follow template structure (.feature + .md files)
- Features should reference applicable ADRs/PDRs/POLs
- Template refinement based on usage feedback

**Inference Tracking**: See [GOVERNANCE-FEATURE-INFERENCE-MAP.md](../../GOVERNANCE-FEATURE-INFERENCE-MAP.md#pdr-0008-feature-documentation-standard)

## References

- [Behavior-Driven Development (BDD)](https://cucumber.io/docs/bdd/) - BDD methodology
- [Gherkin Reference](https://cucumber.io/docs/gherkin/reference/) - Gherkin syntax
- [ScalaTest FeatureSpec](https://www.scalatest.org/user_guide/selecting_a_style) - Scala BDD testing
- [Martin Fowler - Feature Toggles](https://martinfowler.com/articles/feature-toggles.html) - Feature management
- Previous project feature documentation (doc/tmp/features/) - Inspiration and patterns

## Notes

**Feature Documentation Philosophy**:

Features bridge the gap between governance (strategic decisions) and code (tactical implementation):

```
Governance (Why/What)
        ↓
   Features (How/When)
        ↓
    Code (Implementation)
        ↓
    Tests (Validation)
```

**Features answer**:
- What does this service do? (capabilities)
- Why does it do it this way? (governance references)
- How is it implemented? (architecture, APIs)
- When is it done? (status, gaps)
- Who benefits? (value propositions)

**From Previous Project Learnings**:

The previous project (doc/tmp/features/) demonstrated:
- ✅ Value propositions critical for stakeholder communication
- ✅ Governance cross-referencing enables traceability
- ✅ Gap analysis prevents "configuration without enforcement"
- ✅ Platform delegation model clarifies boundaries
- ✅ Sequence diagrams aid understanding
- ⚠️ Can become verbose (2600+ lines per feature) - aim for conciseness
- ⚠️ Java/OOP examples - adapt for Scala 3/FP/actors

**TJMPaaS Adaptations**:
- Simpler value framework (3 perspectives vs 4)
- Actor model emphasis (message protocols, supervision)
- CQRS level documentation (explicit Level 1/2/3)
- Functional programming patterns (immutability, pure functions, effects)
- Co-located templates (PDR-0007 strategy)
- Service canvas integration (PDR-0006 hierarchy)

**Solo Developer Context**:

Initial overhead justified by:
- **Clarity**: Forces thinking through design before coding
- **Communication**: When team grows, features are onboarding docs
- **Quality**: BDD scenarios = integration tests
- **Traceability**: Governance validated by real features
- **Maintainability**: Clear structure prevents ad-hoc documentation

**Start Small**: Document 3-5 core features per service, expand incrementally.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
