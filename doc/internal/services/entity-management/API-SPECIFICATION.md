# Entity Management Service - API Specification

**Status**: Active  
**Version**: 1.0.0 (OpenAPI 3.1.0)  
**Last Updated**: 2025-11-29  
**Template**: [API-SPECIFICATION.md](../../governance/templates/API-SPECIFICATION.md)

---

## API Overview

**Base URL**: `https://api.tjmpaas.com/api/v1`  
**Authentication**: JWT (RS256) in Authorization header  
**Multi-Tenancy**: X-Tenant-ID header required (must match JWT tenant_id claim)  
**Rate Limiting**: By tenant subscription tier (1000/10000/100000 req/hour)  
**Response Format**: JSON with HATEOAS links

---

## Authentication

**Security Standard**: [SECURITY-JWT-PERMISSIONS.md](../../technical/standards/SECURITY-JWT-PERMISSIONS.md)

All endpoints require JWT authentication with RS256 algorithm:

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
X-Tenant-ID: 550e8400-e29b-41d4-a716-446655440000
```

**JWT Claims Required** (per SECURITY-JWT-PERMISSIONS standard):
- `tenant_id`: Must match X-Tenant-ID header (mandatory validation)
- `user_id`: Authenticated user ID (from `sub` claim)
- `roles`: Array of role names for authorization
- `permissions`: Array of permissions in `service:action:scope` format

**Token Validation**:
1. Verify RS256 signature using public key from JWKS endpoint
2. Verify standard claims (iss, aud, exp, iat)
3. Verify `tenant_id` matches X-Tenant-ID header (cross-tenant prevention)
4. Verify `token_version` (not revoked)
5. Cache validated claims for 1 hour (until expiry)

**Permission Checking**:
- Permissions evaluated from JWT `permissions` array
- Format: `entity-management:action:scope` (e.g., `entity-management:write:own`)
- Cached for 5 minutes per user for <1ms checks
- See SECURITY-JWT-PERMISSIONS standard for complete enforcement algorithm

---

## Tenant Management

### Create Tenant

```http
POST /tenants
Content-Type: application/json
Authorization: Bearer <jwt>
X-Tenant-ID: <tenant-id>

{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Acme Corporation",
  "subscription_plan": "silver"
}
```

**Response** (202 Accepted):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Acme Corporation",
  "subscription_plan": "silver",
  "created_at": "2025-11-29T10:00:00Z",
  "_links": {
    "self": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000" },
    "organizations": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000/organizations" },
    "users": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000/users" }
  }
}
```

**Errors**:
- `400 Bad Request`: Invalid tenant data
- `401 Unauthorized`: Missing/invalid JWT
- `403 Forbidden`: Tenant ID mismatch
- `409 Conflict`: Tenant already exists

### Get Tenant

```http
GET /tenants/{tenantId}
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}
```

**Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Acme Corporation",
  "subscription_plan": "silver",
  "organization_count": 5,
  "user_count": 42,
  "created_at": "2025-11-29T10:00:00Z",
  "updated_at": "2025-11-29T12:00:00Z",
  "_links": {
    "self": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000" },
    "organizations": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000/organizations" },
    "users": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000/users" }
  }
}
```

---

## Organization Management

### Create Organization

```http
POST /tenants/{tenantId}/organizations
Content-Type: application/json
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}

{
  "id": "650e8400-e29b-41d4-a716-446655440000",
  "name": "Engineering Department",
  "parent_organization_id": null
}
```

**Response** (202 Accepted):
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Engineering Department",
  "parent_organization_id": null,
  "team_count": 0,
  "member_count": 0,
  "created_at": "2025-11-29T10:05:00Z",
  "_links": {
    "self": { "href": "/organizations/650e8400-e29b-41d4-a716-446655440000" },
    "tenant": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000" },
    "teams": { "href": "/organizations/650e8400-e29b-41d4-a716-446655440000/teams" },
    "members": { "href": "/organizations/650e8400-e29b-41d4-a716-446655440000/members" }
  }
}
```

