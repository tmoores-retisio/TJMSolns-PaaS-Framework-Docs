# Architectural Decision Records (ADRs)

This directory contains records of significant architectural and technical decisions made during the development of TJMPaaS.

## Purpose

ADRs document the reasoning behind architectural choices, helping future contributors (including future you) understand:

- What decision was made
- Why it was made
- What alternatives were considered
- What consequences resulted from the decision

## Naming Convention

`ADR-NNNN-short-title.md`

**Examples**:
- `ADR-0001-use-kubernetes-for-orchestration.md`
- `ADR-0002-multi-cloud-abstraction-approach.md`
- `ADR-0003-monitoring-stack-selection.md`

## Template

Use `TEMPLATE.md` in this directory as the starting point for new ADRs.

## Index

| ADR # | Title | Status | Date |
|-------|-------|--------|------|
| 0001  | [GCP as Pilot Cloud Platform](ADR-0001-gcp-pilot-platform.md) | Accepted | 2025-11-26 |
| 0002  | [Documentation-First Approach](ADR-0002-documentation-first-approach.md) | Accepted | 2025-11-26 |
| 0003  | [Containerization as Core Strategy](ADR-0003-containerization-strategy.md) | Accepted | 2025-11-26 |
| 0004  | [Scala 3 Technology Stack](ADR-0004-scala3-technology-stack.md) | Accepted | 2025-11-26 |
| 0005  | [Reactive Manifesto Alignment](ADR-0005-reactive-manifesto-alignment.md) | Accepted | 2025-11-26 |
| 0006  | [Agent-Based Service Patterns](ADR-0006-agent-patterns.md) | Accepted | 2025-11-26 |
| 0007  | [CQRS and Event-Driven Architecture](ADR-0007-cqrs-event-driven-architecture.md) | Accepted | 2025-11-26 |
| -    | [Template](TEMPLATE.md) | Example | - |

## Creating a New ADR

1. Copy `TEMPLATE.md` to new file with next sequential number
2. Fill in all sections thoughtfully
3. Update the index table above
4. Link from related documentation (architecture docs, etc.)
5. Commit with descriptive message: `docs: add ADR-NNNN - <short title>`

## When to Create an ADR

Create an ADR when making decisions about:

- **Infrastructure**: Cloud provider selection, orchestration platform, networking approach
- **Architecture**: System design patterns, service boundaries, data flow
- **Technology**: Framework selection, programming languages, databases
- **Security**: Authentication/authorization approach, encryption standards
- **Integration**: APIs, protocols, message formats
- **Performance**: Caching strategies, scaling approaches, optimization techniques

## Review and Updates

- ADRs should not be edited after acceptance (except for minor typos)
- If a decision needs to change, create a new ADR that supersedes the old one
- Mark the old ADR status as "Superseded" and reference the new ADR
- This preserves the decision history and reasoning

## Related Documents

- [Governance README](../README.md) - Governance framework overview
- [Architecture Documentation](../../architecture/) - System design documents
