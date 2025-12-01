# API Design Standards

**Status**: Active Standard  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Category**: API Standard

## Context

TJMPaaS services expose REST APIs for client integration and inter-service communication. Consistent API design across services enables:
- Progressive familiarity (learn one API, understand all APIs)
- Predictable error handling and responses
- Standard security patterns (authentication, authorization)
- Multi-tenant isolation at API layer
- Version management and evolution

### Problem Statement

Without API design standards:
- Each service invents its own URL patterns, error formats, headers
- Clients must learn different patterns per service
- Multi-tenant isolation inconsistent
- Versioning approaches vary
- Error responses unpredictable

### Goals

- Consistent REST API patterns across all TJMPaaS services
- Multi-tenant aware API design (X-Tenant-ID mandatory)
- Standard error responses and status codes
- Predictable versioning strategy
- HATEOAS Level 2 for resource navigation
- OpenAPI 3.1 specifications for all endpoints

## Standards

### 1. Multi-Tenant API Requirements

**MANDATORY: X-Tenant-ID Header**

All API requests MUST include `X-Tenant-ID` header:

```http
GET /api/v1/carts/abc-123 HTTP/1.1
Host: cart-service.tjmpaas.com
Authorization: Bearer <JWT>
X-Tenant-ID: tenant-456
Content-Type: application/json
```

**Validation**:
```scala
// Every endpoint validates X-Tenant-ID matches JWT claim
def validateTenantContext(request: HttpRequest): Either[Error, TenantId] = {
  for {
    tenantHeader <- request.header[`X-Tenant-ID`].toRight(MissingTenantHeaderError)
    jwt <- extractJWT(request.header[Authorization]).toRight(MissingAuthError)
    tenantClaim <- jwt.claims.get("tenant_id").toRight(MissingTenantClaimError)
    _ <- if (tenantHeader.value == tenantClaim) Right(())
         else Left(TenantMismatchError(tenantHeader.value, tenantClaim))
  } yield TenantId(tenantHeader.value)
}

// Reject requests with missing or mismatched tenant context
request.validateTenantContext match {
  case Right(tenantId) => processRequest(tenantId)
  case Left(error) => complete(StatusCodes.Forbidden, errorResponse(error))
}
```

**Response Headers**:
```http
HTTP/1.1 200 OK
X-Tenant-ID: tenant-456
Content-Type: application/hal+json
```

Response SHOULD echo `X-Tenant-ID` header for client verification.

### 2. URL Structure

**Base Pattern**: `/api/{version}/{resource-collection}/{resource-id}/{sub-resource}`

**Examples**:
```
GET    /api/v1/carts                      # List carts for tenant
GET    /api/v1/carts/abc-123              # Get specific cart
POST   /api/v1/carts                      # Create new cart
PUT    /api/v1/carts/abc-123              # Update cart (full replacement)
PATCH  /api/v1/carts/abc-123              # Update cart (partial)
DELETE /api/v1/carts/abc-123              # Delete cart

GET    /api/v1/carts/abc-123/items        # List items in cart
POST   /api/v1/carts/abc-123/items        # Add item to cart
DELETE /api/v1/carts/abc-123/items/item-1 # Remove specific item

POST   /api/v1/carts/abc-123/checkout     # Action on resource
```

**Rules**:
- Resource names are **plural nouns** (carts, orders, users, not cart, order, user)
- Resource IDs are **UUIDs** or **natural keys** (avoid sequential integers for security)
- Sub-resources follow same pattern
- Actions use **verb at end** when not standard REST (e.g., `/checkout`, `/cancel`, `/refund`)

### 3. HTTP Methods

| Method | Purpose | Idempotent | Safe | Request Body | Success Status |
|--------|---------|------------|------|--------------|----------------|
| GET | Retrieve resource(s) | Yes | Yes | No | 200 OK |
| POST | Create resource or action | No | No | Yes | 201 Created (resource) or 200 OK (action) |
| PUT | Replace entire resource | Yes | No | Yes | 200 OK or 204 No Content |
| PATCH | Partial update | No | No | Yes | 200 OK or 204 No Content |
| DELETE | Remove resource | Yes | No | No | 204 No Content or 200 OK |
| HEAD | Retrieve headers only | Yes | Yes | No | 200 OK |
| OPTIONS | Retrieve allowed methods | Yes | Yes | No | 200 OK with Allow header |