### List Organizations

```http
GET /tenants/{tenantId}/organizations?page=1&page_size=20
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}
```

**Response** (200 OK):
```json
{
  "organizations": [
    {
      "id": "650e8400-e29b-41d4-a716-446655440000",
      "name": "Engineering Department",
      "team_count": 3,
      "member_count": 15,
      "created_at": "2025-11-29T10:05:00Z"
    }
  ],
  "page": 1,
  "page_size": 20,
  "total": 5,
  "_links": {
    "self": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000/organizations?page=1" },
    "next": { "href": "/tenants/550e8400-e29b-41d4-a716-446655440000/organizations?page=2" }
  }
}
```

---

## User Management

### Invite User

```http
POST /tenants/{tenantId}/users/invite
Content-Type: application/json
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}

{
  "email": "alice@acme.com",
  "role": "org-admin",
  "organization_id": "650e8400-e29b-41d4-a716-446655440000"
}
```

**Response** (202 Accepted):
```json
{
  "user_id": "750e8400-e29b-41d4-a716-446655440000",
  "email": "alice@acme.com",
  "status": "pending",
  "invited_at": "2025-11-29T10:10:00Z",
  "invitation_expires_at": "2025-12-06T10:10:00Z",
  "_links": {
    "self": { "href": "/users/750e8400-e29b-41d4-a716-446655440000" },
    "activate": { "href": "/users/750e8400-e29b-41d4-a716-446655440000/activate" }
  }
}
```

**Business Rules**:
- Email must be unique within tenant
- Invitation valid for 7 days
- Rate limited by tenant tier (10/100/unlimited per month)

### Get User

```http
GET /users/{userId}
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}
```

**Response** (200 OK):
```json
{
  "id": "750e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alice@acme.com",
  "status": "active",
  "created_at": "2025-11-29T10:10:00Z",
  "activated_at": "2025-11-29T11:00:00Z",
  "_links": {
    "self": { "href": "/users/750e8400-e29b-41d4-a716-446655440000" },
    "roles": { "href": "/users/750e8400-e29b-41d4-a716-446655440000/roles" },
    "permissions": { "href": "/users/750e8400-e29b-41d4-a716-446655440000/permissions" }
  }
}
```

---

## Role Management

### Assign Role

```http
POST /users/{userId}/roles
Content-Type: application/json
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}

{
  "role": "org-admin",
  "scope": {
    "type": "organization",
    "id": "650e8400-e29b-41d4-a716-446655440000"
  }
}
```

**Response** (202 Accepted):
```json
{
  "user_id": "750e8400-e29b-41d4-a716-446655440000",
  "role": "org-admin",
  "scope": {
    "type": "organization",
    "id": "650e8400-e29b-41d4-a716-446655440000",
    "name": "Engineering Department"
  },
  "assigned_at": "2025-11-29T10:15:00Z",
  "_links": {
    "user": { "href": "/users/750e8400-e29b-41d4-a716-446655440000" },
    "organization": { "href": "/organizations/650e8400-e29b-41d4-a716-446655440000" }
  }
}
```

### Get User Roles

```http
GET /users/{userId}/roles
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}
```

**Response** (200 OK):
```json
{
  "roles": [
    {
      "role": "tenant-admin",
      "scope": { "type": "tenant", "id": "550e8400-e29b-41d4-a716-446655440000" },
      "assigned_at": "2025-11-29T10:00:00Z"
    },
    {
      "role": "org-admin",
      "scope": { "type": "organization", "id": "650e8400-e29b-41d4-a716-446655440000" },
      "assigned_at": "2025-11-29T10:15:00Z"
    }
  ]
}
```

---

## Permission Evaluation

### Check Permission

```http
POST /users/{userId}/permissions/check
Content-Type: application/json
Authorization: Bearer <jwt>
X-Tenant-ID: {tenantId}

{
  "permission": "entity-management:user:invite",
  "resource": {
    "type": "organization",
    "id": "650e8400-e29b-41d4-a716-446655440000"
  }
}
```

