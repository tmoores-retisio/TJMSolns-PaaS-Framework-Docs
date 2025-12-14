# Entity Management Service - Security Requirements

**Status**: Active  
**Version**: 1.0.0  
**Last Updated**: 2025-11-29  
**Template**: [SECURITY-REQUIREMENTS.md](../../governance/templates/SECURITY-REQUIREMENTS.md)

---

## Authentication

- JWT (RS256) on all endpoints
- Token includes tenant_id claim (validated against X-Tenant-ID header)
- Token expiry: 1 hour (access), 30 days (refresh)
- Public key cached for signature validation

## Authorization

- RBAC model with 4 roles: tenant-owner, tenant-admin, org-admin, team-member
- Permissions format: `entity-management:action:scope`
- Permission evaluation cached (5-minute TTL)

## Multi-Tenant Isolation

**Seam 1 (Tenant)**:
- X-Tenant-ID header required on all requests
- JWT tenant_id claim must match header
- All database queries filtered: `WHERE tenant_id = ?`
- Kafka events partitioned by tenant_id

**Seam 2 (Service Entitlement)**:
- Organization feature per subscription plan
- Feature flags checked before command processing

**Seam 3 (Feature Limits)**:
- User invitations rate limited by tier
- API calls rate limited by tier
- Quota enforcement with Redis counters

**Seam 4 (Role Permissions)**:
- Role hierarchy enforced
- Permission evaluation for all operations
- Scope-based access control (tenant/org/team)

## Data Protection

- **At-Rest**: Email addresses encrypted (AES-256-GCM)
- **In-Transit**: TLS 1.3 for all connections
- **Audit Log**: All entity changes logged (immutable, 7-year retention)

## Input Validation

- All inputs validated before processing
- SQL injection prevention: Parameterized queries only
- XSS prevention: Input sanitization, CSP headers
- Email validation: RFC 5322 compliant

## Security Headers

- `Content-Security-Policy`: Restrict resource loading
- `Strict-Transport-Security`: Force HTTPS
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`

## Threat Model (STRIDE)

**Spoofing**: JWT authentication prevents impersonation  
**Tampering**: Immutable event store prevents data modification  
**Repudiation**: Audit logging provides non-repudiation  
**Information Disclosure**: Multi-tenant isolation prevents data leakage  
**Denial of Service**: Rate limiting prevents abuse  
**Elevation of Privilege**: RBAC prevents unauthorized access

## Compliance

- **GDPR**: Right to erasure (soft delete + anonymization)
- **PCI-DSS**: No payment card data stored
- **SOC2**: Access controls, audit logging, encryption

---

See [SECURITY-REQUIREMENTS.md template](../../governance/templates/SECURITY-REQUIREMENTS.md) for complete requirements.
