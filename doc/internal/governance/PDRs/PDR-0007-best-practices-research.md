# PDR-0007: Research-Backed Best Practices Framework

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Technical Story**: Phase 0 - Foundation

## Context

TJMPaaS involves complex architectural, commerce, and operational decisions. While ADRs and PDRs document decisions made for the project, there's value in researching and documenting industry best practices to inform those decisions.

### Problem Statement

Establish a framework for:
- Researching industry best practices
- Documenting findings in a structured way
- Applying research critically to TJMPaaS context
- Challenging assumptions with evidence-based alternatives
- Maintaining a knowledge base of validated patterns

### Goals

- Evidence-based decision making
- Critical evaluation of proposed approaches
- Access to industry consensus and case studies
- Trade-off analysis for architectural patterns
- Context-aware application of best practices
- Knowledge preservation for team scaling

### Constraints

- Solo developer initially (limited research time)
- Must be practical, not academic
- Focus on actionable insights
- Avoid analysis paralysis
- Balance research depth with delivery velocity

## Decision

**Establish a research-backed best practices framework** with:

1. **Best Practices Directory**: `doc/internal/best-practices/`
2. **Best Practices Guide**: `doc/internal/BEST-PRACTICES-GUIDE.md` (index and process)
3. **Structured Documentation**: Standard template for research findings
4. **Critical Thinking**: AI assistant provides evidence-based challenges
5. **Contextual Application**: Best practices inform, not dictate decisions

## Rationale

### Why Document Best Practices?

**Informed Decision Making**:
- Access to industry consensus before committing to approaches
- Understanding of trade-offs beyond theoretical knowledge
- Case studies from companies solving similar problems
- Awareness of common pitfalls and anti-patterns

**Critical Thinking**:
- Evidence to validate or challenge proposed approaches
- Concrete alternatives with documented trade-offs
- Reduces risk of reinventing known solutions poorly
- Exposes blind spots in reasoning

**Knowledge Preservation**:
- Captures research for future reference
- Avoids repeating research when similar decisions arise
- Foundation for onboarding when team grows
- Documents "why not X" as much as "why Y"

**Solo Developer Benefit**:
- External validation of approaches
- Compensates for lack of team peer review
- Access to collective wisdom of industry
- Reduces decision anxiety with evidence

### Why Structured Documentation?

**Consistency**: Standard template ensures complete analysis

**Reusability**: Findings apply to multiple decisions over time

**Traceability**: Link from ADRs/PDRs to supporting research

**Maintenance**: Easy to update as industry evolves

### Integration with AI Assistant Role

Tony explicitly stated:

> "I am opinionated but not always correct. Agreeing with me to stroke my ego is no help at all. In these roles I expect you to be realistic, practical & critical, calling out where you or conventional wisdom may disagree, offering superior alternative suggestions for my consideration..."

This framework enables AI assistant to:
- Research topics before making recommendations
- Provide evidence-based disagreement when warranted
- Offer alternatives grounded in industry practice
- Document findings for Tony's consideration
- Reference authoritative sources in discussions

## Alternatives Considered

### Alternative 1: No Formal Research Process

**Description**: Make decisions ad-hoc without documented research

**Pros**:
- Faster initial decisions
- No documentation overhead
- Maximum flexibility

**Cons**:
- Risk of poor decisions lacking context
- Repeat research for similar decisions
- No knowledge preservation
- Miss proven patterns
- Solo developer has no peer review substitute

**Reason for rejection**: Research benefits outweigh documentation overhead; critical for solo developer

### Alternative 2: Research Without Documentation

**Description**: Research as needed but don't document findings

**Pros**:
- Research benefits without documentation work
- Faster than full documentation

**Cons**:
- Lose research findings over time
- Repeat research for similar decisions
- Can't reference in ADRs/PDRs
- No knowledge base for team growth

**Reason for rejection**: Documentation makes research reusable and prevents repeated work

### Alternative 3: Academic/Exhaustive Research

**Description**: Deep academic research for every topic

**Pros**:
- Comprehensive understanding
- Academic rigor
- Publication-quality

