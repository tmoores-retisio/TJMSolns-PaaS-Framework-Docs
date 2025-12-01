# {Service Name} API Specification

**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Template Version**: 1.0

---

**Instructions**: Copy this template to service repository `docs/API-SPECIFICATION.md`. This provides the complete OpenAPI 3.1 specification for the service's REST API. All TJMPaaS services MUST provide OpenAPI spec at runtime at `/api/openapi.json`.

---

## Overview

**Base URL**: `https://{host}/api/v1`  
**Authentication**: JWT Bearer token  
**Multi-Tenant**: X-Tenant-ID header required on all requests (except tenant creation)  
**OpenAPI Version**: 3.1.0

## OpenAPI Specification

```yaml
openapi: 3.1.0
info:
  title: {Service Name} API
  version: 1.0.0
  description: |
    {Service description}
    
    **Multi-Tenancy**: All endpoints (except POST /tenants) require X-Tenant-ID header.
    The header value must match the tenant_id claim in the JWT token.
  contact:
    name: {Team Name}
    email: {team@example.com}
  license:
    name: Apache 2.0
    url: https://www.apache.org/licenses/LICENSE-2.0

servers:
  - url: https://{host}/api/v1
    description: Production
    variables:
      host:
        default: api.tjmpaas.com
  - url: http://localhost:8080/api/v1
    description: Local development

security:
  - BearerAuth: []
  - TenantHeader: []

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token with tenant_id claim
    TenantHeader:
      type: apiKey
      in: header
      name: X-Tenant-ID
      description: Tenant context identifier (must match JWT tenant_id claim)
  
  parameters:
    TenantIdHeader:
      name: X-Tenant-ID
      in: header
      required: true
      schema:
        type: string
        format: uuid
      description: Tenant identifier (must match JWT tenant_id claim)
    
    ResourceId:
      name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
      description: Resource identifier
  
  schemas:
    # Domain Models
    {Resource}:
      type: object
      required:
        - id
        - tenant_id
        - {required_field}
      properties:
        id:
          type: string
          format: uuid
          description: Unique identifier
        tenant_id:
          type: string
          format: uuid
          description: Tenant context
        {field_name}:
          type: {type}
          description: {description}
        created_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time
        _links:
          $ref: '#/components/schemas/HATEOASLinks'
      example:
        id: "550e8400-e29b-41d4-a716-446655440000"
        tenant_id: "660e8400-e29b-41d4-a716-446655440000"
        created_at: "2025-01-15T10:30:00Z"
        updated_at: "2025-01-15T10:30:00Z"
        _links:
          self:
            href: "/api/v1/{resources}/550e8400-e29b-41d4-a716-446655440000"
          collection:
            href: "/api/v1/{resources}"
    
    # HATEOAS Links
    HATEOASLinks:
      type: object
      description: Hypermedia links for API navigation
      properties:
        self:
          $ref: '#/components/schemas/Link'
        collection:
          $ref: '#/components/schemas/Link'
        related:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/Link'
      required:
        - self
    
    Link:
      type: object
      required:
        - href
      properties:
        href:
          type: string
          description: Link URL
        method:
          type: string
          enum: [GET, POST, PUT, PATCH, DELETE]
          description: HTTP method for link
        rel:
          type: string
          description: Link relationship
        type:
          type: string
          description: Media type
      example:
        href: "/api/v1/tenants/123"
        method: "GET"
        rel: "self"
        type: "application/json"
    
    # Error Responses
    Error:
      type: object
      required:
        - code
        - message
        - request_id
      properties:
        code:
          type: string
          description: Machine-readable error code
          example: "RESOURCE_NOT_FOUND"
        message:
          type: string
          description: Human-readable error message
          example: "The requested resource was not found"
        details:
          type: object
          additionalProperties: true
          description: Additional error context
        request_id:
          type: string
          format: uuid
          description: Request identifier for tracing
        _links:
          type: object
          properties:
            documentation:
              $ref: '#/components/schemas/Link'
    
    ValidationError:
      allOf:
        - $ref: '#/components/schemas/Error'
        - type: object
          properties:
            validation_errors:
              type: array
              items:
                type: object
                properties:
                  field:
                    type: string
                  message:
                    type: string
                  code:
                    type: string
    
    # Pagination
    PaginatedResponse:
      type: object
      required:
        - data
        - pagination
      properties:
        data:
          type: array
          items:
            type: object
        pagination:
          $ref: '#/components/schemas/Pagination'
        _links:
          type: object
          properties:
            self:
              $ref: '#/components/schemas/Link'
            first:
              $ref: '#/components/schemas/Link'
            prev:
              $ref: '#/components/schemas/Link'
            next:
              $ref: '#/components/schemas/Link'
            last:
              $ref: '#/components/schemas/Link'
    
    Pagination:
      type: object
      properties:
        total:
          type: integer
          description: Total number of items
        limit:
          type: integer
          description: Items per page
        offset:
          type: integer
          description: Current offset
        has_more:
          type: boolean
          description: Whether more items exist

paths:
  # Health Endpoints
  /health:
    get:
      summary: Health check
      description: Liveness probe - service is running
      operationId: healthCheck
      security: []
      tags:
        - Health
      responses:
        '200':
          description: Service is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    enum: [healthy]
                  timestamp:
                    type: string
                    format: date-time
        '503':
          description: Service is unhealthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    enum: [unhealthy]
                  error:
                    type: string
  
  /ready:
    get:
      summary: Readiness check
      description: Readiness probe - service is ready to accept traffic
      operationId: readinessCheck
      security: []
      tags:
        - Health
      responses:
        '200':
          description: Service is ready
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    enum: [ready]
                  checks:
                    type: object
                    properties:
                      database:
                        type: string
                        enum: [ok, degraded]
                      kafka:
                        type: string
                        enum: [ok, degraded]
        '503':
          description: Service is not ready
  
  # API Documentation
  /openapi.json:
    get:
      summary: OpenAPI specification
      description: Returns this OpenAPI 3.1 specification
      operationId: getOpenAPISpec
      security: []
      tags:
        - Documentation
      responses:
        '200':
          description: OpenAPI specification
          content:
            application/json:
              schema:
                type: object

  # Resource Collection Endpoints
  /{resources}:
    get:
      summary: List {resources}
      description: |
        Retrieve paginated list of {resources} for the specified tenant.
        Requires X-Tenant-ID header matching JWT tenant_id claim.
      operationId: list{Resources}
      tags:
        - {Resources}
      parameters:
        - $ref: '#/components/parameters/TenantIdHeader'
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
          description: Number of items per page
        - name: offset
          in: query
          schema:
            type: integer
            minimum: 0
            default: 0
          description: Number of items to skip
        - name: sort
          in: query
          schema:
            type: string
            enum: [created_at, updated_at, name]
            default: created_at
          description: Sort field
        - name: order
          in: query
          schema:
            type: string
            enum: [asc, desc]
            default: desc
          description: Sort order
      responses:
        '200':
          description: List of {resources}
          headers:
            X-Tenant-ID:
              schema:
                type: string
              description: Echo of request tenant ID
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedResponse'
        '401':
          description: Unauthorized - missing or invalid JWT
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden - X-Tenant-ID does not match JWT tenant_id
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Too Many Requests - rate limit exceeded
          headers:
            Retry-After:
              schema:
                type: integer
              description: Seconds until retry allowed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
    
    post:
      summary: Create {resource}
      description: Create new {resource} in the specified tenant context
      operationId: create{Resource}
      tags:
        - {Resources}
      parameters:
        - $ref: '#/components/parameters/TenantIdHeader'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/{Resource}'
      responses:
        '201':
          description: {Resource} created
          headers:
            Location:
              schema:
                type: string
              description: URL of created resource
            X-Tenant-ID:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{Resource}'
        '400':
          description: Bad Request - validation failed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ValidationError'
        '401':
          description: Unauthorized
        '403':
          description: Forbidden
        '409':
          description: Conflict - resource already exists
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '422':
          description: Unprocessable Entity - business rule violation
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  
  # Individual Resource Endpoints
  /{resources}/{id}:
    get:
      summary: Get {resource} by ID
      description: Retrieve single {resource} by identifier
      operationId: get{Resource}
      tags:
        - {Resources}
      parameters:
        - $ref: '#/components/parameters/TenantIdHeader'
        - $ref: '#/components/parameters/ResourceId'
      responses:
        '200':
          description: {Resource} details
          headers:
            X-Tenant-ID:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{Resource}'
        '401':
          description: Unauthorized
        '403':
          description: Forbidden
        '404':
          description: Not Found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
    
    put:
      summary: Update {resource}
      description: Replace {resource} (full update)
      operationId: update{Resource}
      tags:
        - {Resources}
      parameters:
        - $ref: '#/components/parameters/TenantIdHeader'
        - $ref: '#/components/parameters/ResourceId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/{Resource}'
      responses:
        '200':
          description: {Resource} updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{Resource}'
        '400':
          description: Bad Request
        '401':
          description: Unauthorized
        '403':
          description: Forbidden
        '404':
          description: Not Found
        '409':
          description: Conflict - concurrent modification
    
    patch:
      summary: Partially update {resource}
      description: Update specific fields of {resource}
      operationId: patch{Resource}
      tags:
        - {Resources}
      parameters:
        - $ref: '#/components/parameters/TenantIdHeader'
        - $ref: '#/components/parameters/ResourceId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              description: Partial {resource} update
      responses:
        '200':
          description: {Resource} updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{Resource}'
        '400':
          description: Bad Request
        '401':
          description: Unauthorized
        '403':
          description: Forbidden
        '404':
          description: Not Found
    
    delete:
      summary: Delete {resource}
      description: Remove {resource} from tenant
      operationId: delete{Resource}
      tags:
        - {Resources}
      parameters:
        - $ref: '#/components/parameters/TenantIdHeader'
        - $ref: '#/components/parameters/ResourceId'
      responses:
        '204':
          description: {Resource} deleted
        '401':
          description: Unauthorized
        '403':
          description: Forbidden
        '404':
          description: Not Found
        '409':
          description: Conflict - cannot delete (e.g., has dependencies)

# Add custom action endpoints as needed:
#  /{resources}/{id}/{action}:
#    post:
#      summary: {Action description}
#      ...

tags:
  - name: Health
    description: Health and readiness probes
  - name: Documentation
    description: API documentation
  - name: {Resources}
    description: {Resource management operations}
```

