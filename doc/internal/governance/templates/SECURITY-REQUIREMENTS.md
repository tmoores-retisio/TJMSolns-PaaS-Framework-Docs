# {Service Name} Security Requirements

**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Template Version**: 1.0

---

**Instructions**: Copy this template to service repository `docs/SECURITY-REQUIREMENTS.md`. This defines comprehensive security requirements for the service.

---

## Overview

**Service**: {Service Name}  
**Security Classification**: {Public / Internal / Confidential / Restricted}  
**Data Sensitivity**: {Low / Medium / High / Critical}  
**Compliance Requirements**: {GDPR / PCI-DSS / HIPAA / SOC2 / None}

## Authentication

### Authentication Mechanisms

**Primary**: JWT (JSON Web Token)

**Token Structure**:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "660e8400-e29b-41d4-a716-446655440000",  // User ID
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "roles": ["tenant-admin"],
    "permissions": [
      "{service-name}:read:*",
      "{service-name}:write:*",
      "{service-name}:delete:*"
    ],
    "iat": 1640000000,  // Issued at
    "exp": 1640003600,  // Expires at (1 hour)
    "iss": "https://auth.{domain}",
    "aud": "{service-name}"
  },
  "signature": "..."
}
```

**Token Requirements**:
- Algorithm: RS256 (RSA with SHA-256)
- Key length: 2048 bits minimum
- Token expiry: 1 hour (access tokens), 30 days (refresh tokens)
- Claims required: `sub`, `tenant_id`, `exp`, `iat`, `iss`, `aud`

### Token Validation

**Validation Steps**:
1. Verify signature using public key
2. Check token expiry (`exp` claim)
3. Verify issuer (`iss` claim matches expected issuer)
4. Verify audience (`aud` claim matches service name)
5. Extract `tenant_id` from JWT payload
6. Compare JWT `tenant_id` with X-Tenant-ID header (must match)

**Code Example**:
```scala
import pdi.jwt.{Jwt, JwtAlgorithm, JwtClaim}

def validateToken(token: String, tenantIdHeader: UUID): Either[AuthError, AuthContext] = {
  for {
    // Verify signature and decode
    claim <- Jwt.decode(token, publicKey, Seq(JwtAlgorithm.RS256))
      .toEither.left.map(_ => InvalidToken)
    
    // Parse claims
    payload <- io.circe.parser.decode[TokenPayload](claim.content)
      .left.map(_ => InvalidToken)
    
    // Verify expiry
    _ <- Either.cond(payload.exp > currentTimestamp, (), TokenExpired)
    
    // Verify issuer
    _ <- Either.cond(payload.iss == expectedIssuer, (), InvalidIssuer)
    
    // Verify audience
    _ <- Either.cond(payload.aud == serviceName, (), InvalidAudience)
    
    // Verify tenant_id matches header
    _ <- Either.cond(payload.tenant_id == tenantIdHeader, (), TenantMismatch)
    
  } yield AuthContext(payload.sub, payload.tenant_id, payload.roles, payload.permissions)
}
```

### Token Storage

**Client-Side**:
- Access tokens: Memory only (never localStorage for security)
- Refresh tokens: HttpOnly cookies (secure, SameSite=Strict)

**Server-Side**:
- No token storage required (stateless JWT)
- Refresh tokens: Database with expiry

### Token Revocation

**Mechanisms**:
- Short-lived access tokens (1 hour) - natural expiry
- Refresh token revocation via database blacklist
- User logout: Invalidate refresh token
- Admin revocation: Add token to revocation list (Redis cache, 1-hour TTL)

**Revocation Check**:
```scala
def isTokenRevoked(tokenId: String): Future[Boolean] = {
  redis.get(s"revoked:$tokenId").map(_.isDefined)
}
```

## Authorization

### Authorization Model

**Role-Based Access Control (RBAC)**:
- Roles assigned to users per tenant
- Permissions assigned to roles
- Hierarchical roles (role inheritance)

**Roles**:
- `tenant-owner`: Full tenant access
- `tenant-admin`: Tenant management (no billing changes)
- `tenant-user`: Standard user access
- `tenant-readonly`: Read-only access

**Permissions Format**: `{service}:{action}:{scope}`

**Examples**:
- `entity-management:read:*` - Read any entity
- `entity-management:write:own` - Write own entities
- `entity-management:delete:*` - Delete any entity
- `entity-management:admin:tenants` - Admin tenant entities

### Permission Enforcement

**API Layer**:
```scala
def requirePermission(permission: String): Directive1[AuthContext] = {
  extractAuthContext.flatMap { authContext =>
    if (authContext.hasPermission(permission))
      provide(authContext)
    else
      complete(StatusCodes.Forbidden -> Error("insufficient_permissions", s"Missing permission: $permission"))
  }
}

