# PDR-0005: Framework and Library Selection Policy

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Technical Story**: Phase 0 - Foundation

## Context

TJMPaaS services will require various frameworks and libraries for different purposes (actors, effects, HTTP, persistence, etc.). The selection of frameworks impacts licensing costs, maintainability, learning curve, and operational complexity.

### Problem Statement

Establish a framework selection policy that:
- Enables choosing the best tool for each service
- Avoids proliferation of too many similar frameworks
- Maintains manageable complexity across projects
- Ensures cost-free usage (open-source only)
- Balances flexibility with standardization

### Goals

- Best-fit framework selection per service
- Bounded complexity across all TJMSolns projects
- Zero licensing costs
- Maintainable by solo developer initially
- Scales to team when needed
- Clear decision criteria

### Constraints

- Solo developer initially (limited bandwidth)
- Must be open-source with permissive licenses
- No paid licenses or commercial subscriptions
- Services should remain independent
- Must work with Scala 3 ecosystem

## Decision

**Adopt a "best-fit-per-service, bounded-across-projects" framework selection policy**:

1. **Best Fit Per Service**: Each service chooses the best framework for its needs
2. **Maximum 3 Per Category**: Limit to 3 frameworks of any particular type/purpose across ALL TJMSolns projects
3. **Open-Source Only**: Only frameworks with permissive open-source licenses (Apache 2.0, MIT, BSD, EPL)
4. **Document Choices**: ADRs document framework selections and rationale
5. **Prefer Convergence**: When starting new services, prefer existing choices unless compelling reason to differ

## Rationale

### Best Fit Per Service

**Why Allow Flexibility**:
- Different services have different needs
- Technology landscape evolves
- One size doesn't fit all
- Enables learning and experimentation
- Services remain independent

**Examples**:
- Service A uses Akka Typed (mature, proven)
- Service B uses ZIO actors (ZIO-first architecture)
- Service C uses Pekko (community-driven, Akka fork)

All valid choices depending on service context.

### Maximum 3 Per Category

**Why Bound to 3**:
- **Manageable Complexity**: Solo developer can maintain expertise in 3 similar frameworks
- **Knowledge Transfer**: Team members learn 3, not 10
- **Realistic Flexibility**: 3 options cover most needs
- **Prevents Chaos**: Unlimited choice leads to unmaintainable diversity
- **Room for Evolution**: Can adopt new tech while phasing out old

**Framework Categories**:
- **Actor Systems**: Akka Typed, ZIO Actors, Pekko
- **Effect Systems**: ZIO, Cats Effect, (3rd TBD)
- **HTTP Frameworks**: http4s, ZIO HTTP, (3rd TBD)
- **Persistence**: Akka Persistence, Pekko Persistence, (3rd TBD)
- **JSON Libraries**: circe, zio-json, (3rd TBD)
- **Testing**: munit, scalatest, (3rd TBD)

When category reaches 3, new choices require explicit decision and possibly retiring one.

### Open-Source Only

**Why No Commercial Licenses**:
- **Cost Control**: Zero licensing costs
- **Independence**: No vendor lock-in
- **Flexibility**: Can fork if needed
- **Transparency**: Source code available
- **Community**: Benefit from community contributions

**Acceptable Licenses**:
- Apache License 2.0 (preferred)
- MIT License
- BSD Licenses (2-clause, 3-clause)
- Eclipse Public License (EPL)
- Similar permissive licenses

**Unacceptable**:
- Commercial licenses requiring payment
- Proprietary software
- GPL (too restrictive for potential commercial use)
- Licenses with usage restrictions

### Documentation Required

**Why Document Choices**:
- **Rationale Preserved**: Understand why frameworks chosen
- **Decision History**: Avoid repeating mistakes
- **Knowledge Transfer**: Help future team understand landscape
- **Review Process**: Explicit decision-making

**When to Document**:
- First use of a framework (create ADR)
- Replacing one framework with another (create ADR)
- Hitting the "3 limit" (requires explicit discussion)

## Alternatives Considered

### Alternative 1: Single Framework Per Category

**Description**: Standardize on one framework for each purpose

**Pros**:
- Simplest approach
- Maximum consistency
- Least learning curve
- Easiest maintenance

**Cons**:
- One size doesn't fit all
- Can't adapt to different needs
- Miss out on better tools
- Inflexible as tech evolves

**Reason for rejection**: Too constraining; different services have genuinely different needs

### Alternative 2: Complete Freedom

**Description**: No limits, choose any framework for any service

**Pros**:
- Maximum flexibility
- Always best tool for job
- No constraints

**Cons**:
- Unmaintainable complexity
- Knowledge fragmentation
- No consistency
- Solo developer overwhelmed

**Reason for rejection**: Too chaotic; would become unmaintainable

### Alternative 3: Maximum 2 Per Category

**Description**: Only 2 frameworks allowed per category