**Idempotency**:
- GET, PUT, DELETE, HEAD, OPTIONS are idempotent (same request = same outcome)
- POST and PATCH are NOT idempotent (use idempotency keys for POST when needed)

### 4. Versioning

**Strategy**: URL Path Versioning

```
/api/v1/carts      # Version 1
/api/v2/carts      # Version 2 (breaking changes)
```

**Version Lifecycle**:
- **v1** → Current version, fully supported
- **v2** → New version introduced, v1 deprecated but still functional
- **v1** → Deprecated for 6 months, then removed (v2 becomes current)

**Breaking Changes** (require new version):
- Removing fields from responses
- Changing field types (string → integer)
- Changing field names
- Removing endpoints
- Changing semantics (same endpoint, different behavior)

**Non-Breaking Changes** (same version):
- Adding new optional fields to requests
- Adding new fields to responses (clients ignore unknown fields)
- Adding new endpoints
- Adding new optional query parameters

**Deprecation Headers**:
```http
HTTP/1.1 200 OK
Deprecation: true
Sunset: Fri, 30 Jun 2026 00:00:00 GMT
Link: </api/v2/carts>; rel="successor-version"
```

### 5. Request/Response Format

**Content Type**: `application/json` or `application/hal+json` (HATEOAS)

**Request Body** (POST/PUT/PATCH):
```json
{
  "cart": {
    "userId": "user-123",
    "items": [
      {
        "productId": "prod-456",
        "quantity": 2,
        "price": {
          "amount": 29.99,
          "currency": "USD"
        }
      }
    ]
  }
}
```

**Response Body** (GET):
```json
{
  "cart": {
    "id": "cart-abc",
    "tenantId": "tenant-456",
    "userId": "user-123",
    "items": [
      {
        "id": "item-1",
        "productId": "prod-456",
        "quantity": 2,
        "price": {
          "amount": 29.99,
          "currency": "USD"
        }
      }
    ],
    "total": {
      "amount": 59.98,
      "currency": "USD"
    },
    "createdAt": "2025-11-28T10:30:00Z",
    "updatedAt": "2025-11-28T11:45:00Z"
  },
  "_links": {
    "self": { "href": "/api/v1/carts/cart-abc" },
    "items": { "href": "/api/v1/carts/cart-abc/items" },
    "checkout": { "href": "/api/v1/carts/cart-abc/checkout", "method": "POST" }
  }
}
```

**Field Naming**:
- **camelCase** for JSON fields (not snake_case or PascalCase)
- Dates in **ISO 8601 format** with timezone (2025-11-28T10:30:00Z)
- Monetary amounts as **object with amount and currency** (not bare number)
- IDs as **strings** (UUIDs or natural keys)

### 6. HATEOAS (Level 2)

**Hypermedia Links** in responses:

```json
{
  "cart": { ... },
  "_links": {
    "self": { 
      "href": "/api/v1/carts/cart-abc" 
    },
    "items": { 
      "href": "/api/v1/carts/cart-abc/items" 
    },
    "checkout": { 
      "href": "/api/v1/carts/cart-abc/checkout",
      "method": "POST",
      "description": "Complete checkout for this cart"
    },
    "update": {
      "href": "/api/v1/carts/cart-abc",
      "method": "PATCH",
      "description": "Update cart properties"
    },
    "delete": {
      "href": "/api/v1/carts/cart-abc",
      "method": "DELETE",
      "description": "Remove cart"
    }
  }
}
```

**Benefits**:
- Clients discover available actions from responses
- API evolution: Add new links without breaking clients
- Clear indication of what operations are possible

**Link Relations**:
- `self`: Canonical URL for this resource
- `items`, `users`, etc.: Related collections
- Action names (`checkout`, `cancel`, `refund`): Available actions

### 7. Error Responses