## Error Codes

| HTTP Status | Error Code | Description | Recovery |
|-------------|-----------|-------------|----------|
| 400 | VALIDATION_ERROR | Request validation failed | Fix request body |
| 401 | UNAUTHORIZED | Missing or invalid JWT | Provide valid JWT |
| 403 | FORBIDDEN | X-Tenant-ID mismatch or insufficient permissions | Check tenant context |
| 404 | RESOURCE_NOT_FOUND | Resource does not exist | Verify resource ID |
| 409 | CONFLICT | Resource already exists or concurrent modification | Check current state |
| 422 | BUSINESS_RULE_VIOLATION | Domain rule validation failed | Review business constraints |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests | Wait and retry (see Retry-After header) |
| 500 | INTERNAL_ERROR | Unexpected server error | Retry with exponential backoff |
| 503 | SERVICE_UNAVAILABLE | Service temporarily unavailable | Retry later |

## Rate Limiting

Rate limits enforced by SLA tier (from X-Tenant-ID lookup):

| Tier | Requests per Minute | Burst |
|------|-------------------|-------|
| Bronze | 100 | 150 |
| Silver | 1,000 | 1,500 |
| Gold | 10,000 | 15,000 |

**Headers**:
- `X-RateLimit-Limit`: Maximum requests per window
- `X-RateLimit-Remaining`: Requests remaining in window
- `X-RateLimit-Reset`: Unix timestamp when window resets
- `Retry-After`: Seconds until retry (on 429 response)