// Usage in route
path("tenants" / JavaUUID) { tenantId =>
  get {
    requirePermission("entity-management:read:tenants") { authContext =>
      // Verify tenant ownership
      if (authContext.tenantId == tenantId || authContext.hasRole("platform-admin")) {
        complete(getTenant(tenantId))
      } else {
        complete(StatusCodes.Forbidden)
      }
    }
  }
}
```

**Domain Layer (Actor)**:
```scala
def handleCommand(cmd: Command, authContext: AuthContext): Effect[Event, State] = cmd match {
  case DeleteTenant(tenantId) =>
    // Check authorization
    if (!authContext.hasPermission("entity-management:delete:tenants")) {
      Effect.reply(Forbidden("Missing permission: entity-management:delete:tenants"))
    } else if (authContext.tenantId != tenantId && !authContext.hasRole("platform-admin")) {
      Effect.reply(Forbidden("Cannot delete other tenant"))
    } else {
      // Authorized - proceed
      Effect.persist(TenantDeleted(tenantId))
        .thenReply(_ => Success)
    }
}
```

### Attribute-Based Access Control (ABAC)

**Context-Sensitive Permissions**:
- Resource ownership (user owns resource)
- Tenant membership (user in tenant)
- Data classification (resource sensitivity level)
- Time-based (business hours only)

**Example**:
```scala
def canAccessResource(user: User, resource: Resource): Boolean = {
  // Check tenant membership
  val inTenant = user.tenantId == resource.tenantId
  
  // Check ownership or admin role
  val isOwner = resource.ownerId == user.id
  val isAdmin = user.roles.contains("tenant-admin")
  
  // Check data classification
  val hasDataClearance = user.dataClearance >= resource.classification
  
  inTenant && (isOwner || isAdmin) && hasDataClearance
}
```

## Multi-Tenant Security

### Tenant Isolation

**Mandatory Requirements**:
1. **X-Tenant-ID Header**: Required on all requests (except tenant creation)
2. **JWT Tenant Claim**: `tenant_id` claim must match X-Tenant-ID header
3. **Database Isolation**: All queries filtered by `tenant_id`
4. **Actor Isolation**: Actors validate tenant ownership in all commands
5. **Event Isolation**: Events include `tenant_id`, consumers filter by tenant
6. **No Cross-Tenant Access**: Attempts logged as security incidents

### Tenant Context Validation

**API Layer**:
```scala
def extractTenantContext: Directive1[TenantContext] = {
  (headerValueByName("X-Tenant-ID") & extractAuthContext).tflatMap {
    case (tenantIdHeader, authContext) =>
      Try(UUID.fromString(tenantIdHeader)) match {
        case Success(tenantId) =>
          // Verify JWT tenant_id matches header
          if (authContext.tenantId == tenantId) {
            provide(TenantContext(tenantId, authContext))
          } else {
            complete(StatusCodes.Forbidden -> Error(
              "tenant_mismatch",
              "JWT tenant_id does not match X-Tenant-ID header"
            ))
          }
        case Failure(_) =>
          complete(StatusCodes.BadRequest -> Error(
            "invalid_tenant_id",
            "X-Tenant-ID must be valid UUID"
          ))
      }
  }
}
```

**Database Layer**:
```sql
-- All queries MUST include tenant_id filter
SELECT * FROM tenants WHERE tenant_id = ? AND id = ?;