**Standard Error Format**:
```json
{
  "error": {
    "code": "CART_NOT_FOUND",
    "message": "Cart with ID 'cart-abc' not found for tenant 'tenant-456'",
    "details": {
      "cartId": "cart-abc",
      "tenantId": "tenant-456"
    },
    "requestId": "req-xyz-789",
    "timestamp": "2025-11-28T10:30:00Z"
  }
}
```

**HTTP Status Codes**:

| Status | Meaning | Use Case |
|--------|---------|----------|
| 200 OK | Success | GET, PUT, PATCH successful |
| 201 Created | Resource created | POST successful |
| 204 No Content | Success, no body | DELETE successful |
| 400 Bad Request | Invalid request | Validation errors, malformed JSON |
| 401 Unauthorized | Missing/invalid auth | Missing or expired JWT |
| 403 Forbidden | Insufficient permissions | User lacks required role/permission |
| 404 Not Found | Resource not found | Cart ID doesn't exist for tenant |
| 409 Conflict | Resource conflict | Duplicate resource, optimistic lock failure |
| 422 Unprocessable Entity | Business rule violation | Can't checkout empty cart |
| 429 Too Many Requests | Rate limit exceeded | Tenant exceeded rate limit for SLA tier |
| 500 Internal Server Error | Server error | Unexpected exception |
| 503 Service Unavailable | Service down | Database connection failed |

**Error Codes** (machine-readable):
```
CART_NOT_FOUND
CART_EMPTY
ITEM_OUT_OF_STOCK
PAYMENT_DECLINED
TENANT_NOT_FOUND
TENANT_MISMATCH
INSUFFICIENT_PERMISSIONS
RATE_LIMIT_EXCEEDED
```

**Validation Errors** (400 Bad Request):
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "errors": [
        {
          "field": "items[0].quantity",
          "code": "MIN_VALUE",
          "message": "Quantity must be at least 1"
        },
        {
          "field": "items[0].price.amount",
          "code": "POSITIVE_NUMBER",
          "message": "Price amount must be positive"
        }
      ]
    },
    "requestId": "req-xyz-789",
    "timestamp": "2025-11-28T10:30:00Z"
  }
}
```

### 8. Pagination

**Query Parameters**:
```
GET /api/v1/carts?limit=20&offset=40
GET /api/v1/carts?limit=20&cursor=eyJpZCI6ImNhcnQtYWJjIn0
```

**Limit-Offset Pagination**:
```json
{
  "carts": [ ... ],
  "pagination": {
    "limit": 20,
    "offset": 40,
    "total": 150
  },
  "_links": {
    "self": { "href": "/api/v1/carts?limit=20&offset=40" },
    "first": { "href": "/api/v1/carts?limit=20&offset=0" },
    "prev": { "href": "/api/v1/carts?limit=20&offset=20" },
    "next": { "href": "/api/v1/carts?limit=20&offset=60" },
    "last": { "href": "/api/v1/carts?limit=20&offset=140" }
  }
}
```

**Cursor-Based Pagination** (recommended for large datasets):
```json
{
  "carts": [ ... ],
  "pagination": {
    "limit": 20,
    "cursor": "eyJpZCI6ImNhcnQtYWJjIn0",
    "hasMore": true
  },
  "_links": {
    "self": { "href": "/api/v1/carts?limit=20&cursor=eyJpZCI6ImNhcnQtYWJjIn0" },
    "next": { "href": "/api/v1/carts?limit=20&cursor=eyJpZCI6ImNhcnQteHl6In0" }
  }
}
```

**Defaults**:
- `limit`: 20 (max 100)
- `offset`: 0
- Cursor: null (start from beginning)

### 9. Filtering and Sorting

**Filtering**:
```
GET /api/v1/carts?status=active&userId=user-123
GET /api/v1/carts?createdAfter=2025-11-01&createdBefore=2025-11-30
```

**Sorting**:
```
GET /api/v1/carts?sort=createdAt:desc
GET /api/v1/carts?sort=updatedAt:asc,total:desc
```

**Rules**:
- Multiple filters combined with AND logic
- Sort format: `field:direction` (asc or desc)
- Multiple sort fields separated by comma

### 10. Security

**Authentication**: JWT Bearer Token
```http
Authorization: Bearer <JWT>
```

**JWT Claims** (required):
```json
{
  "sub": "user-123",
  "tenant_id": "tenant-456",
  "email": "user@example.com",
  "roles": ["CustomerUser"],
  "permissions": ["cart:read", "cart:write:own"],
  "exp": 1701187200
}
```

**Authorization**:
- Endpoint checks JWT `tenant_id` matches `X-Tenant-ID` header
- Endpoint checks JWT `permissions` include required permission
- Row-level checks ensure user can only access their own resources (unless has wildcard permission)

**HTTPS Only**:
- All API endpoints MUST use HTTPS in production
- HTTP redirects to HTTPS (301 Moved Permanently)
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains`

