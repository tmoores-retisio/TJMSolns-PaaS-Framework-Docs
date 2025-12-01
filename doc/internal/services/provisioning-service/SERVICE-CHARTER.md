# Provisioning Service - Service Charter

**Status**: Planned (Not Yet Implemented)  
**Service Type**: Platform Infrastructure Service  
**Domain**: Cross-Cutting (Tenant Lifecycle Management)  
**Owner**: TJM Solutions / TJMPaaS Platform Team  
**Last Updated**: 2025-11-27

---

## 1. Service Identity

### Service Name
**Provisioning Service**

### Mission Statement
Provide centralized, automated provisioning and entitlement management for all tenants, services, and features across the TJMPaaS platform, ensuring consistent application of subscription plans, progressive familiarity levels, and operational DRY principles.

### Vision
The Provisioning Service acts as the **single source of truth** for:
- Tenant subscription plan definitions (Bronze, Silver, Gold, Enterprise)
- Service and feature entitlement matrices
- Progressive familiarity progression tracking (50% → 75% → 87.5% → 100%)
- Automated provisioning workflows
- Entitlement validation and enforcement

By centralizing provisioning logic, we eliminate duplication across services, ensure consistent entitlement enforcement, and provide a clear operational control point for tenant lifecycle management.

### Strategic Alignment

**Aligns With**:
- **PROVISIONING-SERVICE-PATTERN.md**: Implements the DRY operational control pattern for multi-tenant entitlement management
- **MULTI-TENANT-SEAM-ARCHITECTURE.md**: Enforces Seam 2 (Tenant-Service) and Seam 3 (Tenant-Service-Feature) boundaries
- **POL-cross-service-consistency.md**: Ensures consistent entitlement enforcement across all services

**Supports**:
- **Entity Management Service**: Provides tenant provisioning and entitlement validation
- **All TJMPaaS Services**: Centralized entitlement checks for features and capabilities
- **Subscription Management**: Backend for subscription plan changes and upgrades

---

## 2. Business Context

### Problem Statement
Without centralized provisioning:
- Each service must duplicate subscription plan logic
- Entitlement checks scattered across services (violates DRY)
- Inconsistent feature availability enforcement
- Difficult to add new subscription plans
- No single view of tenant entitlements
- Progressive familiarity tracking fragmented

### Target Users
**Primary**:
- **Platform Administrators**: Provision new tenants, manage subscription plans
- **TJMPaaS Services**: Query entitlements, validate feature access
- **Tenant Administrators**: Request subscription changes (future self-service)

**Secondary**:
- **Support Teams**: Troubleshoot entitlement issues
- **Billing System**: Sync subscription status
- **Analytics**: Track feature adoption by plan

### Business Value
- **Operational Efficiency**: Centralized provisioning reduces operational overhead
- **Consistency**: Single source of truth for entitlements eliminates discrepancies
- **Agility**: New subscription plans added without service changes
- **Compliance**: Audit trail for all entitlement changes
- **Progressive Familiarity**: Automated tracking and progression

### Success Metrics
- Tenant provisioning time: < 2 seconds P95
- Entitlement check latency: < 5ms P95 (cached)
- Zero entitlement inconsistencies across services
- 100% audit trail coverage for provisioning events
- Self-service provisioning adoption: > 80% (future)

---

## 3. Strategic Foundation

### Core Capabilities

#### 3.1 Subscription Plan Management
- Define and manage subscription plan templates (Bronze/Silver/Gold/Enterprise)
- Configure entitlements per plan:
  - Service access (Entity Management, Order Management, etc.)
  - Feature availability per service
  - Resource limits (users, API calls, storage)
  - Progressive familiarity initial level