**Response** (200 OK):
```json
{
  "user_id": "750e8400-e29b-41d4-a716-446655440000",
  "permission": "entity-management:user:invite",
  "resource": {
    "type": "organization",
    "id": "650e8400-e29b-41d4-a716-446655440000"
  },
  "granted": true,
  "reason": "User has 'org-admin' role in organization"
}
```

---

## Standard Error Responses

### 400 Bad Request

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invalid organization name",
    "details": {
      "field": "name",
      "constraint": "must be 3-255 characters"
    },
    "trace_id": "abc123",
    "timestamp": "2025-11-29T10:00:00Z"
  }
}
```

### 401 Unauthorized

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired JWT token",
    "trace_id": "abc123",
    "timestamp": "2025-11-29T10:00:00Z"
  }
}
```

### 403 Forbidden

```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "Tenant ID mismatch: header '550...' does not match JWT claim '660...'",
    "trace_id": "abc123",
    "timestamp": "2025-11-29T10:00:00Z"
  }
}
```

### 404 Not Found

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Organization not found: 650e8400-e29b-41d4-a716-446655440000",
    "trace_id": "abc123",
    "timestamp": "2025-11-29T10:00:00Z"
  }
}
```

### 409 Conflict

```json
{
  "error": {
    "code": "CONFLICT",
    "message": "User with email 'alice@acme.com' already exists in tenant",
    "trace_id": "abc123",
    "timestamp": "2025-11-29T10:00:00Z"
  }
}
```

### 429 Too Many Requests

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded: 1000 requests per hour for Bronze tier",
    "details": {
      "limit": 1000,
      "remaining": 0,
      "reset_at": "2025-11-29T11:00:00Z"
    },
    "trace_id": "abc123",
    "timestamp": "2025-11-29T10:00:00Z"
  }
}
```

---

## Rate Limiting

**Headers Returned**:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1732880400
```

**Limits by Tier**:
- Bronze: 1,000 requests/hour
- Silver: 10,000 requests/hour
- Gold: 100,000 requests/hour

---

## Pagination

**Query Parameters**:
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 20, max: 100)

**Response**:
```json
{
  "items": [...],
  "page": 1,
  "page_size": 20,
  "total": 150,
  "_links": {
    "self": { "href": "/...?page=1" },
    "next": { "href": "/...?page=2" },
    "prev": null,
    "first": { "href": "/...?page=1" },
    "last": { "href": "/...?page=8" }
  }
}
```

---

## Events Published (Kafka)

All events published to `entity-events` topic in CloudEvents format.

**Event Schema**:
```json
{
  "specversion": "1.0",
  "type": "com.tjmpaas.entity.TenantCreated.v1",
  "source": "/entity-management-service",
  "id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "time": "2025-11-29T10:00:00Z",
  "datacontenttype": "application/json",
  "data": {
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Acme Corporation",
    "subscription_plan": "silver"
  },
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "trace_id": "abc123"
}
```

**Event Types**:
- `com.tjmpaas.entity.TenantCreated.v1`
- `com.tjmpaas.entity.OrganizationCreated.v1`
- `com.tjmpaas.entity.UserInvited.v1`
- `com.tjmpaas.entity.UserActivated.v1`
- `com.tjmpaas.entity.RoleAssigned.v1`
- (See EVENT-SCHEMA-STANDARDS.md for complete list)

---

## OpenAPI 3.1 Specification

**Full spec available at**: `/api/v1/openapi.json`

**Swagger UI**: `/api/v1/docs`

**Redoc**: `/api/v1/redoc`

---

## Related Documentation

- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Technical implementation
- [EVENT-SCHEMA-STANDARDS.md](../../standards/EVENT-SCHEMA-STANDARDS.md) - Event format details
- [API-DESIGN-STANDARDS.md](../../standards/API-DESIGN-STANDARDS.md) - API design principles

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-29 | Initial API specification | Platform Team |