**Pros**:
- Simpler than 3
- Still some flexibility
- Less complexity

**Cons**:
- Too constraining
- Not enough room for evolution
- Forcing choices too early

**Reason for rejection**: 2 is too few; 3 provides better balance

### Alternative 4: Commercial Licenses Acceptable

**Description**: Allow paid frameworks if they're better

**Pros**:
- Access to commercial tools
- Professional support
- Often more polished

**Cons**:
- Licensing costs
- Vendor lock-in
- May change pricing
- Less flexibility

**Reason for rejection**: Cost and lock-in concerns outweigh benefits; open-source ecosystem is excellent

### Alternative 5: No Framework Policy

**Description**: Ad-hoc decisions, no formal policy

**Pros**:
- No overhead
- Maximum flexibility

**Cons**:
- Inconsistent decisions
- No rationale captured
- Easy to lose track
- Knowledge not preserved

**Reason for rejection**: Need explicit policy to maintain manageable complexity

## Consequences

### Positive

- **Flexibility**: Services use best-fit frameworks
- **Bounded Complexity**: Maximum 3 keeps complexity manageable
- **Cost Control**: Zero licensing costs
- **Independence**: No vendor lock-in
- **Evolution**: Room to adopt new technology
- **Documentation**: Decisions captured for posterity
- **Team Scaling**: Bounded set easier to train on

### Negative

- **Multiple Tools**: Must maintain expertise in multiple frameworks
- **Inconsistency**: Services may differ in approaches
- **Limit Enforcement**: Need discipline to maintain 3-limit
- **Documentation Overhead**: Must document framework choices

### Neutral

- **Learning Curve**: 3 frameworks manageable but not trivial
- **Decision Making**: Requires thought when choosing frameworks

## Implementation

### Current Framework Selections

**Actor Systems** (max 3):
1. **Pekko**: Apache 2.0, community-driven Akka fork (recommended for new services)
2. **Akka Typed 2.6.x**: Last Apache 2.0 version, mature, proven ecosystem
3. **ZIO Actors**: Tight ZIO integration, functional style

*See [Actor Patterns Best Practices](../../best-practices/architecture/actor-patterns.md) for detailed framework comparison. Industry evidence: PayPal achieves 99.999% uptime with actors; LinkedIn runs 15K+ actors handling 100M+ req/day. Pekko recommended over Akka 2.7+ (BSL license) for licensing freedom.*

**Effect Systems** (max 3):
1. **ZIO**: Comprehensive effect system, batteries included
2. **Cats Effect**: Functional programming foundation
3. *[Available slot]*

**HTTP Frameworks** (max 3):
1. **http4s**: Pure functional HTTP
2. **ZIO HTTP**: ZIO-native HTTP server
3. *[Available slot]*

**Persistence** (max 3):
1. **Akka Persistence**: Event sourcing for Akka actors
2. **Pekko Persistence**: Event sourcing for Pekko actors
3. *[Available slot]*

**JSON Libraries** (max 3):
1. **circe**: Popular, well-documented
2. **zio-json**: ZIO-native, performant
3. *[Available slot]*

**Testing** (max 3):
1. **munit**: Fast, simple, Scala-native
2. **scalatest**: Comprehensive, mature
3. *[Available slot]*

### Selection Criteria

When choosing a framework:

1. **Licensing**: Must be open-source with permissive license
2. **Fit**: Solves the specific service's needs
3. **Maturity**: Stable and production-ready
4. **Community**: Active development and support
5. **Documentation**: Well-documented
6. **Scala 3**: Good Scala 3 support
7. **Integration**: Works with chosen effect system
8. **Count**: Doesn't exceed 3-per-category limit

### Decision Process

**First Framework in Category**:
1. Research options
2. Evaluate against criteria
3. Choose best fit
4. Document in ADR (can be brief)

**Second Framework in Category**:
1. Justify why first doesn't fit
2. Evaluate alternatives
3. Choose best fit
4. Document in ADR with rationale

**Third Framework in Category**:
1. Justify why first two don't fit
2. Seriously consider if needed
3. Evaluate carefully
4. Document in ADR with strong rationale
5. **Category is now FULL**

**Fourth Framework (Replace One)**:
1. Requires explicit ADR
2. Must justify new framework
3. Must identify which to retire
4. Migration plan for existing services
5. High bar for approval

### Guidelines

**Prefer Existing Choices**:
- Starting new service? Use existing frameworks
- Only choose new when clear benefit
- Bias toward convergence

**Document Decisions**:
- Create ADR for first use of framework
- Update ADR index
- Link from service documentation

**License Verification**:
- Check license before adoption
- Verify no hidden commercial clauses
- Confirm compatible with potential commercial use

**Review Process**:
- Self-review initially (solo developer)
- Team review when team exists
- Annual review of framework landscape

### Service Documentation

