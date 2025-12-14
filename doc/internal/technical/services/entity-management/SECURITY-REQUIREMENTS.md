# Entity Management Service - Security Requirements

**Status**: Active  
**Version**: 1.0.0  
**Last Updated**: 2025-12-14  
**Template**: [SECURITY-REQUIREMENTS.md](../../governance/templates/SECURITY-REQUIREMENTS.md)  
**Security Standard**: [SECURITY-JWT-PERMISSIONS.md](../../standards/SECURITY-JWT-PERMISSIONS.md)

---

## Authentication

**Implements**: [SECURITY-JWT-PERMISSIONS.md](../../standards/SECURITY-JWT-PERMISSIONS.md) standard

- JWT (RS256) on all endpoints per SECURITY-JWT-PERMISSIONS standard
- Token includes tenant_id claim (validated against X-Tenant-ID header - mandatory)
- Token expiry: 1 hour (access), 30 days (refresh with rotation)
- Token validation: RS256 signature verification + claim checks
- Public keys fetched from JWKS endpoint (`/.well-known/jwks.json`)
- Public key cached for 1 hour
- Token revocation via token_version claim (incremented on security events)
- Refresh token blacklist in Redis for immediate revocation

## Authorization

**Implements**: Permission model from [SECURITY-JWT-PERMISSIONS.md](../../standards/SECURITY-JWT-PERMISSIONS.md)

- RBAC model with 4 built-in roles: tenant-owner, tenant-admin, org-admin, team-member
- Custom roles supported (1,000+ per tenant)
- **Permissions format**: `service:action:scope` per SECURITY-JWT-PERMISSIONS standard
  - Service: `entity-management`
  - Actions: `read`, `write`, `delete`, `approve`, `admin`, `*` (wildcard)
  - Scopes: `*` (all), `own` (user-owned), `organization`, `{resource_type}`
- **Permission hierarchy**: Negative permissions (`!`) override positive, wildcard matching supported
- **Permission evaluation**: Cached 5-minute TTL for <1ms checks
- **Permission enforcement**: Akka HTTP directives (`requirePermission`, `requireRole`)
- **Cache invalidation**: Event-driven updates when roles/permissions change

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

## Error Handling Security

**Standard**: [ERROR-HANDLING-STANDARDS.md](../../standards/ERROR-HANDLING-STANDARDS.md)

### Sensitive Data Protection

- **No sensitive data in error responses**: Stack traces, database details, internal IDs excluded in production
- **Generic error messages for system errors**: "An unexpected error occurred. Contact support with request ID: req-abc-123"
- **Detailed validation errors only**: Field-level errors included for client corrections
- **Cross-tenant leak prevention**: Resources in another tenant return 404 (not 403)

### Error Rate Limiting

- **Authentication failures**: Max 5 attempts per IP/15 minutes (429 Too Many Requests)
- **API errors**: Counted toward tier rate limits (no separate error allowance)
- **Error-based enumeration prevention**: Timing attacks mitigated (constant-time responses)

### Error Correlation

- **request_id in all error responses**: Enables support debugging without exposing internals
- **tenant_id in authenticated errors**: Enables tenant-scoped debugging
- **trace_id in distributed errors**: Correlates errors across services
- **Structured error logging**: All errors logged with full context (request_id, tenant_id, user_id, trace_id)

## Compliance

- **GDPR**: Right to erasure (soft delete + anonymization)
- **PCI-DSS**: No payment card data stored
- **SOC2**: Access controls, audit logging, encryption

---

See [SECURITY-REQUIREMENTS.md template](../../governance/templates/SECURITY-REQUIREMENTS.md) for complete requirements.