-- Use row-level security policies (PostgreSQL)
CREATE POLICY tenant_isolation ON tenants
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
```

**Actor Layer**:
```scala
def handleCommand(cmd: Command): Effect[Event, State] = cmd match {
  case CreateUser(tenantId, userId, data) =>
    // Validate tenant ownership
    if (tenantId != state.tenantId) {
      Effect.reply(Forbidden("Cannot create user in different tenant"))
    } else {
      Effect.persist(UserCreated(tenantId, userId, data))
        .thenReply(_ => Success)
    }
}
```

### Cross-Tenant Access Prevention

**Monitoring**:
```scala
// Log and alert on cross-tenant access attempts
if (requestedTenantId != authContext.tenantId && !authContext.hasRole("platform-admin")) {
  logger.warn(
    "Cross-tenant access attempt",
    "user_id" -> authContext.userId,
    "user_tenant_id" -> authContext.tenantId,
    "requested_tenant_id" -> requestedTenantId,
    "request_id" -> requestId
  )
  
  metrics.counter("cross_tenant_access_attempts_total")
    .tag("user_tenant_id", authContext.tenantId.toString)
    .tag("requested_tenant_id", requestedTenantId.toString)
    .increment()
  
  // Return 404 (not 403) to avoid tenant enumeration
  complete(StatusCodes.NotFound)
}
```

**Automated Testing**:
```scala
"Multi-tenant isolation" should "prevent cross-tenant access" in {
  // Create resource in tenant A
  val resourceA = createResource(tenantIdA, data)
  
  // Attempt access from tenant B
  val response = Get(s"/api/v1/resources/${resourceA.id}")
    .withHeaders(
      RawHeader("X-Tenant-ID", tenantIdB.toString),
      RawHeader("Authorization", s"Bearer ${jwtTenantB}")
    ) ~> routes
  
  // Should return 404 or 403, not 200 with data
  response.status shouldBe StatusCodes.NotFound
}
```

## Data Protection

### Encryption at Rest

**Database Encryption**:
- **Transparent Data Encryption (TDE)**: Entire database encrypted (PostgreSQL pgcrypto extension)
- **Column-Level Encryption**: Sensitive fields encrypted (PII, credentials)
- **Encryption Algorithm**: AES-256-GCM
- **Key Management**: Google Cloud KMS (or AWS KMS)

**Encrypted Fields**:
| Field | Table | Encryption Method | Key Rotation |
|-------|-------|------------------|--------------|
| email | users | AES-256-GCM | 90 days |
| phone | users | AES-256-GCM | 90 days |
| api_key | tenants | AES-256-GCM | 30 days |
| webhook_secret | tenants | AES-256-GCM | 30 days |

**Encryption Example**:
```scala
import javax.crypto.Cipher
import javax.crypto.spec.{GCMParameterSpec, SecretKeySpec}

def encryptField(plaintext: String, key: Array[Byte]): String = {
  val cipher = Cipher.getInstance("AES/GCM/NoPadding")
  val iv = generateIV() // 12 bytes random
  val gcmSpec = new GCMParameterSpec(128, iv)
  val keySpec = new SecretKeySpec(key, "AES")
  
  cipher.init(Cipher.ENCRYPT_MODE, keySpec, gcmSpec)
  val ciphertext = cipher.doFinal(plaintext.getBytes("UTF-8"))
  
  // Return IV + ciphertext as base64
  Base64.getEncoder.encodeToString(iv ++ ciphertext)
}

def decryptField(encrypted: String, key: Array[Byte]): String = {
  val bytes = Base64.getDecoder.decode(encrypted)
  val iv = bytes.take(12)
  val ciphertext = bytes.drop(12)
  
  val cipher = Cipher.getInstance("AES/GCM/NoPadding")
  val gcmSpec = new GCMParameterSpec(128, iv)
  val keySpec = new SecretKeySpec(key, "AES")
  
  cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec)
  new String(cipher.doFinal(ciphertext), "UTF-8")
}
```

### Encryption in Transit

**TLS Requirements**:
- **Protocol**: TLS 1.3 (or TLS 1.2 minimum)
- **Cipher Suites**: Strong ciphers only (ECDHE-RSA-AES256-GCM-SHA384, ECDHE-RSA-AES128-GCM-SHA256)
- **Certificate**: Valid X.509 certificate from trusted CA
- **HSTS**: Strict-Transport-Security header (max-age=31536000; includeSubDomains)

**Kubernetes Ingress**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {service-name}
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.3"
    nginx.ingress.kubernetes.io/ssl-ciphers: "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"
spec:
  tls:
  - hosts:
    - api.{domain}
    secretName: {service-name}-tls
  rules:
  - host: api.{domain}
    http:
      paths:
      - path: /api/v1/{service}
        pathType: Prefix
        backend:
          service:
            name: {service-name}
            port:
              number: 8080
```

**Internal Services** (Kubernetes):
- Service mesh (Istio/Linkerd) with mTLS for pod-to-pod communication
- Certificate rotation automated (cert-manager)

### Data Masking

**Logging**:
- PII fields masked in logs (email → e***@example.com, phone → ***-***-1234)
- Tokens masked (JWT → first 8 chars + "...")
- Passwords never logged