**Example Plan Definition**:
```json
{
  "plan_id": "gold",
  "name": "Gold Plan",
  "entitlements": {
    "services": {
      "entity-management": {
        "enabled": true,
        "features": ["tenant-provisioning", "organization-hierarchy", "user-management", "role-permissions", "audit-trail"],
        "progressive_familiarity_level": "87.5%"
      }
    },
    "resource_limits": {
      "max_users": 1000,
      "max_api_calls_per_day": 1000000,
      "max_storage_gb": 500
    }
  }
}
```

#### 3.2 Tenant Provisioning
- Automated tenant provisioning workflow:
  1. Validate subscription plan
  2. Create tenant in Entity Management Service
  3. Provision entitlements based on plan
  4. Initialize progressive familiarity tracking
  5. Emit TenantProvisioned event
  6. Notify downstream services

#### 3.3 Entitlement Validation
- Real-time entitlement checks for services:
  - **Service Access**: Can tenant access this service?
  - **Feature Access**: Can tenant use this feature?
  - **Resource Limits**: Has tenant exceeded limits?
  - **Progressive Familiarity**: What UI complexity should be shown?

**Example API**:
```
GET /api/v1/entitlements/{tenant_id}/check?service=entity-management&feature=role-permissions
Response: {"entitled": true, "progressive_familiarity": "87.5%"}
```

#### 3.4 Progressive Familiarity Management
- Track tenant's familiarity progression (50% → 75% → 87.5% → 100%)
- Trigger level advancement based on usage patterns
- Emit ProgressiveFamiliarityAdvanced events
- Provide UI complexity recommendations

### Boundaries & Interfaces

**Owns**:
- Subscription plan definitions
- Tenant-to-plan assignments
- Entitlement validation logic
- Progressive familiarity state

**Does NOT Own**:
- Tenant identity data (Entity Management Service)
- Billing/payments (separate Billing Service)
- Service-specific features (individual services)
- User authentication (Authentication Service)

**Integration Points**:
- **Entity Management Service**: Consumes tenant provisioning, provides entitlement validation
- **All TJMPaaS Services**: Query entitlements before exposing features
- **Billing Service** (future): Subscription changes trigger entitlement updates
- **Event Bus (Kafka)**: Publishes entitlement events

### Technology Stack (Planned)

**Language/Runtime**: Scala 3, functional programming paradigm  
**Actor System**: Pekko (Apache 2.0) for SubscriptionPlanActor, EntitlementActor  
**Effect System**: ZIO for pure functional effects  
**HTTP**: http4s for REST API  
**Event Streaming**: Kafka for entitlement events  
**Storage**: PostgreSQL for subscription plans and entitlements  
**Caching**: Redis for low-latency entitlement checks  

**Rationale**: Aligns with TJMPaaS technology standards (ADR-0004, ADR-0006)

---

## 4. Implementation Vision (High-Level)

### Architecture Approach
**Actor-Based Design**:
- **SubscriptionPlanActor**: Manages subscription plan definitions
- **TenantEntitlementActor**: Manages entitlements for a specific tenant (one actor per tenant)
- **ProgressiveFamiliarityActor**: Tracks familiarity progression

**CQRS Pattern**:
- **Commands**: ProvisionTenant, UpdateSubscriptionPlan, CheckEntitlement
- **Events**: TenantProvisioned, SubscriptionPlanChanged, ProgressiveFamiliarityAdvanced
- **Read Model**: Cached entitlements for fast lookups

### Key APIs (Planned)

**Provisioning API**:
```
POST /api/v1/tenants/{tenant_id}/provision
Body: {"subscription_plan": "gold", "admin_email": "admin@example.com"}
```

**Entitlement Check API**:
```
GET /api/v1/entitlements/{tenant_id}/check?service=X&feature=Y
Response: {"entitled": true|false, "reason": "...", "progressive_familiarity": "87.5%"}
```

**Subscription Plan API**:
```
GET /api/v1/subscription-plans
GET /api/v1/subscription-plans/{plan_id}
```

