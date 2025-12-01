# Feature: Tenant Provisioning

**Feature ID**: EMS-F001  
**Status**: Planned  
**Priority**: Critical (P0)  
**Seam Levels**: Seam 1 (Tenant)

## Overview

Tenant Provisioning enables platform administrators to onboard new customers by creating tenant records with their subscription plans, initial admin users, and service entitlements.

## Business Context

**Problem**: New customers cannot use the platform until their tenant infrastructure is provisioned.

**Solution**: Automated tenant provisioning that creates tenant record, admin user, subscription configuration, and service entitlements in a single atomic operation.

**Value**: Reduces customer onboarding time from hours to seconds; ensures consistent tenant setup.

## User Stories

**US-001**: As a platform administrator, I want to provision new tenants so that customers can start using the platform.

**US-002**: As a platform administrator, I want tenants to have subscription plans (Bronze/Silver/Gold) so that entitlements are automatically configured.

**US-003**: As a system, I want to prevent duplicate tenant names so that tenant identification remains unambiguous.

## Functional Requirements

### Command: CreateTenant

**Input**:
```json
{
  "name": "Acme Corp",
  "subscription_plan": "bronze",
  "admin_email": "admin@acme.example.com",
  "admin_name": "Jane Admin"
}
```

**Output** (Success):
```json
{
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Acme Corp",
  "subscription_plan": "bronze",
  "status": "active",
  "created_at": "2025-01-15T10:30:00Z",
  "admin_user_id": "660e8400-e29b-41d4-a716-446655440000"
}
```

**Business Rules**:
- BR-001: Tenant name must be unique across platform
- BR-002: Subscription plan must be one of: bronze, silver, gold
- BR-003: Admin email must be valid email format
- BR-004: Tenant receives entitlements based on subscription plan
- BR-005: Admin user automatically receives "tenant-owner" role

### Events Published

**TenantProvisioned**:
```json
{
  "event_type": "tenant.provisioned",
  "tenant_id": "550e8400...",
  "data": {
    "tenant_name": "Acme Corp",
    "subscription_plan": "bronze",
    "admin_user_id": "660e8400..."
  },
  "metadata": {
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

## Multi-Tenant Considerations

**Seam Level 1 (Tenant)**:
- Creates new tenant boundary
- Establishes tenant_id for all future operations
- Initializes tenant-specific configuration

**Isolation**:
- Each tenant provisioned independently
- Tenant data isolated from creation
- No cross-tenant visibility

## Non-Functional Requirements

- **Performance**: Provisioning completes in <2 seconds P95
- **Reliability**: Atomic operation (all-or-nothing)
- **Idempotency**: Duplicate requests with same name return 409
- **Audit**: All provisioning logged for compliance

## Testing Strategy

See companion `tenant-provisioning.feature` file for BDD scenarios.

**Test Coverage**:
- ✅ Happy path (Bronze/Silver/Gold plans)
- ✅ Validation errors (invalid plan, duplicate name)
- ✅ Edge cases (special characters in name, long names)
- ✅ Cross-tenant isolation verification

## Dependencies

- Provisioning Service: Supplies subscription plan configuration
- Authentication Service: Creates admin user credentials
- Kafka: Event publishing

## Metrics

- `tenants_provisioned_total` (counter) - Total tenants created
- `tenant_provisioning_duration_seconds` (histogram) - Provisioning latency
- `tenant_provisioning_errors_total` (counter) - Failed provisioning attempts

## Acceptance Criteria

- [ ] Tenant can be provisioned via POST /api/v1/tenants
- [ ] Subscription plan validation enforced
- [ ] Duplicate name prevention working
- [ ] Admin user created with tenant-owner role
- [ ] TenantProvisioned event published to Kafka
- [ ] Provisioning completes in <2s P95
- [ ] All BDD scenarios passing