Each service should document:
```markdown
## Technology Stack

- **Language**: Scala 3.3.x
- **Build**: Mill
- **Actor System**: Akka Typed 2.x
- **Effect System**: ZIO 2.x
- **HTTP**: http4s 0.23.x
- **Persistence**: Akka Persistence
- **JSON**: circe 0.14.x
- **Testing**: munit 0.7.x

For rationale, see [ADR-0006](link) and [ADR-0004](link).
```

## Validation

Success criteria:

- Framework selections documented in ADRs
- No more than 3 frameworks per category across all projects
- All frameworks are open-source with permissive licenses
- Services using frameworks successfully
- Complexity remains manageable
- No licensing costs incurred

Metrics:
- Framework count per category (≤ 3)
- Number of services per framework
- Licensing costs ($0)
- Developer productivity (subjective)

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Exceeding 3-per-category | Medium | Strict discipline; annual review; ADR requirement for additions |
| Framework fragmentation | Medium | Prefer existing choices; justify differences; convergence bias |
| Solo developer overwhelmed | Medium | Start with 1-2 per category; grow slowly; focus on essentials |
| License changes | Low | Monitor licenses; can fork if needed; prefer Apache 2.0 |
| Framework abandonment | Low | Choose mature frameworks; active communities; have alternatives |
| Wrong framework choice | Medium | Can replace but costly; careful initial evaluation; pilot first |

## Related Decisions

- [ADR-0004: Scala 3 Technology Stack](./ADR-0004-scala3-technology-stack.md) - Base language choice
- [ADR-0006: Agent-Based Service Patterns](./ADR-0006-agent-patterns.md) - Actor framework choices
- [ADR-0007: CQRS and Event-Driven Architecture](./ADR-0007-cqrs-event-driven-architecture.md) - Persistence framework choices
- Future ADR: Effect system selection (ZIO vs Cats Effect)
- Future ADR: HTTP framework selection (http4s vs ZIO HTTP)

## References

- [Open Source Licenses](https://opensource.org/licenses)
- [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)
- [Akka License](https://www.lightbend.com/akka/license) - Note: Now BSL, Pekko is Apache 2.0 fork
- [ZIO License](https://github.com/zio/zio/blob/master/LICENSE) - Apache 2.0
- [Pekko License](https://pekko.apache.org/docs/pekko/current/project/licenses.html) - Apache 2.0
- [Choosing the Right OSS License](https://choosealicense.com/)

## Notes

**Why 3 Specifically?**

The "maximum 3" rule provides:
- **Variety**: 3 options cover most scenarios (mature/stable, modern/innovative, alternative/backup)
- **Manageable**: Solo developer can maintain expertise in 3 similar tools
- **Flexible**: Room for evolution and experimentation
- **Bounded**: Prevents chaos of unlimited choices

Examples:
- **Actor Systems**: Akka (mature), ZIO Actors (functional), Pekko (community)
- **Effect Systems**: ZIO (comprehensive), Cats Effect (standard), [room for emergence]

**Framework Categories**

Categories are logical groupings:
- **Actor Systems**: Frameworks providing actor model implementations
- **Effect Systems**: Frameworks for functional effects and IO
- **HTTP Frameworks**: Web server/client frameworks
- **Persistence**: Event sourcing and CQRS frameworks
- **JSON Libraries**: JSON serialization/deserialization
- **Testing Frameworks**: Unit and integration testing

New categories can emerge; apply same 3-limit rule.

**Akka Licensing Note**

Important: Akka changed license to Business Source License (BSL) in 2022:
- **Akka 2.6.x** (last Apache 2.0 version): Can use freely
- **Akka 2.7+**: BSL requires license for production use above revenue threshold
- **Pekko**: Apache 2.0 fork of Akka, community-driven, fully open-source

For new services:
- **Prefer Pekko** for actor systems (Apache 2.0, open governance)
- **Akka Typed 2.6.x** acceptable if already familiar
- **ZIO Actors** good alternative for ZIO-first services

This policy ensures we stay on free, open-source options.

**Service Autonomy**

Services remain autonomous:
- Each service chooses its frameworks
- Services don't share code/dependencies
- Independent deployment
- Independent framework versions

Policy provides guidance, not hard constraints per service, but constraints across ALL services.

**Evolution Strategy**

As technology evolves:
1. **Monitor**: Watch for new frameworks
2. **Evaluate**: Assess when starting new services
3. **Pilot**: Try in non-critical service first
4. **Adopt**: If proven, add to available frameworks (respecting 3-limit)
5. **Retire**: Phase out older frameworks if new one better

**Commercial Use Consideration**

Permissive licenses (Apache 2.0, MIT, BSD) chosen because:
- Compatible with future commercial offerings
- Can build proprietary services on top
- Can redistribute
- No copyleft restrictions

This enables TJMPaaS commercialization path.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