**Masking Example**:
```scala
def maskEmail(email: String): String = {
  val parts = email.split("@")
  if (parts.length == 2) {
    val local = parts(0)
    val masked = local.take(1) + "***"
    s"$masked@${parts(1)}"
  } else {
    "***"
  }
}

def maskToken(token: String): String = {
  if (token.length > 8) {
    token.take(8) + "..."
  } else {
    "***"
  }
}

// Usage in logging
logger.info(
  "User logged in",
  "email" -> maskEmail(user.email),
  "token" -> maskToken(jwt)
)
```

## Input Validation

### Validation Rules

**UUID Validation**:
```scala
def validateUUID(input: String): Either[ValidationError, UUID] = {
  Try(UUID.fromString(input)).toEither
    .left.map(_ => ValidationError("invalid_uuid", s"Invalid UUID: $input"))
}
```

**Email Validation**:
```scala
def validateEmail(input: String): Either[ValidationError, String] = {
  val emailRegex = """^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$""".r
  emailRegex.findFirstIn(input) match {
    case Some(_) => Right(input)
    case None => Left(ValidationError("invalid_email", s"Invalid email: $input"))
  }
}
```

**String Sanitization** (prevent XSS):
```scala
import org.owasp.encoder.Encode

def sanitizeString(input: String): String = {
  Encode.forHtml(input) // Escapes HTML special characters
}
```

**SQL Injection Prevention**:
- Use parameterized queries (prepared statements)
- Never concatenate user input into SQL strings
- Use ORM/query builder (Doobie, Slick, Quill)

**Example (Doobie)**:
```scala
def getUserById(userId: UUID): ConnectionIO[Option[User]] = {
  sql"SELECT id, email, created_at FROM users WHERE id = $userId"
    .query[User]
    .option
}
```

### API Input Validation

**Request Body Validation**:
```scala
case class CreateTenantRequest(
  name: String,
  subscription_plan: String,
  admin_email: String
)

object CreateTenantRequest {
  implicit val decoder: Decoder[CreateTenantRequest] = deriveDecoder
  
  def validate(req: CreateTenantRequest): Either[ValidationErrors, CreateTenantRequest] = {
    val errors = List(
      validateNonEmpty(req.name, "name"),
      validateSubscriptionPlan(req.subscription_plan),
      validateEmail(req.admin_email)
    ).flatten
    
    if (errors.isEmpty) Right(req) else Left(ValidationErrors(errors))
  }
}
```

**Header Validation**:
```scala
def validateTenantIdHeader(header: String): Either[ValidationError, UUID] = {
  validateUUID(header)
}
```

## Security Headers

### HTTP Security Headers

**Required Headers**:
```scala
def securityHeaders: Seq[HttpHeader] = Seq(
  // Prevent clickjacking
  RawHeader("X-Frame-Options", "DENY"),
  
  // Prevent MIME sniffing
  RawHeader("X-Content-Type-Options", "nosniff"),
  
  // XSS protection (legacy but still useful)
  RawHeader("X-XSS-Protection", "1; mode=block"),
  
  // Referrer policy
  RawHeader("Referrer-Policy", "strict-origin-when-cross-origin"),
  
  // Content Security Policy
  RawHeader("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none'"),
  
  // HSTS (force HTTPS)
  RawHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains"),
  
  // Permissions policy
  RawHeader("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
)

// Apply to all responses
respondWithHeaders(securityHeaders) {
  // routes
}
```

### CORS Configuration

**Allowed Origins**:
- Production: `https://*.{domain}`
- Staging: `https://*.staging.{domain}`
- Development: `http://localhost:*`

**CORS Headers**:
```scala
val corsSettings = CorsSettings.defaultSettings.withAllowedOrigins(
  HttpOriginMatcher(
    HttpOrigin("https://app.example.com"),
    HttpOrigin("https://admin.example.com")
  )
).withAllowedMethods(Seq(GET, POST, PUT, PATCH, DELETE, OPTIONS))
  .withAllowedHeaders(Seq("Authorization", "X-Tenant-ID", "Content-Type"))
  .withExposedHeaders(Seq("X-Request-ID", "X-RateLimit-Remaining"))
  .withAllowCredentials(true)

// Apply CORS
cors(corsSettings) {
  // routes
}
```

## Audit Logging

### Audit Events

**Required Audit Events**:
- Authentication events (login, logout, token refresh)
- Authorization failures (permission denied, cross-tenant access attempts)
- Data modifications (create, update, delete)
- Admin actions (user role changes, tenant settings)
- Security events (failed login attempts, token revocation)