### 11. Rate Limiting

**Headers**:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 998
X-RateLimit-Reset: 1701190800
```

**429 Response**:
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded for tenant 'tenant-456'. Limit: 1000 requests per minute",
    "details": {
      "tenantId": "tenant-456",
      "limit": 1000,
      "remaining": 0,
      "resetAt": "2025-11-28T11:00:00Z"
    },
    "requestId": "req-xyz-789",
    "timestamp": "2025-11-28T10:59:59Z"
  }
}
```

**Rate Limits by SLA Tier**:
- Bronze: 100 req/min
- Silver: 1000 req/min
- Gold: 10000 req/min

### 12. OpenAPI Specification

Every service MUST provide OpenAPI 3.1 specification at `/api/openapi.json`:

```yaml
openapi: 3.1.0
info:
  title: CartService API
  version: 1.0.0
  description: Shopping cart management service
servers:
  - url: https://cart-service.tjmpaas.com/api/v1
security:
  - BearerAuth: []
paths:
  /carts:
    get:
      summary: List carts for tenant
      parameters:
        - name: X-Tenant-ID
          in: header
          required: true
          schema:
            type: string
      responses:
        '200':
          description: List of carts
          content:
            application/hal+json:
              schema:
                $ref: '#/components/schemas/CartList'
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
  schemas:
    CartList:
      type: object
      properties:
        carts:
          type: array
          items:
            $ref: '#/components/schemas/Cart'
```

## Validation

Success criteria:

- All TJMPaaS service APIs follow these standards (100% compliance)
- X-Tenant-ID header mandatory on all endpoints
- OpenAPI 3.1 specification available for all services
- Error responses use standard format
- HATEOAS links present in all resource responses

Metrics:
- API standards compliance: 100% of services
- OpenAPI spec coverage: 100% of endpoints documented
- Consistent error format: 100% of error responses
- HATEOAS adoption: >90% of GET endpoints include _links

## Related Standards

- [POL-cross-service-consistency.md](./POL-cross-service-consistency.md) - Tier 1 consistency includes API design
- [MULTI-TENANT-SEAM-ARCHITECTURE.md](./MULTI-TENANT-SEAM-ARCHITECTURE.md) - X-Tenant-ID header requirement
- [EVENT-SCHEMA-STANDARDS.md](./EVENT-SCHEMA-STANDARDS.md) - Event naming matches resource names

## Related Best Practices

- [REST with HATEOAS Best Practices](../best-practices/architecture/rest-hateoas.md) - Level 2 REST validation

## Notes

**Why X-Tenant-ID Header?**

- Clear, explicit tenant context on every request
- Complements JWT `tenant_id` claim for validation
- Enables infrastructure-level tenant routing/sharding
- Consistent with industry patterns (X-prefixed custom headers)

**Why HATEOAS Level 2?**

Per [REST with HATEOAS Best Practices](../best-practices/architecture/rest-hateoas.md):
- Level 2 (HTTP methods + status codes + links) provides good balance
- Links enable API evolution without breaking clients
- Full Level 3 (HATEOAS with link rel types) adds complexity without ROI for most APIs
- Matches patterns used by Stripe, GitHub, AWS APIs

**Why Not GraphQL?**

- REST with HATEOAS simpler to implement and understand
- Better caching characteristics
- Established tooling (OpenAPI, Swagger UI)
- Progressive familiarity goal favors consistency (all REST)
- GraphQL may be added for specific use cases (complex queries) in future versions

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-28 | Initial API standards establishing multi-tenant REST patterns | Tony Moores |
