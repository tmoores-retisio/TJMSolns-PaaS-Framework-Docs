# ADR-0001: Google Cloud Platform as Pilot Cloud Provider

**Status**: Accepted  
**Date**: 2025-11-26  
**Deciders**: Tony Moores  
**Technical Story**: Phase 0 - Foundation

## Context

TJMPaaS requires a cloud infrastructure platform to pilot the containerized services library. The platform selection impacts:

- Initial development velocity
- Infrastructure costs during pilot phase
- Container orchestration capabilities
- Future multi-cloud portability requirements
- Existing organizational infrastructure and expertise

### Problem Statement

Select an initial cloud platform that enables rapid prototyping and validation while maintaining architectural decisions that support future multi-cloud deployment.

### Goals

- Leverage existing TJMSolns infrastructure investments
- Minimize friction during pilot phase
- Maintain cloud portability for future expansion
- Support containerized workloads effectively
- Enable cost-effective experimentation

### Constraints

- TJMSolns already has active GCP account and Google Workspace integration
- Tony is sole administrator (minimize operational complexity)
- Budget-conscious pilot phase
- Must support eventual multi-cloud strategy
- Need robust container orchestration (Kubernetes)

## Decision

**Use Google Cloud Platform (GCP) as the initial pilot cloud provider**, leveraging:

- Google Kubernetes Engine (GKE) for container orchestration
- Cloud Build for CI/CD pipelines
- Cloud Run for serverless containers (where appropriate)
- Cloud Storage for object storage
- Cloud SQL for managed databases
- Cloud IAM integrated with Google Workspace

## Rationale

### Existing Infrastructure

TJMSolns already uses:
- Google Workspace for business operations
- GCP account with established billing
- Familiarity with Google ecosystem

### Technical Capabilities

GCP provides:
- Industry-leading Kubernetes (GKE is based on Google's internal Borg)
- Excellent container tooling and registry (Artifact Registry)
- Strong serverless options (Cloud Run)
- Integrated IAM with Google Workspace
- Comprehensive monitoring (Cloud Operations)

### Cost Management

- Committed use discounts available
- Sustainable usage tier for experimentation
- Pay-as-you-go aligns with pilot phase
- Cost controls and budgeting tools

### Multi-Cloud Preparation

Using GCP first while designing for portability:
- Kubernetes abstracts orchestration layer
- Standard container images work across clouds
- Infrastructure-as-Code patterns are transferable
- Service mesh (Istio) is cloud-agnostic

## Alternatives Considered

### Alternative 1: Amazon Web Services (AWS)

**Description**: Use AWS as pilot platform with EKS for Kubernetes

**Pros**:
- Largest cloud provider market share
- Most comprehensive service catalog
- Extensive documentation and community
- Strong enterprise adoption

**Cons**:
- No existing AWS infrastructure or investment
- Learning curve for AWS-specific services
- More complex IAM model
- Higher operational overhead for single administrator
- No integration with existing Google Workspace

**Reason for rejection**: Lack of existing infrastructure and additional complexity during pilot phase outweigh market position benefits

### Alternative 2: Microsoft Azure

**Description**: Use Azure as pilot platform with AKS for Kubernetes

**Pros**:
- Strong enterprise integration
- Good hybrid cloud capabilities
- Growing Kubernetes support (AKS)
- Microsoft ecosystem integration

**Cons**:
- No existing Azure infrastructure
- Less natural fit with Google Workspace
- Learning curve for Azure services
- Cost structure less favorable for experimentation

**Reason for rejection**: No existing investment and less alignment with current tooling

### Alternative 3: Multi-Cloud from Start

**Description**: Deploy to multiple clouds simultaneously from beginning

**Pros**:
- Immediate validation of portability
- No single vendor lock-in
- Cloud-agnostic from day one

**Cons**:
- 3x operational complexity
- Significantly higher costs
- Slower iteration during pilot
- Resource constraint (solo administrator)
- Premature optimization

**Reason for rejection**: Excessive complexity for pilot phase; can validate portability patterns without parallel deployment

## Consequences

### Positive

- **Faster Start**: Leverage existing GCP knowledge and infrastructure
- **Integrated IAM**: Google Workspace integration simplifies authentication
- **Cost Efficiency**: Existing account, committed use discounts
- **Strong Kubernetes**: GKE is mature and well-supported
- **Reduced Complexity**: Single cloud focus during learning phase

### Negative

- **GCP-Specific Knowledge**: Some learnings may not transfer directly
- **Portability Risk**: Must remain vigilant about cloud-specific dependencies
- **Future Migration**: Will need validation when expanding to other clouds
- **Vendor Relationship**: Building deeper GCP dependency during pilot

### Neutral

- **Market Position**: GCP is #3 cloud provider but sufficient for needs
- **Service Gaps**: Some specialized services may require alternatives
- **Community**: Smaller but adequate community compared to AWS

## Implementation

### Requirements

- Maintain GCP account with appropriate billing alerts
- Use Infrastructure-as-Code (Terraform or similar) from start
- Document GCP-specific vs. portable patterns
- Design services with cloud abstraction in mind
- Regular cost review and optimization

### Migration Path

When expanding to other clouds:
1. Validate container images work on target platform
2. Translate IaC to target cloud (or use multi-cloud tools)
3. Test service mesh and networking on target platform
4. Implement cloud-agnostic configuration management
5. Document platform-specific adaptations needed

### Timeline

- **Phase 0 (Q4 2025)**: GCP pilot environment setup
- **Phase 1-3 (2026)**: Service development on GCP
- **Phase 4 (Q4 2026)**: Multi-cloud architecture assessment
- **Phase 5+ (2027)**: Potential expansion to AWS/Azure

## Validation

Success criteria for this decision:

- Services run successfully on GKE
- Infrastructure costs remain within pilot budget
- Architecture patterns support future portability (validated through design reviews)
- No critical service gaps that require alternative cloud
- Operational overhead manageable for solo administrator

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| GCP-specific lock-in | Medium | Use Kubernetes extensively; avoid proprietary services where possible |
| Cost overruns | Medium | Implement budget alerts; regular cost reviews; use committed use discounts |
| Service limitations | Low | Evaluate service catalog early; identify gaps before deep commitment |
| Future migration complexity | Medium | Document architecture decisions; maintain cloud-agnostic design principles |
| Skill transfer concerns | Low | Focus on portable skills (Kubernetes, containers, IaC patterns) |

## Related Decisions

- ADR-0003: Containerization as core strategy (supports portability)
- Future ADR: Kubernetes orchestration approach
- Future ADR: Infrastructure-as-Code tool selection

## References

- [GCP Documentation](https://cloud.google.com/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Google Workspace Integration](https://cloud.google.com/identity/docs)
- [Initial Thoughts](../../initial-thoughts.md) - Original vision for multi-cloud

## Notes

This decision explicitly supports the vision outlined in `initial-thoughts.md` of piloting on GCP with future multi-cloud expansion. The key is maintaining architectural discipline to enable that future expansion without requiring complete rewrites.

The decision prioritizes practical constraints (existing infrastructure, solo administration) while keeping strategic goals (multi-cloud, commercialization) achievable through thoughtful design patterns.

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-26 | Initial draft and acceptance | Tony Moores |
