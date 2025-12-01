# {Service Name} Service Charter

**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Template Version**: 1.0

---

**Instructions**: Copy this template to service repository root as `SERVICE-CHARTER.md`. This document establishes the service's mission, scope, and strategic goals. Think of this as the "constitution" for your service - the foundational document that guides all design decisions.

---

## Service Identity

**Service Name**: {Full service name}  
**Repository**: `TJMSolns-{ServiceName}`  
**Owner**: {Team or individual name}  
**Status**: {Development / Production / Deprecated}

## Mission Statement

{One paragraph describing why this service exists and what problem it solves}

**Example**:
> Entity Management Service provides the foundational tenant and user management capabilities for TJMPaaS multi-tenant architecture. It enables organizations to onboard as tenants, provision services, manage users, and enforce multi-tenant isolation across the platform.

## Business Value

### Primary Stakeholders

| Stakeholder | Need | How Service Addresses |
|-------------|------|---------------------|
| {Role} | {Specific need} | {How service provides value} |

**Example**:
| Stakeholder | Need | How Service Addresses |
|-------------|------|---------------------|
| Platform Operators | Onboard new tenants efficiently | Automated tenant provisioning workflows |
| Tenant Administrators | Manage users and permissions | Self-service user management APIs |
| Service Developers | Enforce multi-tenant isolation | Tenant context validation middleware |

### Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| {Metric name} | {Target value} | {How to measure} |

**Example**:
| Metric | Target | Measurement |
|--------|--------|-------------|
| Tenant provisioning time | <30 seconds | P95 latency from request to ready |
| User onboarding success rate | >99% | Successful invitations / total invitations |
| Multi-tenant isolation enforcement | 100% | Zero cross-tenant data leaks |

## Scope

### In Scope

- {Capability 1}
- {Capability 2}
- {Capability 3}

### Out of Scope

- {Explicitly not provided}
- {Delegated to other services}

### Boundaries

**Upstream Dependencies** (services this service calls):
- {Service A}: {What for}
- {Service B}: {What for}

**Downstream Consumers** (services that call this service):
- {Service X}: {What they need}
- {Service Y}: {What they need}

**Integration Points**:
- {Integration type}: {Description}

## Strategic Goals

### Short Term (Q1-Q2 2026)

- {Goal 1}
- {Goal 2}
- {Goal 3}

### Long Term (2026-2027)

- {Strategic goal 1}
- {Strategic goal 2}

## Constraints and Assumptions

### Technical Constraints

- {Constraint 1}
- {Constraint 2}

### Business Constraints

- {Constraint 1}
- {Constraint 2}

### Assumptions

- {Assumption 1}
- {Assumption 2}

## Governance

### Decision Authority

| Decision Type | Authority | Process |
|---------------|-----------|---------|
| Architecture changes | {Role/Team} | ADR required |
| API breaking changes | {Role/Team} | PDR + customer notification |
| Feature prioritization | {Role/Team} | Roadmap review |

### Related Governance Documents

- [ADR-XXXX: {Title}](../../governance/ADRs/ADR-XXXX-title.md) - {Why relevant}
- [PDR-XXXX: {Title}](../../governance/PDRs/PDR-XXXX-title.md) - {Why relevant}

## Revision History

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial charter | {Name} |

---

**Next Steps After Creating Charter**:
1. Create `SERVICE-CANVAS.md` (comprehensive overview)
2. Create `SERVICE-ARCHITECTURE.md` (detailed design)
3. Create `API-SPECIFICATION.md` (OpenAPI spec)
4. Create feature documentation in `features/` directory