**Cons**:
- Massively time-consuming
- Analysis paralysis
- Over-engineering risk
- Not actionable enough

**Reason for rejection**: Need practical, actionable insights, not academic papers

### Alternative 4: Only Industry Blogs

**Description**: Rely solely on blog posts and articles

**Pros**:
- Fast to consume
- Practical examples
- Current information

**Cons**:
- Variable quality
- May lack depth
- Potential bias
- Miss academic foundations

**Reason for rejection**: Need balance of academic foundations and practical application

### Alternative 5: External Consultants

**Description**: Hire consultants for architectural guidance

**Pros**:
- Expert perspective
- Experience from multiple projects
- Immediate guidance

**Cons**:
- Expensive
- May not understand context
- Not always available
- Knowledge leaves with consultant

**Reason for rejection**: Cost-prohibitive for solo bootstrapped project; documented research is reusable

## Consequences

### Positive

- **Better Decisions**: Informed by industry consensus and case studies
- **Risk Reduction**: Aware of pitfalls before encountering them
- **Faster Learning**: Access to collective wisdom
- **Critical Thinking**: AI assistant can provide evidence-based challenges
- **Knowledge Preservation**: Research captured for future reference
- **Team Scaling**: Foundation for onboarding future team members
- **Confidence**: Decisions backed by evidence, not just intuition

### Negative

- **Time Investment**: Research and documentation take time
- **Maintenance Burden**: Best practices must be kept current
- **Analysis Risk**: Potential for over-analysis
- **Context Misapplication**: Industry patterns may not fit TJMPaaS context

### Neutral

- **Documentation Volume**: More documents to maintain
- **Research Depth**: Must balance thoroughness with velocity

## Implementation

### Directory Structure

```
doc/internal/
├── BEST-PRACTICES-GUIDE.md       # Index and process documentation
└── best-practices/
    ├── README.md                 # Directory overview
    ├── architecture/             # Architecture pattern research
    ├── commerce/                 # Digital commerce patterns
    ├── operations/               # Ops and observability
    ├── security/                 # Security and compliance
    └── development/              # Development practices
```

### Document Template

Each best practices document follows structure:

1. **Context**: Why this matters for TJMPaaS
2. **Industry Consensus**: What leaders recommend
3. **Research Summary**: Key findings
4. **Value Proposition**: Benefits and costs
5. **Recommendations**: How to apply to TJMPaaS
6. **Trade-off Analysis**: Compare approaches
7. **References**: Sources consulted
8. **Related Governance**: Links to ADRs/PDRs

### Research Process

1. **Identify Need**: Topic requires external validation
2. **Research**: Review authoritative sources (blogs, papers, case studies)
3. **Synthesize**: Extract patterns, anti-patterns, trade-offs
4. **Document**: Create best practices document
5. **Index**: Add to BEST-PRACTICES-GUIDE.md
6. **Apply**: Reference in recommendations and decisions
7. **Update**: Revise as new information emerges

### Priority Topics

**Phase 1** (High Priority):
- CQRS implementation patterns
- Event sourcing at scale
- Actor model supervision strategies
- Microservices boundaries
- Shopping cart patterns
- Payment gateway integration

**Phase 2** (Medium Priority):
- Service observability
- Circuit breaker patterns
- Kubernetes resource management
- API versioning strategies

**Phase 3** (Lower Priority):
- Container security hardening
- Multi-tenant architecture
- Advanced saga patterns

### Authoritative Sources

**Architecture**: Martin Fowler, ThoughtWorks, InfoQ, ACM Queue

**Cloud-Native**: Google Cloud Architecture, AWS Architecture, Azure patterns

**Commerce**: Shopify Engineering, Stripe, Adobe Commerce, commercetools

**Reactive**: Lightbend, Reactive Manifesto, Jonas Bonér

**Scala/FP**: Typelevel, ZIO, Rock the JVM

**Books**: DDD (Evans), Microservices (Newman), Release It! (Nygard), DDIA (Kleppmann)

### AI Assistant Integration

Update copilot instructions to:
- Emphasize critical thinking over agreement
- Conduct research for significant decisions
- Document findings in best-practices/
- Reference research in recommendations
- Challenge Tony's approaches when warranted
- Provide evidence-based alternatives

