# TJMPaaS Project Charter

**Version**: 1.0  
**Date**: November 26, 2025  
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
- **Cloud Infrastructure**: Initial deployment on Google Cloud Platform (GCP)
- **Documentation**: Comprehensive internal documentation for architecture, operations, and governance
- **Multi-Cloud Planning**: Design decisions that enable future cloud portability
- **Pilot Phase**: Initial implementation and validation on TJMSolns' GCP infrastructure

### Out of Scope (Current Phase)

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
2. **GCP Pilot Success**: Successfully deploy and validate services on GCP infrastructure
3. **Documentation Excellence**: Maintain comprehensive, knowledge-base-ready documentation
4. **Cloud Portability**: Design with multi-cloud deployment as a future capability

### Success Metrics

- Number of production-ready containerized services
- Successful deployment and operation on GCP
- Documentation completeness and accessibility
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