## Pagination

**Limit-Offset Pagination**:
```
GET /api/v1/resources?limit=20&offset=40
```

**Response**:
```json
{
  "data": [...],
  "pagination": {
    "total": 150,
    "limit": 20,
    "offset": 40,
    "has_more": true
  },
  "_links": {
    "self": { "href": "/api/v1/resources?limit=20&offset=40" },
    "first": { "href": "/api/v1/resources?limit=20&offset=0" },
    "prev": { "href": "/api/v1/resources?limit=20&offset=20" },
    "next": { "href": "/api/v1/resources?limit=20&offset=60" },
    "last": { "href": "/api/v1/resources?limit=20&offset=140" }
  }
}
```

## Idempotency

**POST** requests support idempotency via `Idempotency-Key` header:

```http
POST /api/v1/resources
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
X-Tenant-ID: 660e8400-e29b-41d4-a716-446655440000
Authorization: Bearer <jwt>

{ ... }
```

- Same key within 24 hours returns cached response
- Prevents duplicate resource creation on retry

## Versioning

**Current Version**: v1

**Deprecation Process**:
1. New version introduced (e.g., v2)
2. Old version marked deprecated (headers: `Deprecation: true`, `Sunset: 2026-12-31`, `Link: <v2-url>; rel="successor-version"`)
3. 6-month deprecation period
4. Old version removed

## Examples

### Create Resource

**Request**:
```http
POST /api/v1/resources HTTP/1.1
Host: api.tjmpaas.com
X-Tenant-ID: 660e8400-e29b-41d4-a716-446655440000
Authorization: Bearer eyJhbGc...
Content-Type: application/json

{
  "name": "Example Resource",
  "description": "..."
}
```

**Response**:
```http
HTTP/1.1 201 Created
Location: /api/v1/resources/770e8400-e29b-41d4-a716-446655440000
X-Tenant-ID: 660e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{
  "id": "770e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "660e8400-e29b-41d4-a716-446655440000",
  "name": "Example Resource",
  "description": "...",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z",
  "_links": {
    "self": { "href": "/api/v1/resources/770e8400-e29b-41d4-a716-446655440000" },
    "collection": { "href": "/api/v1/resources" }
  }
}
```

## Related Documentation

- [API-DESIGN-STANDARDS.md](../../../standards/API-DESIGN-STANDARDS.md) - TJMPaaS API standards
- [MULTI-TENANT-SEAM-ARCHITECTURE.md](../../../standards/MULTI-TENANT-SEAM-ARCHITECTURE.md) - Multi-tenancy patterns
- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Service architecture details

## Revision History

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial API specification | {Name} |