**Audit Log Format**:
```json
{
  "timestamp": "2025-01-15T10:30:45.123Z",
  "event_type": "audit.tenant.created",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "660e8400-e29b-41d4-a716-446655440000",
  "user_email": "admin@example.com",
  "action": "CREATE",
  "resource_type": "tenant",
  "resource_id": "550e8400-e29b-41d4-a716-446655440000",
  "request_id": "770e8400-e29b-41d4-a716-446655440000",
  "ip_address": "203.0.113.42",
  "user_agent": "Mozilla/5.0 ...",
  "details": {
    "tenant_name": "Acme Corp",
    "subscription_plan": "gold"
  },
  "result": "success"
}
```

### Audit Log Storage

**Requirements**:
- Immutable (append-only)
- Retention: 7 years (compliance requirement)
- Indexed by: tenant_id, user_id, event_type, timestamp
- Storage: Separate audit database or event store

**Example**:
```scala
def logAuditEvent(event: AuditEvent): Future[Unit] = {
  auditLogRepository.insert(event).map { _ =>
    logger.info("Audit event logged", "event_type" -> event.eventType)
    metrics.counter("audit_events_total")
      .tag("event_type", event.eventType)
      .tag("tenant_id", event.tenantId.toString)
      .increment()
  }
}
```

## Threat Model

### Identified Threats

| Threat | Impact | Likelihood | Mitigation |
|--------|--------|------------|------------|
| Cross-tenant data access | High | Medium | Tenant ID validation at all layers, isolation tests |
| JWT token theft | High | Low | Short-lived tokens (1 hour), HTTPS only, HttpOnly cookies |
| SQL injection | High | Low | Parameterized queries, input validation |
| XSS attacks | Medium | Low | Input sanitization, CSP headers |
| DDoS | Medium | Medium | Rate limiting, Kubernetes autoscaling, Cloudflare |
| Man-in-the-middle | High | Low | TLS 1.3, certificate pinning (mobile apps) |
| Privilege escalation | High | Low | RBAC, permission checks, audit logging |
| Data breach (DB compromise) | Critical | Low | Encryption at rest, access controls, monitoring |

### Attack Surface

**External Attack Surface**:
- REST API endpoints (authenticated, rate-limited)
- Webhook endpoints (signature validation required)

**Internal Attack Surface**:
- Kafka topics (consumer authentication required)
- Database (network policies, credentials rotation)
- Internal APIs (mTLS for service-to-service)

## Security Testing

### Penetration Testing

**Scope**:
- OWASP Top 10 vulnerabilities
- Multi-tenant isolation
- Authentication/authorization bypasses
- Input validation
- API abuse

**Tools**:
- OWASP ZAP (automated scanning)
- Burp Suite (manual testing)
- Nuclei (vulnerability scanning)

### Security Scanning

**Static Analysis**:
- Snyk (dependency vulnerability scanning)
- SonarQube (code quality and security issues)
- Trivy (container image scanning)

**Dynamic Analysis**:
- Runtime security monitoring (Falco)
- Network policy validation

## Compliance

### GDPR Compliance

**Requirements**:
- [ ] Consent management for data collection
- [ ] Right to access (data export)
- [ ] Right to erasure (data deletion)
- [ ] Data portability
- [ ] Privacy by design

**Implementation**:
- Event sourcing supports complete data history
- Soft delete with anonymization for "right to be forgotten"
- Export API for data portability

### PCI-DSS Compliance

**Scope Minimization**:
- No cardholder data stored
- Payment processing via third-party (Stripe/Square)
- Only store tokenized payment methods

### SOC2 Compliance

**Requirements**:
- [ ] Access controls (authentication, authorization)
- [ ] Audit logging (comprehensive, immutable)
- [ ] Data encryption (at rest, in transit)
- [ ] Monitoring and alerting
- [ ] Incident response plan

## Incident Response

### Security Incident Procedures

1. **Detect**: Monitoring alerts, user reports
2. **Contain**: Isolate affected systems, revoke compromised credentials
3. **Investigate**: Review audit logs, trace attack vector
4. **Remediate**: Apply fixes, rotate secrets, patch vulnerabilities
5. **Recover**: Restore services, verify integrity
6. **Post-Mortem**: Document incident, improve defenses

### Incident Contacts

- **Security Team**: security@{domain}
- **On-Call Engineer**: PagerDuty escalation
- **Legal/Compliance**: compliance@{domain}

## Related Documentation

- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Architecture security details
- [API-SPECIFICATION.md](./API-SPECIFICATION.md) - API security (auth, rate limiting)
- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) - Security operations

## Revision History

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial security requirements | {Name} |