### Application Guidelines

**When to Apply Best Practices**:
- Context matches where practice adds value
- Benefits justify complexity
- Supports TJMPaaS business model
- Practical for solo developer
- Facilitates future team scaling

**When to Deviate**:
- TJMPaaS context differs significantly
- Simpler solution achieves same goals
- Complexity outweighs benefits
- Premature for current phase
- Conflicts with other constraints

**Critical Questions**:
1. Does our context match where this adds value?
2. Can one person reasonably apply this?
3. Does benefit justify added complexity?
4. Does this support commercial viability?
5. Will this help when team grows?

### Maintenance

- **Quarterly Review**: Check for outdated information
- **Industry Changes**: Update when consensus shifts
- **Production Lessons**: Incorporate TJMPaaS experience
- **Community Input**: Consider broader community feedback

## Validation

Success criteria:

- Best practices documents created for key topics
- Research referenced in ADRs/PDRs
- AI assistant provides evidence-based recommendations
- Tony receives critical feedback, not just agreement
- Decisions informed by industry consensus
- Research findings reused across similar decisions

Metrics:
- Number of best practices documents created
- References from ADRs/PDRs to best practices
- Decisions changed based on research findings
- Time saved by reusing previous research

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Analysis paralysis | Medium | Time-box research; focus on actionable insights; defer deep dives |
| Outdated information | Medium | Quarterly reviews; mark documents with research date; update as needed |
| Context misapplication | Medium | Always evaluate fit for TJMPaaS; document when to skip practices |
| Documentation burden | Low | Use template; prioritize high-value topics; don't document everything |
| Confirmation bias | Low | Seek diverse sources; document trade-offs; include counter-arguments |
| Over-reliance on best practices | Low | Remember "best" is contextual; validate against TJMPaaS needs |

## Related Decisions

- [PDR-0001: Documentation Standards](./PDR-0001-documentation-standards.md) - How docs are structured
- [PDR-0002: Governance Framework](./PDR-0002-governance-framework.md) - Decision-making process
- All ADRs - May reference best practices research
- All PDRs - May reference best practices research

## References

- [Martin Fowler's Blog](https://martinfowler.com/)
- [ThoughtWorks Technology Radar](https://www.thoughtworks.com/radar)
- [InfoQ](https://www.infoq.com/)
- [Google Cloud Architecture Center](https://cloud.google.com/architecture)
- Research methodology from academic and industry sources

## Notes

**Research vs. Decision**:

Clear distinction:
- **Best Practices Documents**: Research findings, industry consensus, trade-off analysis
- **ADRs**: Project-wide architectural decisions for TJMPaaS
- **PDRs**: Process decisions for TJMPaaS

Research informs decisions but doesn't make them. Best practices provide context; ADRs/PDRs make choices.

**Critical Thinking**:

Tony's emphasis on critical thinking is key:
- Don't agree just to agree
- Provide evidence-based disagreement
- Offer superior alternatives
- Document trade-offs honestly
- Focus on outcomes, not egos

This framework enables that by grounding recommendations in research.

**Solo Developer Context**:

Best practices research particularly valuable for solo developer because:
- No team for peer review
- No architecture board
- No tech leads to consult
- External validation critical
- Reduces decision anxiety

Research serves as "virtual team" providing perspectives.

**Pragmatism**:

Balance research depth with delivery:
- Time-box research (don't go down rabbit holes)
- Focus on actionable insights
- Document enough to inform, not exhaustively
- Prioritize high-impact topics
- Defer low-priority topics until needed

**Example Workflow**:

1. Tony: "Should we use CQRS for CartService?"
2. AI: Researches CQRS implementation patterns
3. AI: Creates best-practices/architecture/cqrs-patterns.md
4. AI: "Research shows CQRS adds value when read-to-write ratio > 10:1 and you need independent scaling. For CartService, this fits because [reasons]. However, simpler alternatives exist: [options]. Here's the trade-off analysis..."
5. Tony: Makes informed decision
6. ADR references best practices research
7. Future services reuse research

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