### Event Schema
**TenantProvisioned**:
```json
{
  "type": "com.tjmsolutions.provisioning.tenant.provisioned.v1",
  "specversion": "1.0",
  "tenant_id": "tenant-123",
  "data": {
    "subscription_plan": "gold",
    "entitlements": { ... },
    "progressive_familiarity_level": "87.5%",
    "provisioned_at": "2025-11-27T10:00:00Z"
  }
}
```

---

## 5. Dependencies & Risks

### Dependencies
**Upstream** (Services Provisioning Service Depends On):
- Entity Management Service: Tenant data
- Authentication Service: API authentication

**Downstream** (Services That Depend On Provisioning Service):
- All TJMPaaS services: Entitlement validation
- Billing Service (future): Subscription changes

### Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Single point of failure | High | Deploy with high availability (3+ replicas), implement circuit breakers in services, cache entitlements (5-minute TTL) |
| Entitlement cache staleness | Medium | Short TTL (5 min), publish entitlement change events, services invalidate cache |
| Provisioning workflow complexity | Medium | Use sagas for multi-step provisioning, idempotent operations, comprehensive testing |
| Subscription plan changes | Medium | Versioned plan definitions, migration scripts for plan changes |

---

## 6. Open Questions & Future Considerations

### Open Questions (To Be Resolved)
1. **Self-Service Provisioning**: Should tenant admins be able to upgrade/downgrade plans directly, or only through platform admin?
2. **Trial Plans**: How to handle trial subscriptions with time limits?
3. **Custom Plans**: Should we support custom subscription plans for enterprise customers?
4. **Entitlement Caching Strategy**: Redis vs in-memory cache per service? Trade-offs?
5. **Progressive Familiarity Triggers**: What usage patterns trigger familiarity level advancement?

### Future Enhancements
- **Entitlement Templates**: Reusable entitlement bundles
- **Feature Flags Integration**: Dynamic feature rollout per tenant
- **Usage-Based Entitlements**: Metered features (API calls, storage)
- **Entitlement History**: Temporal queries for entitlement changes
- **Multi-Region Provisioning**: Provision tenants in specific geographic regions

---

## 7. Next Steps

### To Complete This Charter
This is a **stub/vision document**. To make this service implementation-ready, we need:

1. **Complete Architecture Document**: Detailed actor design, CQRS patterns, caching strategy
2. **API Specification**: Full OpenAPI spec with all endpoints
3. **Feature Specifications**: BDD scenarios for subscription plan management, provisioning workflows, entitlement checks
4. **Deployment Runbook**: Infrastructure requirements, scaling strategy, failover procedures
5. **Security Requirements**: Authentication, authorization, audit logging
6. **Telemetry Specification**: Metrics, logs, traces for observability

### Gap Analysis Reference
See **STANDARDS-GAPS.md** for analysis of what's missing to make this service (and others) production-ready.

---

## 8. References

**TJMPaaS Standards**:
- [PROVISIONING-SERVICE-PATTERN.md](../../standards/PROVISIONING-SERVICE-PATTERN.md): DRY operational control pattern
- [MULTI-TENANT-SEAM-ARCHITECTURE.md](../../standards/MULTI-TENANT-SEAM-ARCHITECTURE.md): Seam enforcement
- [API-DESIGN-STANDARDS.md](../../standards/API-DESIGN-STANDARDS.md): REST API design
- [EVENT-SCHEMA-STANDARDS.md](../../standards/EVENT-SCHEMA-STANDARDS.md): CloudEvents format

**Related Services**:
- [Entity Management Service](../entity-management/SERVICE-CHARTER.md): Tenant and user management (implemented)

**Templates**:
- [SERVICE-CHARTER.md](../../templates/SERVICE-CHARTER.md): This document follows the charter template

---

**Document Status**: This is a **vision/stub** document showing the planned Provisioning Service. Not yet implemented. Intended to demonstrate the SERVICE-CHARTER template and serve as a reference for gap analysis.

**Next Deliverable**: Gap analysis (STANDARDS-GAPS.md) identifying what's needed to make this production-ready.
