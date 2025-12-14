# JWT Authentication and Permission System

**Status**: Active Standard  
**Version**: 1.0.0  
**Date**: December 14, 2025  
**Authority**: TJMPaaS Technical Standards  
**Applies To**: All TJMPaaS services requiring authentication/authorization

---

## Executive Summary

This standard defines the JSON Web Token (JWT) structure, permission model, and implementation patterns for authentication and authorization across all TJMPaaS services. It establishes a **multi-tenant RBAC (Role-Based Access Control) system** with hierarchical permissions, tenant isolation guarantees, and security best practices aligned with OAuth 2.0, OpenID Connect, and NIST guidelines.

**Key Decisions**:
- **Token Types**: Access tokens (short-lived, 1 hour), Refresh tokens (long-lived, 30 days), ID tokens (user profile)
- **Algorithm**: RS256 (RSA signature with SHA-256) for public/private key cryptography
- **Permission Format**: `service:action:scope` pattern (e.g., `entity-management:write:own`)
- **Multi-Tenant**: Mandatory `tenant_id` claim in all tokens, validated against `X-Tenant-ID` header
- **Caching**: Permission checks cached 5 minutes, token validation cached until expiry
- **Revocation**: Token versioning + blacklist for immediate revocation

---

## Table of Contents

1. [Context and Rationale](#context-and-rationale)
2. [Token Types and Structure](#token-types-and-structure)
3. [JWT Claims Specification](#jwt-claims-specification)
4. [Permission Model](#permission-model)
5. [Multi-Tenant Integration](#multi-tenant-integration)
6. [Token Lifecycle](#token-lifecycle)
7. [Validation and Verification](#validation-and-verification)
8. [Permission Enforcement](#permission-enforcement)
9. [Caching Strategy](#caching-strategy)
10. [Revocation Mechanisms](#revocation-mechanisms)
11. [Security Considerations](#security-considerations)
12. [Implementation Patterns](#implementation-patterns)
13. [Integration with Entity Management Service](#integration-with-entity-management-service)
14. [Examples](#examples)
15. [References](#references)

---

## Context and Rationale

### Problem Statement

TJMPaaS services require a **consistent, secure, scalable authentication and authorization mechanism** that:
- Supports multi-tenancy with strong isolation guarantees
- Enables fine-grained permissions (RBAC)
- Works across distributed microservices
- Minimizes performance overhead (< 1ms permission checks)
- Supports token refresh without re-authentication
- Enables immediate revocation when needed

### Why JWT?

**Benefits**:
- **Stateless**: No server-side session storage required
- **Self-Contained**: Contains user identity and permissions
- **Distributed**: Works across multiple services without central session store
- **Standard**: Industry-standard (RFC 7519), excellent library support
- **Performance**: Fast signature verification, no database lookups

**Trade-offs**:
- **Size**: Larger than session IDs (typically 1-2KB)
- **Revocation**: Requires additional mechanisms (stateless tokens can't be revoked by default)
- **Secret Management**: Requires secure key management

**Alternatives Considered**:
- **Session tokens**: Requires centralized session store, doesn't scale
- **SAML**: Too heavyweight for API-first architecture
- **OAuth opaque tokens**: Requires token introspection on every request

### Industry Standards Alignment

- **RFC 7519**: JSON Web Token (JWT)
- **RFC 7515**: JSON Web Signature (JWS)
- **RFC 6749**: OAuth 2.0 Authorization Framework
- **OpenID Connect Core 1.0**: ID tokens and user profile
- **NIST SP 800-63B**: Digital Identity Guidelines (Authentication)

---

## Token Types and Structure

TJMPaaS uses **three token types** following OAuth 2.0 and OpenID Connect patterns:

### 1. Access Token

**Purpose**: Authorizes API requests

**Lifetime**: 1 hour (3600 seconds)

**Usage**: Included in `Authorization: Bearer <token>` header on API requests

**Contents**: User identity, tenant context, roles, permissions

**Example**:
```
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4ODBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJ0ZW5hbnRfaWQiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJyb2xlcyI6WyJ0ZW5hbnQtYWRtaW4iXSwicGVybWlzc2lvbnMiOlsiZW50aXR5LW1hbmFnZW1lbnQ6cmVhZDoqIiwiZW50aXR5LW1hbmFnZW1lbnQ6d3JpdGU6Km4iXSwiaWF0IjoxNzM0MjAwNDAwLCJleHAiOjE3MzQyMDQwMDAsImlzcyI6Imh0dHBzOi8vYXV0aC50am1wYWFzLmlvIiwiYXVkIjoidGptcGFhcy1hcGkifQ.signature
```

### 2. Refresh Token

**Purpose**: Obtains new access tokens without re-authentication

**Lifetime**: 30 days (2,592,000 seconds)

**Usage**: Sent to token refresh endpoint to get new access token

**Storage**: Secure HTTP-only cookie or secure client storage

**Security**: 
- Rotated on every use (refresh token rotation)
- Single-use (invalidated after refresh)
- Longer detection window for compromise

**Example Structure**:
```json
{
  "token_type": "refresh",
  "jti": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "sub": "880e8400-e29b-41d4-a716-446655440000",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "iat": 1734200400,
  "exp": 1736792400,
  "iss": "https://auth.tjmpaas.io",
  "aud": "tjmpaas-refresh"
}
```

### 3. ID Token

**Purpose**: User profile information (OpenID Connect)

**Lifetime**: Same as access token (1 hour)

**Usage**: Client-side user profile display (name, email, avatar)

**Contents**: User profile data (NOT permissions)

**Example Structure**:
```json
{
  "sub": "880e8400-e29b-41d4-a716-446655440000",
  "email": "admin@example.com",
  "name": "Alice Admin",
  "email_verified": true,
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "organization_id": "770e8400-e29b-41d4-a716-446655440000",
  "iat": 1734200400,
  "exp": 1734204000,
  "iss": "https://auth.tjmpaas.io",
  "aud": "tjmpaas-client"
}
```

---

## JWT Claims Specification

### Standard Claims (RFC 7519)

All TJMPaaS tokens MUST include these **standard claims**:

| Claim | Name | Type | Required | Description |
|-------|------|------|----------|-------------|
| `iss` | Issuer | String | Yes | Token issuer (e.g., `https://auth.tjmpaas.io`) |
| `sub` | Subject | String (UUID) | Yes | User ID (stable across tenant) |
| `aud` | Audience | String or Array | Yes | Intended recipient (e.g., `tjmpaas-api`) |
| `exp` | Expiration Time | NumericDate | Yes | Token expiry (Unix timestamp) |
| `iat` | Issued At | NumericDate | Yes | Token issuance time (Unix timestamp) |
| `jti` | JWT ID | String (UUID) | Yes | Unique token identifier (for revocation) |

**Validation Rules**:
- `iss`: MUST match configured issuer (prevents token substitution)
- `sub`: MUST be a valid UUID (user exists in system)
- `aud`: MUST include service identifier (prevents token reuse across services)
- `exp`: MUST be future timestamp (rejects expired tokens)
- `iat`: MUST be past timestamp, within reasonable clock skew (5 minutes)
- `jti`: MUST be unique (enables revocation tracking)

### TJMPaaS Custom Claims

Additional claims specific to TJMPaaS multi-tenant RBAC:

| Claim | Type | Required | Description |
|-------|------|----------|-------------|
| `tenant_id` | String (UUID) | Yes | Tenant context for all operations |
| `organization_id` | String (UUID) | No | Primary organization (if user in multiple orgs) |
| `roles` | Array[String] | Yes | User roles (e.g., `["tenant-admin", "project-manager"]`) |
| `permissions` | Array[String] | Yes | Flattened permissions from all roles |
| `token_version` | Integer | Yes | Token version for revocation (incremented on password change) |
| `session_id` | String (UUID) | No | Session identifier (for multi-session tracking) |

**Example Access Token Payload**:
```json
{
  "iss": "https://auth.tjmpaas.io",
  "sub": "880e8400-e29b-41d4-a716-446655440000",
  "aud": ["tjmpaas-api", "entity-management"],
  "exp": 1734204000,
  "iat": 1734200400,
  "jti": "f1e2d3c4-b5a6-7890-1234-567890abcdef",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "organization_id": "770e8400-e29b-41d4-a716-446655440000",
  "roles": ["tenant-admin", "project-manager"],
  "permissions": [
    "entity-management:read:*",
    "entity-management:write:*",
    "entity-management:delete:own",
    "cart-service:read:*",
    "cart-service:write:own"
  ],
  "token_version": 3,
  "session_id": "d4c3b2a1-9876-5432-fedc-ba9876543210"
}
```

### Claim Size Considerations

**Access Token Size Budget**: 2KB maximum (compressed)

**Optimization Strategies**:
1. **Permission Compression**: Store hash of permission set instead of full list (for users with 50+ permissions)
   - Token contains: `"permission_hash": "sha256:abc123..."`
   - Service fetches full permissions from cache using hash
2. **Audience Optimization**: Only include relevant services in `aud`
3. **Role-Only Tokens**: For low-permission users, omit `permissions` array (compute from roles on-demand)

---

## Permission Model

### Permission Format

**Pattern**: `service:action:scope`

**Components**:
1. **Service**: TJMPaaS service name (e.g., `entity-management`, `cart-service`, `order-service`)
2. **Action**: Operation type (e.g., `read`, `write`, `delete`, `admin`, `approve`)
3. **Scope**: Access level (e.g., `*`, `own`, `tenant`, `organization`, `{resource_type}`)

**Examples**:
```
entity-management:read:*           → Read any entity in tenant
entity-management:write:own        → Write entities owned by user
entity-management:delete:organizations → Delete organizations specifically
cart-service:read:*                → Read any cart in tenant
cart-service:write:own             → Write user's own cart
order-service:approve:*            → Approve any order
admin:*:*                          → Full system admin (super-admin only)
```

### Action Types

| Action | Description | HTTP Methods | Example Use Case |
|--------|-------------|--------------|------------------|
| `read` | View/query resources | GET | View user list, read cart |
| `write` | Create/update resources | POST, PUT, PATCH | Create user, update cart |
| `delete` | Remove resources | DELETE | Delete user, remove cart item |
| `approve` | Workflow approvals | POST | Approve order, approve refund |
| `admin` | Administrative operations | ALL | System configuration, bulk operations |
| `*` | Wildcard (all actions) | ALL | Super-admin role |

### Scope Semantics

| Scope | Meaning | Filter Logic |
|-------|---------|--------------|
| `*` | All resources in tenant | No additional filter (tenant isolation already applied) |
| `own` | Resources owned/created by user | `WHERE created_by = user_id` |
| `tenant` | Tenant-scoped resources | `WHERE tenant_id = current_tenant` |
| `organization` | Organization-scoped resources | `WHERE organization_id IN user.organizations` |
| `{resource_type}` | Specific resource type | `WHERE resource_type = {type}` (e.g., `organizations`, `tenants`) |

### Permission Hierarchy

**Inheritance Rules**:
1. `*:*:*` grants ALL permissions (super-admin)
2. `service:*:*` grants all actions on service
3. `service:action:*` grants action on all resources in tenant
4. More specific permissions override general (deny takes precedence)

**Hierarchy Example**:
```
admin:*:*                            → Grants EVERYTHING
  ↓
entity-management:*:*                → Grants all entity-management operations
  ↓
entity-management:write:*            → Write any entity
  ↓
entity-management:write:own          → Write only owned entities
```

### Negative Permissions (Deny Rules)

**Format**: Prefix with `!` (e.g., `!entity-management:delete:*`)

**Precedence**: Deny ALWAYS takes precedence over allow

**Example**:
```json
{
  "roles": ["tenant-admin"],
  "permissions": [
    "entity-management:*:*",
    "!entity-management:delete:tenants"
  ]
}
```
Result: User can do everything EXCEPT delete tenants

**Use Case**: Restrict super-admin from certain dangerous operations

### Wildcard Patterns

**Supported**:
- `*` in action: `entity-management:*:own` (all actions on owned entities)
- `*` in scope: `entity-management:read:*` (read all entities)
- `*` in service: `*:read:*` (read across all services)

**Not Supported** (security risk):
- Partial wildcards: `entity-*:read:*` (too broad)
- Regex patterns: `entity-management:read:user.*` (complexity)

---

## Multi-Tenant Integration

### Tenant Context Propagation

**Mandatory Header**: `X-Tenant-ID` on ALL API requests

**Validation Flow**:
1. Extract `X-Tenant-ID` from request header
2. Extract `tenant_id` from JWT access token
3. **MUST match exactly** (case-sensitive UUID comparison)
4. If mismatch → HTTP 403 Forbidden

**Example**:
```http
GET /api/v1/organizations HTTP/1.1
Host: entity-management.tjmpaas.io
Authorization: Bearer eyJhbGci...
X-Tenant-ID: 550e8400-e29b-41d4-a716-446655440000
```

**Token Validation Pseudocode**:
```scala
def validateTenantContext(
  request: HttpRequest, 
  token: JWTToken
): Either[Error, TenantContext] = {
  
  val headerTenantId = request.headers.get("X-Tenant-ID")
  val tokenTenantId = token.claims.tenant_id
  
  if (headerTenantId != tokenTenantId) {
    Left(TenantMismatchError("X-Tenant-ID header does not match JWT tenant_id"))
  } else {
    Right(TenantContext(tenantId = tokenTenantId))
  }
}
```

### Cross-Tenant Access Prevention

**Database Queries**: ALL queries MUST filter by `tenant_id`

**Good** (Safe):
```sql
SELECT * FROM users 
WHERE tenant_id = ? AND user_id = ?
```

**Bad** (Unsafe):
```sql
SELECT * FROM users WHERE user_id = ?  -- MISSING TENANT FILTER!
```

**ORM Configuration** (Example with Slick):
```scala
trait TenantScoped {
  def tenant_id: UUID
}

implicit class TenantScopedQuery[T <: TenantScoped](query: Query[T, _, _]) {
  def forTenant(tenantId: UUID) = query.filter(_.tenant_id === tenantId)
}

// Usage - automatic tenant filtering
val users = usersTable
  .forTenant(authContext.tenant_id)  // REQUIRED
  .filter(_.email === email)
  .result
```

### Tenant Isolation Guarantees

**Seam Level 1 (Tenant)**: Covered by this standard
- JWT `tenant_id` claim mandatory
- `X-Tenant-ID` header validation
- All database queries tenant-filtered

**Seam Levels 2-4**: Covered by application logic
- Seam 2 (Service Entitlement): Feature flags per subscription tier
- Seam 3 (Feature Limits): Rate limiting, quotas per tier
- Seam 4 (Role Permissions): RBAC permission evaluation

See [Multi-Tenant Seam Architecture](./MULTI-TENANT-SEAM-ARCHITECTURE.md) for complete isolation model.

---

## Token Lifecycle

### Token Issuance

**Authentication Flow** (Login):
```mermaid
sequenceDiagram
    participant Client
    participant AuthService
    participant UserDB
    participant TokenStore
    
    Client->>AuthService: POST /auth/login<br/>{email, password, tenant_id}
    AuthService->>UserDB: Validate credentials
    UserDB-->>AuthService: User + Roles + Permissions
    AuthService->>AuthService: Generate tokens<br/>(access, refresh, ID)
    AuthService->>TokenStore: Store refresh token hash
    AuthService-->>Client: {access_token, refresh_token, id_token}
```

**Token Generation**:
1. User authenticates (email/password, SSO, etc.)
2. Fetch user roles and permissions from Entity Management Service
3. Generate access token with full permission set
4. Generate refresh token (single-use, rotated)
5. Generate ID token (user profile)
6. Store refresh token hash in database (for revocation)
7. Return all three tokens to client

### Token Refresh

**Refresh Flow** (No Re-Authentication):
```mermaid
sequenceDiagram
    participant Client
    participant AuthService
    participant TokenStore
    participant EMS as Entity Mgmt
    
    Client->>AuthService: POST /auth/refresh<br/>{refresh_token}
    AuthService->>TokenStore: Validate refresh token
    TokenStore-->>AuthService: Valid (not revoked)
    AuthService->>EMS: Fetch latest roles/permissions
    EMS-->>AuthService: Updated permission set
    AuthService->>AuthService: Generate new tokens
    AuthService->>TokenStore: Revoke old refresh token<br/>Store new refresh token
    AuthService-->>Client: {access_token, refresh_token, id_token}
```

**Refresh Token Rotation**:
- Old refresh token invalidated immediately
- New refresh token issued with new `jti`
- Prevents replay attacks
- If old token reused → revoke ALL user tokens (potential compromise)

### Token Expiry

**Access Token Expiry** (1 hour):
- Short-lived to limit exposure if compromised
- Client MUST refresh before expiry
- Server rejects expired tokens (HTTP 401)

**Refresh Token Expiry** (30 days):
- Long-lived for good user experience
- Sliding window: Extends on each refresh
- After 30 days idle → user must re-authenticate

**Expiry Handling**:
```scala
def validateExpiry(token: JWTToken): Either[Error, Unit] = {
  val now = Instant.now().getEpochSecond
  val exp = token.claims.exp
  val clockSkew = 300  // 5 minutes tolerance
  
  if (now > exp + clockSkew) {
    Left(TokenExpiredError("Token has expired"))
  } else {
    Right(())
  }
}
```

---

## Validation and Verification

### Signature Verification

**Algorithm**: RS256 (RSA Signature with SHA-256)

**Key Management**:
- **Private Key**: Held by Auth Service only (HSM or secure vault)
- **Public Key**: Distributed to all services (via JWKS endpoint)
- **Rotation**: Keys rotated every 90 days (dual key support during rotation)

**JWKS Endpoint** (JSON Web Key Set):
```http
GET /.well-known/jwks.json HTTP/1.1
Host: auth.tjmpaas.io
```

**Response**:
```json
{
  "keys": [
    {
      "kty": "RSA",
      "use": "sig",
      "kid": "2024-12-14-primary",
      "alg": "RS256",
      "n": "0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtV...",
      "e": "AQAB"
    }
  ]
}
```

**Verification Steps**:
1. Extract `kid` (Key ID) from token header
2. Fetch public key from JWKS endpoint (cached 1 hour)
3. Verify signature using RSA-SHA256
4. If signature invalid → reject token (HTTP 401)

**Implementation** (Scala example):
```scala
import pdi.jwt.{Jwt, JwtAlgorithm, JwtClaim}

def verifyToken(token: String, publicKey: PublicKey): Try[JwtClaim] = {
  Jwt.decode(token, publicKey, Seq(JwtAlgorithm.RS256))
}

// Usage
verifyToken(accessToken, cachedPublicKey) match {
  case Success(claims) => 
    validateClaims(claims)  // Additional claim validation
  case Failure(ex) => 
    Unauthorized("Invalid token signature")
}
```

### Claim Validation

**Mandatory Validations** (ALL tokens):
1. **Signature**: Valid RS256 signature
2. **Issuer** (`iss`): Matches configured issuer
3. **Audience** (`aud`): Contains service identifier
4. **Expiration** (`exp`): Token not expired (with 5-min clock skew)
5. **Issued At** (`iat`): Token not issued in future
6. **Tenant ID** (`tenant_id`): Matches `X-Tenant-ID` header
7. **Token Version** (`token_version`): Matches user's current version (not revoked)

**Validation Function**:
```scala
case class TokenValidationError(message: String) extends Exception

def validateToken(
  token: JWTToken,
  request: HttpRequest,
  config: AuthConfig
): Either[TokenValidationError, AuthContext] = {
  
  for {
    _ <- validateSignature(token, config.publicKey)
    _ <- validateExpiry(token)
    _ <- validateIssuer(token.iss, config.issuer)
    _ <- validateAudience(token.aud, config.serviceId)
    _ <- validateTenantContext(token.tenant_id, request.headers("X-Tenant-ID"))
    _ <- validateTokenVersion(token.sub, token.token_version)
  } yield {
    AuthContext(
      userId = token.sub,
      tenantId = token.tenant_id,
      organizationId = token.organization_id,
      roles = token.roles,
      permissions = token.permissions
    )
  }
}
```

---

## Permission Enforcement

### Permission Check Algorithm

**Core Logic**:
```scala
def hasPermission(
  authContext: AuthContext, 
  requiredPermission: Permission
): Boolean = {
  
  // Check negative permissions first (deny takes precedence)
  val denials = authContext.permissions.filter(_.startsWith("!"))
  if (denials.exists(p => matchesPermission(p.drop(1), requiredPermission))) {
    return false
  }
  
  // Check positive permissions
  authContext.permissions.exists(p => matchesPermission(p, requiredPermission))
}

def matchesPermission(
  userPerm: Permission, 
  required: Permission
): Boolean = {
  val userParts = userPerm.split(":")
  val reqParts = required.split(":")
  
  // Service must match (or wildcard)
  val serviceMatch = userParts(0) == "*" || userParts(0) == reqParts(0)
  if (!serviceMatch) return false
  
  // Action must match (or wildcard)
  val actionMatch = userParts(1) == "*" || userParts(1) == reqParts(1)
  if (!actionMatch) return false
  
  // Scope must match (or wildcard)
  val scopeMatch = userParts(2) == "*" || userParts(2) == reqParts(2)
  scopeMatch
}
```

### Ownership Checks

**For `own` Scope**: Additional ownership validation required

**Example**:
```scala
def checkOwnership(
  resourceId: UUID, 
  authContext: AuthContext
): Future[Boolean] = {
  // Query database to verify resource ownership
  resourceRepository.findById(resourceId).map { resource =>
    resource.created_by == authContext.userId &&
    resource.tenant_id == authContext.tenantId
  }
}

// Usage in API endpoint
path("carts" / JavaUUID) { cartId =>
  put {
    requirePermission("cart-service:write:own") { authContext =>
      checkOwnership(cartId, authContext).flatMap {
        case true => complete(updateCart(cartId, request))
        case false => complete(StatusCodes.Forbidden)
      }
    }
  }
}
```

### HTTP Directive Pattern

**Reusable Akka HTTP Directive**:
```scala
import akka.http.scaladsl.server.Directives._

def requirePermission(permission: Permission): Directive1[AuthContext] = {
  headerValueByName("Authorization").flatMap { authHeader =>
    extractRequest.flatMap { request =>
      val token = authHeader.replace("Bearer ", "")
      
      validateToken(token, request, config) match {
        case Right(authContext) if hasPermission(authContext, permission) =>
          provide(authContext)
        case Right(_) =>
          complete(StatusCodes.Forbidden, "Insufficient permissions")
        case Left(error) =>
          complete(StatusCodes.Unauthorized, error.message)
      }
    }
  }
}

// Usage
path("users") {
  get {
    requirePermission("entity-management:read:*") { authContext =>
      complete(listUsers(authContext.tenantId))
    }
  }
}
```

---

## Caching Strategy

### Token Validation Cache

**What to Cache**: Validated JWT claims + public key

**Cache Key**: `jwt:validated:{jti}`

**TTL**: Token expiry time (`exp - now`)

**Benefits**:
- Avoid repeated signature verification (expensive RSA operation)
- Avoid repeated claim validation
- Reduce latency from ~10ms to <1ms

**Implementation**:
```scala
def getCachedTokenValidation(
  token: String, 
  jti: String
): Future[Option[AuthContext]] = {
  redis.get(s"jwt:validated:$jti").map {
    case Some(json) => Some(parseAuthContext(json))
    case None => None
  }
}

def cacheTokenValidation(
  jti: String, 
  authContext: AuthContext, 
  expiresAt: Long
): Future[Unit] = {
  val ttl = expiresAt - Instant.now().getEpochSecond
  redis.setex(s"jwt:validated:$jti", ttl.toInt, authContext.toJson)
}

// Validation with caching
def validateTokenCached(token: String): Future[AuthContext] = {
  val decoded = Jwt.decode(token)  // Just decode (no verification yet)
  val jti = decoded.claims.jti
  
  getCachedTokenValidation(token, jti).flatMap {
    case Some(cached) => Future.successful(cached)
    case None =>
      // Not cached - perform full validation
      validateToken(token).map { authContext =>
        cacheTokenValidation(jti, authContext, decoded.claims.exp)
        authContext
      }
  }
}
```

### Permission Evaluation Cache

**What to Cache**: User permission set (flattened from roles)

**Cache Key**: `permissions:{tenant_id}:{user_id}`

**TTL**: 5 minutes (balances freshness vs performance)

**Invalidation**: On role change, permission update, or user update

**Benefits**:
- Avoid repeated Entity Management Service calls
- Permission checks become in-memory lookups (<1ms)

**Implementation**:
```scala
def getUserPermissions(
  tenantId: UUID, 
  userId: UUID
): Future[Set[Permission]] = {
  
  val cacheKey = s"permissions:$tenantId:$userId"
  
  redis.get(cacheKey).flatMap {
    case Some(json) => 
      Future.successful(parsePermissions(json))
    
    case None =>
      // Fetch from Entity Management Service
      entityManagementClient
        .getUserRolesAndPermissions(tenantId, userId)
        .map { result =>
          val permissions = result.roles.flatMap(_.permissions).toSet
          redis.setex(cacheKey, 300, permissions.toJson)  // 5 min TTL
          permissions
        }
  }
}
```

### Public Key Cache

**What to Cache**: RSA public keys from JWKS endpoint

**Cache Key**: `jwks:keys`

**TTL**: 1 hour (keys rotate every 90 days, 1 hour refresh is safe)

**Invalidation**: Manual invalidation on key rotation

**Implementation**:
```scala
def getPublicKeys(): Future[Map[String, PublicKey]] = {
  redis.get("jwks:keys").flatMap {
    case Some(json) => Future.successful(parsePublicKeys(json))
    case None =>
      // Fetch from JWKS endpoint
      httpClient.get("https://auth.tjmpaas.io/.well-known/jwks.json").map { jwks =>
        val keys = parseJWKS(jwks)
        redis.setex("jwks:keys", 3600, keys.toJson)  // 1 hour
        keys
      }
  }
}
```

---

## Revocation Mechanisms

### Token Versioning

**User-Level Token Version**: Incremented on security-sensitive events

**Events Triggering Version Increment**:
- Password change
- Role change
- Permission change
- Account compromise detected
- Manual revocation

**Implementation**:
```scala
case class User(
  id: UUID,
  email: String,
  password_hash: String,
  token_version: Int,  // Incremented on password change
  ...
)

// On password change
def changePassword(userId: UUID, newPassword: String): Future[Unit] = {
  for {
    user <- userRepository.findById(userId)
    hashedPassword = hashPassword(newPassword)
    _ <- userRepository.update(user.copy(
      password_hash = hashedPassword,
      token_version = user.token_version + 1  // Invalidate all tokens
    ))
  } yield ()
}

// Token validation checks version
def validateTokenVersion(userId: UUID, tokenVersion: Int): Future[Boolean] = {
  userRepository.findById(userId).map { user =>
    user.token_version == tokenVersion
  }
}
```

### Refresh Token Blacklist

**What**: Revoked refresh tokens stored in fast lookup (Redis Set)

**Cache Key**: `revoked:refresh:{jti}`

**TTL**: Original token expiry (no need to store after expiry)

**Implementation**:
```scala
def revokeRefreshToken(jti: String, expiresAt: Long): Future[Unit] = {
  val ttl = expiresAt - Instant.now().getEpochSecond
  redis.setex(s"revoked:refresh:$jti", ttl.toInt, "1")
}

def isRefreshTokenRevoked(jti: String): Future[Boolean] = {
  redis.exists(s"revoked:refresh:$jti")
}

// On refresh
def refreshAccessToken(refreshToken: String): Future[TokenSet] = {
  val claims = Jwt.decode(refreshToken).claims
  
  isRefreshTokenRevoked(claims.jti).flatMap {
    case true => Future.failed(TokenRevokedException("Refresh token revoked"))
    case false =>
      // Generate new tokens
      generateTokenSet(claims.sub, claims.tenant_id).map { newTokens =>
        // Revoke old refresh token
        revokeRefreshToken(claims.jti, claims.exp)
        newTokens
      }
  }
}
```

### Emergency Revocation

**Scenario**: User account compromised, need immediate lockout

**Implementation**:
1. Increment user `token_version` (invalidates all access tokens)
2. Add all active refresh tokens to blacklist
3. Force logout on all devices

**Code**:
```scala
def emergencyRevokeAllTokens(userId: UUID): Future[Unit] = {
  for {
    user <- userRepository.findById(userId)
    
    // Increment version (access tokens now invalid)
    _ <- userRepository.update(user.copy(
      token_version = user.token_version + 1
    ))
    
    // Revoke all refresh tokens
    activeSessions <- sessionRepository.findByUserId(userId)
    _ <- Future.traverse(activeSessions) { session =>
      revokeRefreshToken(session.refresh_token_jti, session.expires_at)
    }
    
    // Delete all sessions
    _ <- sessionRepository.deleteByUserId(userId)
    
  } yield ()
}
```

---

## Security Considerations

### Token Storage

**Client-Side Storage**:

| Token Type | Storage | Rationale |
|------------|---------|-----------|
| Access Token | Memory only (variable) | Short-lived, minimal XSS risk |
| Refresh Token | HTTP-only cookie (preferred) or secure storage | Prevents XSS access |
| ID Token | Memory or localStorage | No sensitive permissions |

**Refresh Token Security**:
- **HTTP-only cookie**: Best option (immune to XSS)
  - `Set-Cookie: refresh_token=...; HttpOnly; Secure; SameSite=Strict`
- **Secure storage**: Second option (mobile apps, SPAs)
  - iOS Keychain, Android Keystore, React Native SecureStore

**Anti-Patterns** (DO NOT DO):
- ❌ Store access token in localStorage (XSS vulnerability)
- ❌ Store refresh token in localStorage (critical vulnerability)
- ❌ Log tokens to console or files
- ❌ Send tokens in URL parameters (logged in server/proxy logs)

### Transport Security

**TLS 1.3 Required**: All API communication MUST use TLS 1.3

**HTTP Headers**:
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
```

### Secret Management

**Private Key Storage**:
- **Production**: Hardware Security Module (HSM) or cloud KMS (GCP Cloud KMS, AWS KMS)
- **Development**: Encrypted files in secure vault (HashiCorp Vault)
- **Never**: Plain text files, environment variables, or source control

**Key Rotation**:
- Rotate signing keys every 90 days
- Support dual keys during rotation (old + new)
- Update JWKS endpoint with new public key
- Tokens signed with old key remain valid until expiry

### Clock Skew Tolerance

**Issue**: Distributed systems have clock drift

**Solution**: 5-minute clock skew tolerance

**Implementation**:
```scala
val CLOCK_SKEW_SECONDS = 300  // 5 minutes

def validateExpiry(token: JWTToken): Boolean = {
  val now = Instant.now().getEpochSecond
  val exp = token.claims.exp
  now <= exp + CLOCK_SKEW_SECONDS  // Allow 5 min grace period
}

def validateIssuedAt(token: JWTToken): Boolean = {
  val now = Instant.now().getEpochSecond
  val iat = token.claims.iat
  iat <= now + CLOCK_SKEW_SECONDS  // Reject tokens issued >5 min in future
}
```

### Rate Limiting

**Token Endpoint**: Prevent brute-force attacks

**Limits**:
- `/auth/login`: 5 attempts per email per 15 minutes
- `/auth/refresh`: 10 requests per refresh token per hour
- `/auth/register`: 3 registrations per IP per hour

**Implementation**:
```scala
def rateLimitLogin(email: String): Future[Boolean] = {
  val key = s"ratelimit:login:$email"
  redis.incr(key).flatMap { count =>
    if (count == 1) redis.expire(key, 900)  // 15 min
    Future.successful(count <= 5)
  }
}
```

### Replay Attack Prevention

**Mechanisms**:
1. **JTI (JWT ID)**: Unique token identifier, can be checked against cache
2. **Short expiry**: Access tokens expire in 1 hour
3. **Refresh token rotation**: Single-use refresh tokens
4. **Nonce**: Optional nonce in token for additional replay protection

---

## Implementation Patterns

### Scala Implementation (Akka HTTP)

**Complete Middleware**:
```scala
import akka.http.scaladsl.server.Directives._
import akka.http.scaladsl.server.Directive1
import pdi.jwt.{Jwt, JwtAlgorithm, JwtClaim}

trait JWTAuth {
  
  def authenticateJWT: Directive1[AuthContext] = {
    headerValueByName("Authorization").flatMap { authHeader =>
      extractRequest.flatMap { request =>
        
        // Extract Bearer token
        val token = authHeader.replace("Bearer ", "")
        
        // Validate token (with caching)
        validateTokenCached(token, request) match {
          case Right(authContext) => provide(authContext)
          case Left(error) => complete(StatusCodes.Unauthorized, error.message)
        }
      }
    }
  }
  
  def requirePermission(permission: Permission): Directive1[AuthContext] = {
    authenticateJWT.flatMap { authContext =>
      if (hasPermission(authContext, permission)) {
        provide(authContext)
      } else {
        complete(StatusCodes.Forbidden, s"Missing permission: $permission")
      }
    }
  }
  
  def requireRole(role: String): Directive1[AuthContext] = {
    authenticateJWT.flatMap { authContext =>
      if (authContext.roles.contains(role)) {
        provide(authContext)
      } else {
        complete(StatusCodes.Forbidden, s"Missing role: $role")
      }
    }
  }
}

// Usage in routes
class EntityManagementRoutes extends JWTAuth {
  
  val routes: Route = 
    path("users") {
      get {
        requirePermission("entity-management:read:*") { authContext =>
          complete(listUsers(authContext.tenantId))
        }
      } ~
      post {
        requirePermission("entity-management:write:*") { authContext =>
          entity(as[CreateUserRequest]) { request =>
            complete(createUser(request, authContext))
          }
        }
      }
    } ~
    path("users" / JavaUUID) { userId =>
      delete {
        requirePermission("entity-management:delete:*") { authContext =>
          complete(deleteUser(userId, authContext.tenantId))
        }
      }
    }
}
```

### Token Generation Service

**Auth Service Implementation**:
```scala
import pdi.jwt.{JwtCirce, JwtAlgorithm}
import java.time.Instant

class TokenService(
  config: AuthConfig,
  privateKey: PrivateKey,
  userRepository: UserRepository,
  roleRepository: RoleRepository
) {
  
  def generateTokenSet(
    userId: UUID, 
    tenantId: UUID
  ): Future[TokenSet] = {
    
    for {
      user <- userRepository.findById(userId)
      roles <- roleRepository.findByUserId(userId, tenantId)
      permissions = roles.flatMap(_.permissions).toSet
      
      accessToken = generateAccessToken(user, tenantId, roles, permissions)
      refreshToken = generateRefreshToken(user, tenantId)
      idToken = generateIDToken(user, tenantId)
      
    } yield TokenSet(
      access_token = accessToken,
      refresh_token = refreshToken,
      id_token = idToken,
      token_type = "Bearer",
      expires_in = 3600
    )
  }
  
  private def generateAccessToken(
    user: User,
    tenantId: UUID,
    roles: Seq[Role],
    permissions: Set[Permission]
  ): String = {
    
    val now = Instant.now().getEpochSecond
    val exp = now + 3600  // 1 hour
    
    val claims = Json.obj(
      "iss" -> config.issuer,
      "sub" -> user.id.toString,
      "aud" -> Json.arr("tjmpaas-api"),
      "exp" -> exp,
      "iat" -> now,
      "jti" -> UUID.randomUUID().toString,
      "tenant_id" -> tenantId.toString,
      "organization_id" -> user.primary_organization_id.toString,
      "roles" -> roles.map(_.name),
      "permissions" -> permissions.toSeq,
      "token_version" -> user.token_version
    )
    
    JwtCirce.encode(claims, privateKey, JwtAlgorithm.RS256)
  }
  
  private def generateRefreshToken(
    user: User, 
    tenantId: UUID
  ): String = {
    
    val now = Instant.now().getEpochSecond
    val exp = now + 2592000  // 30 days
    
    val claims = Json.obj(
      "token_type" -> "refresh",
      "jti" -> UUID.randomUUID().toString,
      "sub" -> user.id.toString,
      "tenant_id" -> tenantId.toString,
      "iat" -> now,
      "exp" -> exp,
      "iss" -> config.issuer,
      "aud" -> "tjmpaas-refresh"
    )
    
    JwtCirce.encode(claims, privateKey, JwtAlgorithm.RS256)
  }
  
  private def generateIDToken(
    user: User, 
    tenantId: UUID
  ): String = {
    
    val now = Instant.now().getEpochSecond
    val exp = now + 3600  // 1 hour
    
    val claims = Json.obj(
      "sub" -> user.id.toString,
      "email" -> user.email,
      "name" -> user.name,
      "email_verified" -> user.email_verified,
      "tenant_id" -> tenantId.toString,
      "organization_id" -> user.primary_organization_id.toString,
      "iat" -> now,
      "exp" -> exp,
      "iss" -> config.issuer,
      "aud" -> "tjmpaas-client"
    )
    
    JwtCirce.encode(claims, privateKey, JwtAlgorithm.RS256)
  }
}
```

---

## Integration with Entity Management Service

Entity Management Service (EMS) is the **source of truth** for users, roles, and permissions in TJMPaaS.

### Integration Points

**1. User Authentication**: Auth Service validates credentials against EMS user store

**2. Role and Permission Fetching**: Auth Service queries EMS for user's roles and permissions

**3. Token Generation**: Auth Service embeds EMS roles/permissions in access token

**4. Permission Updates**: EMS publishes events when roles/permissions change → invalidates permission cache

### Event-Driven Permission Updates

**Event Flow**:
```mermaid
sequenceDiagram
    participant EMS as Entity Mgmt
    participant Kafka
    participant AuthService
    participant Redis
    
    EMS->>EMS: Admin updates user role
    EMS->>Kafka: Publish RoleUpdated event
    Kafka->>AuthService: Consume event
    AuthService->>Redis: Invalidate permission cache<br/>DELETE permissions:{tenant_id}:{user_id}
    
    Note over AuthService,Redis: Next API request will fetch<br/>fresh permissions from EMS
```

**Event Schema**:
```json
{
  "event_type": "role.permissions_updated",
  "event_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-01-15T10:30:00Z",
  "data": {
    "role_id": "990e8400-e29b-41d4-a716-446655440000",
    "affected_users": [
      "880e8400-e29b-41d4-a716-446655440000",
      "990e8400-e29b-41d4-a716-446655440000"
    ]
  }
}
```

**Consumer Implementation**:
```scala
class PermissionUpdateConsumer(redis: RedisClient) {
  
  def handleRoleUpdated(event: RoleUpdatedEvent): Future[Unit] = {
    // Invalidate permission cache for all affected users
    Future.traverse(event.data.affected_users) { userId =>
      val cacheKey = s"permissions:${event.tenant_id}:$userId"
      redis.del(cacheKey)
    }.map(_ => ())
  }
  
  def handleUserRoleAssigned(event: UserRoleAssignedEvent): Future[Unit] = {
    // Invalidate permission cache for user
    val cacheKey = s"permissions:${event.tenant_id}:${event.data.user_id}"
    redis.del(cacheKey)
  }
}
```

### Permission Format Alignment

EMS permission model (from `role-permissions.md`):
- Format: `service:action:scope` ✅ **MATCHES THIS STANDARD**
- Scope semantics: `*`, `own`, `{resource_type}` ✅ **MATCHES**
- Actions: `read`, `write`, `delete`, `approve`, `admin` ✅ **MATCHES**

**No conflicts** - EMS design already aligns with JWT permission model.

---

## Examples

### Example 1: Tenant Admin Login

**Request**:
```http
POST /auth/login HTTP/1.1
Host: auth.tjmpaas.io
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "SecurePass123!",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

**Decoded Access Token**:
```json
{
  "iss": "https://auth.tjmpaas.io",
  "sub": "880e8400-e29b-41d4-a716-446655440000",
  "aud": ["tjmpaas-api", "entity-management", "cart-service"],
  "exp": 1734204000,
  "iat": 1734200400,
  "jti": "f1e2d3c4-b5a6-7890-1234-567890abcdef",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "organization_id": "770e8400-e29b-41d4-a716-446655440000",
  "roles": ["tenant-admin"],
  "permissions": [
    "entity-management:read:*",
    "entity-management:write:*",
    "entity-management:delete:*",
    "!entity-management:delete:tenants",
    "cart-service:read:*",
    "cart-service:write:*"
  ],
  "token_version": 5
}
```

### Example 2: API Request with JWT

**Request**:
```http
GET /api/v1/users HTTP/1.1
Host: entity-management.tjmpaas.io
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
X-Tenant-ID: 550e8400-e29b-41d4-a716-446655440000
```

**Server-Side Validation**:
```scala
// 1. Extract and validate JWT
val token = request.headers("Authorization").replace("Bearer ", "")
val authContext = validateTokenCached(token, request).toOption.get

// 2. Validate tenant context
assert(authContext.tenant_id == request.headers("X-Tenant-ID"))

// 3. Check permission
assert(hasPermission(authContext, "entity-management:read:*"))

// 4. Execute query (tenant-scoped)
val users = usersTable
  .filter(_.tenant_id === authContext.tenant_id)
  .result
```

**Response**:
```json
{
  "users": [
    {
      "user_id": "880e8400-e29b-41d4-a716-446655440000",
      "email": "admin@example.com",
      "name": "Alice Admin",
      "roles": ["tenant-admin"]
    },
    {
      "user_id": "990e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "Bob User",
      "roles": ["team-member"]
    }
  ]
}
```

### Example 3: Token Refresh

**Request**:
```http
POST /auth/refresh HTTP/1.1
Host: auth.tjmpaas.io
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Server-Side Flow**:
```scala
// 1. Validate refresh token
val refreshClaims = Jwt.decode(refreshToken).claims

// 2. Check if revoked
if (isRefreshTokenRevoked(refreshClaims.jti)) {
  throw TokenRevokedException("Refresh token has been revoked")
}

// 3. Fetch fresh permissions from EMS
val permissions = getUserPermissions(refreshClaims.tenant_id, refreshClaims.sub)

// 4. Generate new token set
val newTokens = generateTokenSet(refreshClaims.sub, refreshClaims.tenant_id)

// 5. Revoke old refresh token
revokeRefreshToken(refreshClaims.jti, refreshClaims.exp)

// 6. Return new tokens
newTokens
```

**Response**: Same as login response (new access, refresh, ID tokens)

### Example 4: Permission Check with `own` Scope

**Scenario**: User wants to update their own cart

**API Request**:
```http
PUT /api/v1/carts/a1b2c3d4-e5f6-7890-abcd-ef1234567890 HTTP/1.1
Host: cart-service.tjmpaas.io
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
X-Tenant-ID: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{
  "items": [
    {"product_id": "prod-123", "quantity": 2}
  ]
}
```

**Server-Side Validation**:
```scala
// 1. Validate JWT and extract auth context
val authContext = validateTokenCached(token, request).toOption.get

// 2. Check permission (has cart-service:write:own)
assert(hasPermission(authContext, "cart-service:write:own"))

// 3. Check ownership (additional check for "own" scope)
val cart = cartRepository.findById(cartId).futureValue

if (cart.user_id != authContext.userId) {
  complete(StatusCodes.Forbidden, "Cannot modify another user's cart")
} else if (cart.tenant_id != authContext.tenantId) {
  complete(StatusCodes.Forbidden, "Tenant isolation violation")
} else {
  // 4. Execute update
  complete(updateCart(cartId, request.body))
}
```

---

## References

### Standards and Specifications

- **RFC 7519**: JSON Web Token (JWT) - https://datatracker.ietf.org/doc/html/rfc7519
- **RFC 7515**: JSON Web Signature (JWS) - https://datatracker.ietf.org/doc/html/rfc7515
- **RFC 6749**: OAuth 2.0 Authorization Framework - https://datatracker.ietf.org/doc/html/rfc6749
- **OpenID Connect Core 1.0**: https://openid.net/specs/openid-connect-core-1_0.html
- **NIST SP 800-63B**: Digital Identity Guidelines (Authentication and Lifecycle Management) - https://pages.nist.gov/800-63-3/sp800-63b.html

### Best Practices and Guides

- **JWT Best Practices**: https://datatracker.ietf.org/doc/html/rfc8725
- **OWASP Authentication Cheat Sheet**: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- **OWASP JWT Cheat Sheet**: https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html
- **Auth0 JWT Best Practices**: https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/

### TJMPaaS Internal References

- [Entity Management Service - Security Requirements](../services/entity-management/SECURITY-REQUIREMENTS.md)
- [Entity Management Service - Role-Based Permissions](../services/entity-management/features/role-permissions.md)
- [Multi-Tenant Seam Architecture](./MULTI-TENANT-SEAM-ARCHITECTURE.md)
- [ADR-0005: Reactive Manifesto Alignment](../../governance/ADRs/ADR-0005-reactive-manifesto-alignment.md)
- [ADR-0006: Agent-Based Service Patterns](../../governance/ADRs/ADR-0006-agent-patterns.md)

### Libraries and Tools

- **Scala JWT**: https://github.com/jwt-scala/jwt-scala (pdi-jwt)
- **Akka HTTP**: https://doc.akka.io/docs/akka-http/current/
- **Redis**: https://redis.io/documentation (caching layer)
- **JWKS (JSON Web Key Set)**: https://datatracker.ietf.org/doc/html/rfc7517

---

## Appendix A: Token Size Analysis

**Typical Access Token Size**:
- Header: ~100 bytes
- Claims (10 permissions): ~800 bytes
- Signature (RS256): ~256 bytes
- **Total**: ~1,156 bytes (within 2KB budget)

**For Users with 100+ Permissions**:
- Use permission hash instead of full list
- Token contains: `"permission_hash": "sha256:abc123def456"`
- Service fetches full permissions from cache using hash
- Reduces token size to ~600 bytes

## Appendix B: Clock Skew Scenarios

**Scenario 1**: Server clock 10 minutes fast
- Token issued: 1734200400 (server time)
- Actual time: 1734199800 (10 min earlier)
- Validation: Token appears issued 10 min in future
- Result: ✅ **ACCEPTED** (within 5 min tolerance after accounting for clock drift)

**Scenario 2**: Server clock 3 minutes slow
- Token expiry: 1734204000 (server time)
- Actual time: 1734204180 (3 min later)
- Validation: Token expired 3 min ago
- Result: ✅ **ACCEPTED** (within 5 min grace period)

## Appendix C: Permission Matrix Example

| Role | Permissions |
|------|-------------|
| **Super Admin** | `admin:*:*` |
| **Tenant Owner** | `entity-management:*:*`, `cart-service:*:*`, `order-service:*:*` |
| **Tenant Admin** | `entity-management:read:*`, `entity-management:write:*`, `entity-management:delete:*`, `!entity-management:delete:tenants` |
| **Org Admin** | `entity-management:read:organization`, `entity-management:write:organization`, `cart-service:read:*` |
| **Team Member** | `entity-management:read:own`, `entity-management:write:own`, `cart-service:read:own`, `cart-service:write:own` |

---

**Document Version**: 1.0.0  
**Last Updated**: December 14, 2025  
**Next Review**: March 14, 2026 (Quarterly)  
**Approved By**: Tony Moores  
**Status**: Active Standard

