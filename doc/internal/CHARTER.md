# TJMPaaS Project Charter

**Version**: 1.1  
**Date**: November 26, 2025  
**Updated**: December 14, 2025 (Added local-first development scope)  
**Owner**: Tony Moores, TJM Solutions LLC  
**Status**: Active

## Mission

To develop and maintain a comprehensive library of containerized services that provide platform-as-a-service capabilities, enabling rapid deployment, scalability, and operational excellence for TJM Solutions' consulting engagements and future commercial offerings.

## Vision

Establish TJMPaaS as a flexible, cloud-agnostic platform framework that:

- Accelerates service delivery for client projects
- Demonstrates technical excellence and modern best practices
- Provides a foundation for future commercial SaaS offerings
- Maintains portability across multiple cloud providers

## Scope

### In Scope

- **Containerized Services**: Development of reusable, containerized service components
- **Local-First Development** (Phase 0-2): Development and validation on local hardware (monsoon workstation) to optimize costs
- **Cloud Infrastructure** (Phase 3+): Deployment to Google Cloud Platform (GCP) when services are production-ready
- **Documentation**: Comprehensive internal documentation for architecture, operations, and governance
- **Multi-Cloud Planning**: Design decisions that enable future cloud portability
- **Architecture Validation**: Prove reactive patterns, CQRS, event sourcing, and multi-tenant isolation locally before cloud costs

### Out of Scope (Current Phase)

- **Immediate cloud deployment**: GCP deployment deferred to Phase 3+ per cost optimization strategy (see [ADR-0008](./governance/ADRs/ADR-0008-local-first-development.md))
- **Multi-cloud deployment**: Active deployment to multiple clouds (planned for post-pilot)
- **Commercial licensing**: Formal commercialization and external customer onboarding (future phase)
- **Public-facing services**: External/public service offerings (pilot is internal only)
- **Team scaling**: Additional staff or external contributors (Tony is sole administrator)

### Future Considerations

- Expansion to AWS, Azure, or other cloud providers
- Commercial product development and go-to-market strategy
- Open-source component releases
- Partner integrations and ecosystem development

## Objectives

### Primary Objectives

1. **Service Library Development**: Create a curated set of containerized services addressing common platform needs
2. **Cost-Optimized Development**: Validate architecture locally (Phase 0-2) before cloud costs, saving ~$1,200 while maintaining cloud-ready design
3. **Architecture Validation**: Prove reactive patterns, CQRS, event sourcing, actor model, and multi-tenant isolation locally
4. **GCP Deployment Readiness**: Ensure seamless cloud migration when services are production-ready (Phase 3+)
5. **Documentation Excellence**: Maintain comprehensive, knowledge-base-ready documentation
6. **Cloud Portability**: Design with multi-cloud deployment as a future capability

### Success Metrics

**Phase 0-2 (Local Development)**:
- Number of services implemented and validated locally
- Zero infrastructure costs ($0/month target)
- Architecture patterns proven (CQRS, event sourcing, actors, multi-tenant)
- Performance targets met locally (<200ms p95 response time)
- Documentation completeness and accessibility

**Phase 3+ (Cloud Deployment)**:
- Successful deployment and operation on GCP
- Migration time per service (<1 day target)
- Cloud costs justified by service maturity and revenue
- Architectural decisions support multi-cloud future

## Technology Foundation

TJMPaaS is built on a modern, reactive technology stack designed for digital commerce and cloud-native deployment:

**Core Technologies**:
- **Scala 3**: Functional programming with advanced type system
- **Mill**: Modern build tool for Scala projects
- **JVM**: OpenJDK 17 or 21 LTS runtime

**Architectural Principles**:
- **Reactive Manifesto**: Responsive, resilient, elastic, message-driven systems
- **Agent Patterns**: Actor Model (Akka Typed/ZIO Actors) for concurrency and state
- **Functional Programming**: Immutability, pure functions, effect systems

**Infrastructure**:
- **Containerization**: Docker/OCI containers
- **Orchestration**: Kubernetes (GKE on GCP)
- **Repository Strategy**: Multi-repo with `TJMSolns-<ServiceName>` pattern

For detailed technology decisions, see:
- [ADR-0004: Scala 3 Technology Stack](./governance/ADRs/ADR-0004-scala3-technology-stack.md)
- [ADR-0005: Reactive Manifesto Alignment](./governance/ADRs/ADR-0005-reactive-manifesto-alignment.md)
- [ADR-0006: Agent-Based Service Patterns](./governance/ADRs/ADR-0006-agent-patterns.md)
- [PDR-0004: Repository Organization](./governance/PDRs/PDR-0004-repository-organization.md)

## Stakeholders

### Primary Stakeholder

- **Tony Moores**: Owner, Architect, Developer, Administrator
  - Business: TJM Solutions LLC
  - Email: tmoores@tjm.solutions
  - GitHub: tmoores-retisio

### Infrastructure

- **Google Workspace**: Business operations and collaboration
- **GCP**: Primary cloud infrastructure (pilot phase)
- **GitHub**: Source control and project management

## Governance

This project operates under the governance framework defined in `doc/internal/governance/`:

- **ADRs**: Architectural decisions affecting system design
- **PDRs**: Process decisions affecting workflow and operations
- **POLs**: Policies establishing standards and compliance requirements

Major changes to project scope, vision, or objectives require updates to this charter.

## Related Documents

- [Initial Thoughts](./initial-thoughts.md) - Original project inception notes
- [Roadmap](./ROADMAP.md) - Timeline and milestones
- [Governance Framework](./governance/) - ADRs, PDRs, and POLs
