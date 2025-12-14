# Error Handling Standards

**Status**: Active Standard  
**Version**: 1.0.0  
**Date**: December 14, 2025  
**Authority**: TJMPaaS Technical Standards  
**Applies To**: All TJMPaaS services

---

## Executive Summary

This standard defines error handling patterns, response formats, logging practices, and observability requirements across all TJMPaaS services. It establishes **consistent, actionable error responses** that support debugging, security, multi-tenant isolation, and excellent developer experience.

**Key Decisions**:
- **Error Format**: RFC 7807 Problem Details for HTTP APIs
- **Error Taxonomy**: System errors (500s) vs Business errors (400s)
- **Multi-Tenant**: `tenant_id` included in errors, cross-tenant leak prevention
- **Actor Errors**: Supervision strategies aligned with error severity
- **Observability**: Structured logging, metrics, distributed tracing
- **Security**: No sensitive data in error responses, rate limiting on errors

---

## Table of Contents

1. [Context and Rationale](#context-and-rationale)
2. [Error Response Format (RFC 7807)](#error-response-format-rfc-7807)
3. [Error Taxonomy and Categories](#error-taxonomy-and-categories)
4. [HTTP Status Code Mapping](#http-status-code-mapping)
5. [Multi-Tenant Error Handling](#multi-tenant-error-handling)
6. [Actor Error Handling Patterns](#actor-error-handling-patterns)
7. [Circuit Breaker Error Responses](#circuit-breaker-error-responses)
8. [Error Logging Standards](#error-logging-standards)
9. [Error Metrics and Observability](#error-metrics-and-observability)
10. [Error Translation Patterns](#error-translation-patterns)
11. [Security Considerations](#security-considerations)
12. [Implementation Patterns (Scala)](#implementation-patterns-scala)
13. [Integration Examples](#integration-examples)
14. [References](#references)

---

## Context and Rationale

### Problem Statement

TJMPaaS services require **consistent, informative error handling** that:
- Helps developers quickly diagnose and fix issues
- Protects sensitive data and maintains security
- Maintains multi-tenant isolation in error responses
- Provides actionable information without exposing internals
- Supports observability and debugging
- Follows industry standards for API error responses

### Goals

1. **Consistency**: All services use same error format and conventions
2. **Actionability**: Errors provide enough context to take corrective action
3. **Security**: No sensitive data leaked, tenant isolation maintained
4. **Observability**: Errors correlated across logs, metrics, traces
5. **Developer Experience**: Clear, well-documented, predictable errors

### Constraints

- Must support multi-tenant SaaS architecture
- Must integrate with actor model (Pekko/Akka supervision)
- Must align with reactive principles (resilience, responsiveness)
- Must work with HTTP APIs (REST) and event-driven integration
- Must support distributed tracing and logging

---

## Error Response Format (RFC 7807)

### Standard: RFC 7807 Problem Details

TJMPaaS adopts **RFC 7807 Problem Details for HTTP APIs** as the standard error response format.

**Why RFC 7807?**
- Industry standard, widely adopted (Google, GitHub, Stripe use similar patterns)
- Machine-readable (consistent structure)
- Human-readable (clear descriptions)
- Extensible (custom fields allowed)
- Framework support (Akka HTTP, http4s have helpers)

### Base Schema

```json
{
  "type": "https://api.tjmpaas.com/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "Invalid tenant_id format: must be UUID",
  "instance": "/api/v1/tenants/invalid-123",
  "timestamp": "2025-12-14T10:30:00Z",
  "request_id": "req-a1b2c3d4",
  "tenant_id": "tenant-abc-123",
  "errors": [
    {
      "field": "tenant_id",
      "message": "Must be valid UUID format",
      "code": "INVALID_FORMAT"
    }
  ]
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `type` | URI | Identifier for error type (URL to error documentation) |
| `title` | String | Short, human-readable summary (constant per error type) |
| `status` | Integer | HTTP status code (matches response status) |
| `detail` | String | Human-readable explanation specific to this occurrence |
| `instance` | URI | URI reference to specific occurrence (request path) |
| `timestamp` | ISO 8601 | When error occurred (UTC) |
| `request_id` | String | Correlation ID for request (for tracing/logging) |

### Multi-Tenant Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tenant_id` | String | **Yes** | Tenant context for error (enables tenant-scoped debugging) |
| `organization_id` | String | If applicable | Organization context (for hierarchical tenants) |
| `user_id` | String | If authenticated | User who encountered error (for user-scoped debugging) |

**Security Note**: Only include `tenant_id` if request was authenticated and tenant validated. Never include another tenant's ID.

### Optional Extension Fields

Common extensions used across TJMPaaS services:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `errors` | Array | Field-level validation errors | See validation example |
| `trace_id` | String | Distributed trace ID | For correlation across services |
| `code` | String | Machine-readable error code | `TENANT_NOT_FOUND`, `INSUFFICIENT_PERMISSIONS` |
| `retry_after` | Integer | Seconds to wait before retry (for rate limits) | `60` |
| `help_url` | URI | Link to documentation/troubleshooting | `https://docs.tjmpaas.com/errors/...` |

---

## Error Taxonomy and Categories

### Error Categories

TJMPaaS classifies errors into two primary categories:

#### 1. System Errors (5xx) - Infrastructure/Platform Failures

**Definition**: Errors caused by system issues, not client mistakes. Client cannot fix by changing request.

**Characteristics**:
- HTTP status codes: 500-599
- Indicates service failure, not request failure
- May be transient (retryable) or permanent
- Logged at ERROR or CRITICAL level
- Trigger alerts and incident response

**Examples**:
- Database connection failure
- Out of memory
- Actor system failure
- Downstream service unavailable
- Internal logic error (unexpected exception)

**Client Expectation**: Retry with exponential backoff, report to support if persistent

#### 2. Business/Client Errors (4xx) - Request Validation Failures

**Definition**: Errors caused by invalid requests. Client must fix request to succeed.

**Characteristics**:
- HTTP status codes: 400-499
- Indicates client error, not service failure
- Not transient (retrying without changes will fail)
- Logged at WARN or INFO level
- Do NOT trigger alerts (expected behavior)

**Examples**:
- Invalid input format
- Missing required field
- Authentication failure
- Authorization failure (insufficient permissions)
- Resource not found
- Conflict (duplicate resource, version mismatch)

**Client Expectation**: Fix request based on error details, do not retry without changes

### Detailed Error Codes

#### System Error Codes (5xx)

| Code | HTTP Status | Title | Retryable | Example |
|------|-------------|-------|-----------|---------|
| `INTERNAL_ERROR` | 500 | Internal Server Error | Maybe | Unhandled exception |
| `SERVICE_UNAVAILABLE` | 503 | Service Unavailable | Yes | Service starting up, overloaded |
| `DATABASE_ERROR` | 500 | Database Error | Maybe | Connection timeout, deadlock |
| `DOWNSTREAM_ERROR` | 502 | Downstream Service Error | Yes | Dependency failed |
| `TIMEOUT_ERROR` | 504 | Gateway Timeout | Yes | Operation exceeded deadline |
| `CIRCUIT_OPEN` | 503 | Circuit Breaker Open | Yes | Circuit breaker protecting downstream |

#### Business Error Codes (4xx)

| Code | HTTP Status | Title | Retryable | Example |
|------|-------------|-------|-----------|---------|
| `VALIDATION_ERROR` | 400 | Validation Error | No | Invalid field format |
| `AUTHENTICATION_REQUIRED` | 401 | Authentication Required | No | Missing/invalid JWT |
| `AUTHENTICATION_FAILED` | 401 | Authentication Failed | No | Invalid credentials |
| `AUTHORIZATION_FAILED` | 403 | Forbidden | No | Insufficient permissions |
| `RESOURCE_NOT_FOUND` | 404 | Not Found | No | Entity doesn't exist |
| `CONFLICT` | 409 | Conflict | Maybe | Duplicate resource, optimistic lock |
| `PRECONDITION_FAILED` | 412 | Precondition Failed | No | If-Match header failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too Many Requests | Yes | Rate limit hit |
| `TENANT_NOT_FOUND` | 404 | Tenant Not Found | No | Invalid tenant_id |
| `TENANT_MISMATCH` | 403 | Tenant Mismatch | No | X-Tenant-ID doesn't match JWT |
| `TENANT_SUSPENDED` | 403 | Tenant Suspended | No | Tenant account suspended |

---

## HTTP Status Code Mapping

### Standard Mappings

| Status | Name | When to Use | Retryable |
|--------|------|-------------|-----------|
| **200** | OK | Successful GET, PUT, PATCH | - |
| **201** | Created | Successful POST (resource created) | - |
| **202** | Accepted | Request accepted for async processing | - |
| **204** | No Content | Successful DELETE | - |
| **400** | Bad Request | Invalid input, validation failure | No |
| **401** | Unauthorized | Authentication required or failed | No |
| **403** | Forbidden | Authenticated but insufficient permissions | No |
| **404** | Not Found | Resource doesn't exist | No |
| **409** | Conflict | Resource conflict (duplicate, version mismatch) | Maybe |
| **412** | Precondition Failed | If-Match, If-None-Match failed | No |
| **422** | Unprocessable Entity | Semantic validation failure | No |
| **429** | Too Many Requests | Rate limit exceeded | Yes (after delay) |
| **500** | Internal Server Error | Unhandled exception, unexpected error | Maybe |
| **502** | Bad Gateway | Downstream service returned invalid response | Yes |
| **503** | Service Unavailable | Service overloaded, starting, circuit open | Yes |
| **504** | Gateway Timeout | Operation timed out | Yes |

### Multi-Tenant Specific Status Codes

| Status | Code | Title | When to Use |
|--------|------|-------|-------------|
| **404** | `TENANT_NOT_FOUND` | Tenant Not Found | tenant_id in path/header doesn't exist |
| **403** | `TENANT_MISMATCH` | Tenant Mismatch | X-Tenant-ID doesn't match JWT tenant_id |
| **403** | `TENANT_SUSPENDED` | Tenant Suspended | Tenant account suspended/disabled |
| **403** | `TENANT_EXPIRED` | Tenant Subscription Expired | Tenant subscription expired |
| **403** | `CROSS_TENANT_ACCESS` | Cross-Tenant Access Denied | Attempted access to another tenant's resource |

---

## Multi-Tenant Error Handling

### Mandatory Requirements

1. **Always include `tenant_id` in error responses** (if request authenticated)
2. **Never leak information about other tenants** (404 instead of 403 if tenant mismatch)
3. **Validate tenant context before processing** (X-Tenant-ID vs JWT tenant_id)
4. **Tenant-scoped error logging** (tenant_id in every log entry)
5. **Tenant isolation in error details** (no cross-tenant resource IDs)

### Cross-Tenant Leak Prevention

**Problem**: Error responses can leak information about other tenants' data.

**Bad Example** (leaks information):
```json
{
  "type": "https://api.tjmpaas.com/errors/forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "User user-123 does not have permission to access organization org-456 owned by tenant tenant-xyz",
  "tenant_id": "tenant-abc"
}
```

**Why bad**: Reveals that `org-456` exists and is owned by `tenant-xyz` (different tenant).

**Good Example** (prevents leak):
```json
{
  "type": "https://api.tjmpaas.com/errors/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "Organization not found",
  "tenant_id": "tenant-abc"
}
```

**Why good**: Returns 404 instead of 403 when resource exists but belongs to another tenant. No information leaked.

### Tenant Validation Flow

```scala
// 1. Extract X-Tenant-ID header
val headerTenantId = request.header("X-Tenant-ID").getOrElse(
  return BadRequest(ProblemDetails(
    type = "https://api.tjmpaas.com/errors/missing-tenant-header",
    title = "Missing Tenant Header",
    status = 400,
    detail = "X-Tenant-ID header is required"
  ))
)

// 2. Extract tenant_id from JWT
val jwtTenantId = jwt.getClaim("tenant_id").asString()

// 3. Validate match
if (headerTenantId != jwtTenantId) {
  return Forbidden(ProblemDetails(
    type = "https://api.tjmpaas.com/errors/tenant-mismatch",
    title = "Tenant Mismatch",
    status = 403,
    detail = s"X-Tenant-ID header ($headerTenantId) does not match authenticated tenant",
    tenantId = Some(jwtTenantId) // Use JWT tenant_id (authenticated context)
  ))
}

// 4. Validate tenant exists and active
tenantService.getTenant(jwtTenantId) match {
  case None =>
    return NotFound(ProblemDetails(
      type = "https://api.tjmpaas.com/errors/tenant-not-found",
      title = "Tenant Not Found",
      status = 404,
      detail = s"Tenant $jwtTenantId does not exist"
    ))
  case Some(tenant) if tenant.status != Active =>
    return Forbidden(ProblemDetails(
      type = "https://api.tjmpaas.com/errors/tenant-suspended",
      title = "Tenant Suspended",
      status = 403,
      detail = s"Tenant $jwtTenantId is ${tenant.status}"
    ))
  case Some(tenant) =>
    // Proceed with request
}
```

### Tenant-Scoped Resource Errors

When resource not found, always check tenant ownership **before** returning error:

```scala
organizationService.getOrganization(orgId, tenantId) match {
  case None =>
    // Don't reveal whether org exists in another tenant - always 404
    NotFound(ProblemDetails(
      type = "https://api.tjmpaas.com/errors/organization-not-found",
      title = "Organization Not Found",
      status = 404,
      detail = s"Organization $orgId not found",
      tenantId = Some(tenantId)
    ))
  case Some(org) =>
    // Process request
}
```

**Never** do this:
```scala
// BAD: Checks existence first, reveals cross-tenant info
if (organizationService.exists(orgId)) {
  if (organizationService.getTenant(orgId) != tenantId) {
    return Forbidden(...) // LEAKS: org exists but belongs to another tenant
  }
}
```

---

## Actor Error Handling Patterns

### Actor Supervision Strategies

TJMPaaS services use the Actor Model (Pekko/Akka) for stateful entities. Actor failures must be handled according to error severity.

### Supervision Strategy by Error Type

| Error Type | Strategy | Reason | Example |
|------------|----------|--------|---------|
| **Transient (Recoverable)** | **Restart** | Error is temporary, retry likely succeeds | Network timeout, database deadlock |
| **Persistent (Unrecoverable)** | **Stop** | Error will persist, retrying won't help | Invalid configuration, corrupted state |
| **Critical (System-Wide)** | **Escalate** | Error affects multiple actors, parent decides | Out of memory, actor system issue |
| **Expected (Business Logic)** | **Resume** | Not an error, normal business flow | Validation failure, permission denied |

### Supervision Configuration

```scala
import org.apache.pekko.actor.typed.SupervisorStrategy
import org.apache.pekko.actor.typed.scaladsl.Behaviors
import scala.concurrent.duration._

object TenantActor {
  def apply(tenantId: TenantId): Behavior[Command] =
    Behaviors.supervise {
      Behaviors.setup { context =>
        // Actor logic here
      }
    }.onFailure[DatabaseException](
      SupervisorStrategy.restart
        .withLimit(maxNrOfRetries = 3, withinTimeRange = 1.minute)
        .withLoggingEnabled(true)
    ).onFailure[ValidationException](
      SupervisorStrategy.resume // Don't restart for business errors
    ).onFailure[ConfigurationException](
      SupervisorStrategy.stop // Can't recover from bad config
    )
}
```

### Actor Error Messages

Actors should respond with error messages (not throw exceptions for business errors):

```scala
sealed trait TenantCommand
final case class CreateOrganization(
  name: String,
  replyTo: ActorRef[OrganizationResponse]
) extends TenantCommand

sealed trait OrganizationResponse
final case class OrganizationCreated(org: Organization) extends OrganizationResponse
final case class OrganizationError(error: ErrorDetails) extends OrganizationResponse

// In actor behavior
case CreateOrganization(name, replyTo) =>
  if (name.isEmpty) {
    // Business error - reply with error message, don't throw
    replyTo ! OrganizationError(ErrorDetails(
      code = "INVALID_NAME",
      message = "Organization name cannot be empty"
    ))
    Behaviors.same
  } else {
    // Happy path
    val org = Organization(name = name)
    replyTo ! OrganizationCreated(org)
    Behaviors.same
  }
```

### Actor Failure Logging

```scala
.onFailure[Exception](
  SupervisorStrategy.restart.withLoggingEnabled(true)
)

// Logs:
// ERROR TenantActor - Exception in actor [Actor[akka://system/user/tenant-123#1234567890]]:
//   DatabaseException: Connection timeout
//   Restarting actor after failure
```

---

## Circuit Breaker Error Responses

### Circuit Breaker States and Errors

When circuit breaker is **Open** (protecting downstream service), return 503 with retry guidance:

```json
{
  "type": "https://api.tjmpaas.com/errors/circuit-open",
  "title": "Service Temporarily Unavailable",
  "status": 503,
  "detail": "Downstream service is experiencing issues. Circuit breaker is open.",
  "retry_after": 30,
  "instance": "/api/v1/orders/123",
  "timestamp": "2025-12-14T10:30:00Z",
  "request_id": "req-a1b2c3d4",
  "tenant_id": "tenant-abc-123"
}
```

**Key Points**:
- Status: 503 (Service Unavailable, retryable)
- Include `retry_after` (seconds to wait)
- Don't expose downstream service details
- Log circuit breaker state changes

### Circuit Breaker Configuration

```scala
import org.apache.pekko.pattern.CircuitBreaker
import scala.concurrent.duration._

val breaker = new CircuitBreaker(
  scheduler = system.scheduler,
  maxFailures = 5,
  callTimeout = 10.seconds,
  resetTimeout = 30.seconds
)

breaker.onOpen {
  logger.warn("Circuit breaker opened - downstream service unavailable")
}

breaker.onHalfOpen {
  logger.info("Circuit breaker half-open - testing downstream service")
}

breaker.onClose {
  logger.info("Circuit breaker closed - downstream service recovered")
}
```

### Fallback Responses

When circuit is open, provide fallback if possible:

```json
{
  "type": "https://api.tjmpaas.com/errors/degraded-service",
  "title": "Degraded Service",
  "status": 200,
  "detail": "Using cached data due to downstream unavailability",
  "data": {
    "product": {
      "id": "prod-123",
      "name": "Widget",
      "price": 19.99,
      "cached_at": "2025-12-14T10:25:00Z"
    }
  },
  "warnings": [
    "Data may be stale. Last updated 5 minutes ago."
  ]
}
```

---

## Error Logging Standards

### Structured Logging Format

All errors must be logged with structured fields for observability:

```scala
import org.slf4j.MDC

// Set context (per request)
MDC.put("request_id", requestId)
MDC.put("tenant_id", tenantId)
MDC.put("user_id", userId)
MDC.put("trace_id", traceId)

// Log error with structured fields
logger.error(
  "Failed to create organization",
  Map(
    "error_code" -> "DATABASE_ERROR",
    "error_type" -> "system",
    "organization_name" -> orgName,
    "tenant_id" -> tenantId,
    "retry_count" -> retryCount,
    "duration_ms" -> durationMs
  ),
  exception
)

// Clear context (after request)
MDC.clear()
```

### Log Levels by Error Category

| Error Category | Log Level | Example |
|---------------|-----------|---------|
| **System Error (5xx)** | **ERROR** or **CRITICAL** | Database failure, unhandled exception |
| **Business Error (4xx)** | **WARN** or **INFO** | Validation failure, permission denied |
| **Circuit Breaker Open** | **WARN** | Protecting downstream service |
| **Rate Limit Exceeded** | **INFO** | Expected behavior, not an error |

### Required Log Fields

| Field | Required | Description |
|-------|----------|-------------|
| `timestamp` | Yes | ISO 8601 timestamp |
| `level` | Yes | ERROR, WARN, INFO |
| `message` | Yes | Human-readable error message |
| `error_code` | Yes | Machine-readable code |
| `error_type` | Yes | system or business |
| `request_id` | Yes | Correlation ID |
| `tenant_id` | If authenticated | Tenant context |
| `user_id` | If authenticated | User context |
| `trace_id` | If tracing enabled | Distributed trace ID |
| `service` | Yes | Service name |
| `exception` | If exception | Stack trace |
| `duration_ms` | If applicable | Request duration |

### Log Sampling for High-Volume Errors

For high-volume expected errors (rate limits, validation), sample logs:

```scala
val rateLimitSampler = new LogSampler(sampleRate = 0.01) // Log 1% of rate limit errors

if (rateLimited) {
  rateLimitSampler.sample {
    logger.info(s"Rate limit exceeded for tenant $tenantId")
  }
  return TooManyRequests(...)
}
```

---

## Error Metrics and Observability

### Required Error Metrics

All services must expose these error metrics (Prometheus format):

#### 1. Error Rate by Type

```
tjmpaas_errors_total{service="entity-management",error_type="system",error_code="DATABASE_ERROR",tenant_id="tenant-123"} 42
tjmpaas_errors_total{service="entity-management",error_type="business",error_code="VALIDATION_ERROR",tenant_id="tenant-123"} 156
```

#### 2. Error Rate by HTTP Status

```
tjmpaas_http_errors_total{service="entity-management",status="500",tenant_id="tenant-123"} 5
tjmpaas_http_errors_total{service="entity-management",status="400",tenant_id="tenant-123"} 23
```

#### 3. Circuit Breaker State

```
tjmpaas_circuit_breaker_state{service="entity-management",name="user-service-breaker"} 1  # 0=closed, 1=open, 2=half-open
tjmpaas_circuit_breaker_failures{service="entity-management",name="user-service-breaker"} 12
```

#### 4. Actor Restart Count

```
tjmpaas_actor_restarts_total{service="entity-management",actor_type="TenantActor",tenant_id="tenant-123"} 3
```

### Alert Conditions

| Metric | Condition | Severity | Action |
|--------|-----------|----------|--------|
| Error rate > 5% | 5xx errors / total requests > 0.05 | **CRITICAL** | Page on-call |
| Error rate > 10% | 5xx errors / total requests > 0.10 | **EMERGENCY** | Escalate immediately |
| Circuit breaker open | State = 1 for > 2 minutes | **WARNING** | Investigate downstream |
| Actor restart spike | Restarts > 10/min | **WARNING** | Check actor logs |
| Database errors | > 5/min | **CRITICAL** | Check database health |

### Distributed Tracing

All errors must be traced across service boundaries:

```scala
import io.opentelemetry.api.trace.{Span, StatusCode}

val span = tracer.spanBuilder("create-organization").startSpan()
try {
  // Operation
} catch {
  case ex: Exception =>
    span.recordException(ex)
    span.setStatus(StatusCode.ERROR, "Failed to create organization")
    throw ex
} finally {
  span.end()
}
```

---

## Error Translation Patterns

### Domain Errors to HTTP Responses

Services define domain-specific error ADTs, then translate to HTTP responses:

```scala
// Domain errors (in domain layer)
sealed trait OrganizationError
case class OrganizationNotFound(orgId: OrganizationId) extends OrganizationError
case class InvalidOrganizationName(name: String, reason: String) extends OrganizationError
case class DuplicateOrganization(name: String) extends OrganizationError
case class DatabaseError(cause: Throwable) extends OrganizationError

// Translation to HTTP (in API layer)
def toHttpResponse(error: OrganizationError, tenantId: TenantId): HttpResponse = error match {
  case OrganizationNotFound(orgId) =>
    NotFound(ProblemDetails(
      type = "https://api.tjmpaas.com/errors/organization-not-found",
      title = "Organization Not Found",
      status = 404,
      detail = s"Organization $orgId not found",
      tenantId = Some(tenantId)
    ))
    
  case InvalidOrganizationName(name, reason) =>
    BadRequest(ProblemDetails(
      type = "https://api.tjmpaas.com/errors/validation-error",
      title = "Validation Error",
      status = 400,
      detail = s"Invalid organization name: $reason",
      tenantId = Some(tenantId),
      errors = Some(Seq(
        FieldError("name", reason, "INVALID_FORMAT")
      ))
    ))
    
  case DuplicateOrganization(name) =>
    Conflict(ProblemDetails(
      type = "https://api.tjmpaas.com/errors/duplicate-organization",
      title = "Duplicate Organization",
      status = 409,
      detail = s"Organization with name '$name' already exists",
      tenantId = Some(tenantId)
    ))
    
  case DatabaseError(cause) =>
    InternalServerError(ProblemDetails(
      type = "https://api.tjmpaas.com/errors/internal-error",
      title = "Internal Server Error",
      status = 500,
      detail = "An internal error occurred. Please try again later.",
      tenantId = Some(tenantId)
      // Don't expose cause to client
    ))
}
```

### Actor Error Messages to HTTP Responses

```scala
// Actor response types
sealed trait OrganizationResponse
case class OrganizationCreated(org: Organization) extends OrganizationResponse
case class OrganizationFailed(error: OrganizationError) extends OrganizationResponse

// HTTP endpoint
def createOrganization(req: CreateOrganizationRequest): Future[HttpResponse] = {
  val tenantActor: ActorRef[TenantCommand] = getTenantActor(req.tenantId)
  
  (tenantActor ? CreateOrganization(req.name, _))
    .map {
      case OrganizationCreated(org) =>
        Created(org, headers = Location(s"/api/v1/organizations/${org.id}"))
        
      case OrganizationFailed(error) =>
        toHttpResponse(error, req.tenantId)
    }
    .recover {
      case _: AskTimeoutException =>
        RequestTimeout(ProblemDetails(
          type = "https://api.tjmpaas.com/errors/timeout",
          title = "Request Timeout",
          status = 408,
          detail = "Organization creation timed out",
          tenantId = Some(req.tenantId)
        ))
    }
}
```

---

## Security Considerations

### 1. No Sensitive Data in Error Responses

**Never** include in error responses:
- Database connection strings
- Internal service URLs
- Stack traces (in production)
- User passwords or tokens
- Encryption keys
- Internal error codes that reveal implementation

**Safe to include**:
- High-level error categories
- Validation failures on user input
- Resource IDs (if user authorized)
- Generic error messages

### 2. Rate Limiting on Errors

Prevent error-based enumeration attacks:

```scala
// Rate limit authentication failures
val authRateLimiter = RateLimiter(
  maxAttempts = 5,
  window = 15.minutes,
  keyBy = (req => req.clientIP) // or username
)

if (!authRateLimiter.allow(req.clientIP)) {
  return TooManyRequests(ProblemDetails(
    type = "https://api.tjmpaas.com/errors/rate-limit",
    title = "Too Many Requests",
    status = 429,
    detail = "Too many authentication attempts. Try again later.",
    retryAfter = Some(authRateLimiter.retryAfter(req.clientIP))
  ))
}
```

### 3. Timing Attack Prevention

Don't reveal resource existence through timing differences:

```scala
// BAD: Timing reveals if user exists
if (userExists(username)) {
  if (checkPassword(username, password)) {
    // Login successful
  } else {
    // Wrong password (slow operation)
  }
} else {
  // User doesn't exist (fast operation)
}

// GOOD: Constant time regardless of user existence
val passwordHash = getUserPasswordHash(username).getOrElse(dummyHash)
val valid = checkPassword(passwordHash, password)
if (valid && userExists(username)) {
  // Login successful
} else {
  // Invalid credentials (same timing)
}
```

### 4. Error Correlation Without Leaking Info

Use `request_id` for correlation instead of exposing internal details:

```json
{
  "type": "https://api.tjmpaas.com/errors/internal-error",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "An unexpected error occurred. Please contact support with request ID: req-a1b2c3d4",
  "request_id": "req-a1b2c3d4"
}
```

Support team can look up `request_id` in logs to see full stack trace and details.

---

## Implementation Patterns (Scala)

### 1. Problem Details Case Class

```scala
import java.time.Instant
import io.circe.{Encoder, Json}
import io.circe.syntax._

case class ProblemDetails(
  `type`: String,
  title: String,
  status: Int,
  detail: String,
  instance: Option[String] = None,
  timestamp: Instant = Instant.now(),
  requestId: Option[String] = None,
  tenantId: Option[String] = None,
  organizationId: Option[String] = None,
  userId: Option[String] = None,
  traceId: Option[String] = None,
  errors: Option[Seq[FieldError]] = None,
  code: Option[String] = None,
  retryAfter: Option[Int] = None,
  helpUrl: Option[String] = None
)

case class FieldError(
  field: String,
  message: String,
  code: String
)

object ProblemDetails {
  implicit val encoder: Encoder[ProblemDetails] = (pd: ProblemDetails) => Json.obj(
    "type" -> pd.`type`.asJson,
    "title" -> pd.title.asJson,
    "status" -> pd.status.asJson,
    "detail" -> pd.detail.asJson,
    "instance" -> pd.instance.asJson,
    "timestamp" -> pd.timestamp.toString.asJson,
    "request_id" -> pd.requestId.asJson,
    "tenant_id" -> pd.tenantId.asJson,
    "organization_id" -> pd.organizationId.asJson,
    "user_id" -> pd.userId.asJson,
    "trace_id" -> pd.traceId.asJson,
    "errors" -> pd.errors.asJson,
    "code" -> pd.code.asJson,
    "retry_after" -> pd.retryAfter.asJson,
    "help_url" -> pd.helpUrl.asJson
  ).dropNullValues
}
```

### 2. Akka HTTP Error Handler

```scala
import akka.http.scaladsl.server.Directives._
import akka.http.scaladsl.server.ExceptionHandler
import akka.http.scaladsl.model.StatusCodes._
import de.heikoseeberger.akkahttpcirce.FailFastCirceSupport._

implicit def exceptionHandler(implicit ctx: RequestContext): ExceptionHandler =
  ExceptionHandler {
    case ex: ValidationException =>
      complete(
        BadRequest,
        ProblemDetails(
          `type` = "https://api.tjmpaas.com/errors/validation-error",
          title = "Validation Error",
          status = 400,
          detail = ex.getMessage,
          requestId = Some(ctx.requestId),
          tenantId = Some(ctx.tenantId)
        )
      )
      
    case ex: AuthorizationException =>
      complete(
        Forbidden,
        ProblemDetails(
          `type` = "https://api.tjmpaas.com/errors/forbidden",
          title = "Forbidden",
          status = 403,
          detail = ex.getMessage,
          requestId = Some(ctx.requestId),
          tenantId = Some(ctx.tenantId)
        )
      )
      
    case ex: NotFoundException =>
      complete(
        NotFound,
        ProblemDetails(
          `type` = "https://api.tjmpaas.com/errors/not-found",
          title = "Not Found",
          status = 404,
          detail = ex.getMessage,
          requestId = Some(ctx.requestId),
          tenantId = Some(ctx.tenantId)
        )
      )
      
    case ex: Exception =>
      logger.error(s"Unhandled exception for request ${ctx.requestId}", ex)
      complete(
        InternalServerError,
        ProblemDetails(
          `type` = "https://api.tjmpaas.com/errors/internal-error",
          title = "Internal Server Error",
          status = 500,
          detail = "An unexpected error occurred. Please contact support.",
          requestId = Some(ctx.requestId),
          tenantId = Some(ctx.tenantId)
        )
      )
  }
```

### 3. Request Context Extraction

```scala
case class RequestContext(
  requestId: String,
  tenantId: String,
  userId: Option[String],
  traceId: Option[String]
)

def extractRequestContext: Directive1[RequestContext] =
  (extractRequestId & extractTenantId & extractUserId & extractTraceId).tmap {
    case (requestId, tenantId, userId, traceId) =>
      RequestContext(requestId, tenantId, userId, traceId)
  }

def extractRequestId: Directive1[String] =
  optionalHeaderValueByName("X-Request-ID").map(_.getOrElse(UUID.randomUUID().toString))

def extractTenantId: Directive1[String] =
  headerValueByName("X-Tenant-ID")

def extractUserId: Directive1[Option[String]] =
  optionalHeaderValueByName("X-User-ID")

def extractTraceId: Directive1[Option[String]] =
  optionalHeaderValueByName("X-Trace-ID")
```

---

## Integration Examples

### Complete API Endpoint with Error Handling

```scala
import akka.http.scaladsl.server.Directives._
import akka.http.scaladsl.server.Route

def routes(implicit ctx: RequestContext): Route =
  pathPrefix("api" / "v1" / "organizations") {
    post {
      entity(as[CreateOrganizationRequest]) { req =>
        onSuccess(createOrganization(req, ctx)) {
          case Right(org) =>
            complete(StatusCodes.Created, org)
            
          case Left(error) =>
            complete(toHttpResponse(error, ctx.tenantId))
        }
      }
    } ~
    get {
      path(JavaUUID) { orgId =>
        onSuccess(getOrganization(orgId, ctx.tenantId)) {
          case Some(org) =>
            complete(org)
            
          case None =>
            complete(
              StatusCodes.NotFound,
              ProblemDetails(
                `type` = "https://api.tjmpaas.com/errors/organization-not-found",
                title = "Organization Not Found",
                status = 404,
                detail = s"Organization $orgId not found",
                requestId = Some(ctx.requestId),
                tenantId = Some(ctx.tenantId)
              )
            )
        }
      }
    }
  }
```

### Actor Error Handling Example

```scala
import org.apache.pekko.actor.typed.scaladsl.Behaviors
import org.apache.pekko.actor.typed.{ActorRef, Behavior}

object OrganizationActor {
  sealed trait Command
  final case class CreateOrganization(
    name: String,
    parentId: Option[OrganizationId],
    replyTo: ActorRef[Response]
  ) extends Command
  
  sealed trait Response
  final case class OrganizationCreated(org: Organization) extends Response
  final case class OrganizationError(details: ProblemDetails) extends Response
  
  def apply(tenantId: TenantId): Behavior[Command] =
    Behaviors.setup { context =>
      Behaviors.receiveMessage {
        case CreateOrganization(name, parentId, replyTo) =>
          // Validate name
          if (name.trim.isEmpty) {
            replyTo ! OrganizationError(ProblemDetails(
              `type` = "https://api.tjmpaas.com/errors/validation-error",
              title = "Validation Error",
              status = 400,
              detail = "Organization name cannot be empty",
              tenantId = Some(tenantId),
              errors = Some(Seq(FieldError("name", "Name cannot be empty", "REQUIRED")))
            ))
            return Behaviors.same
          }
          
          // Validate parent exists (if specified)
          parentId.foreach { pid =>
            if (!organizationExists(pid, tenantId)) {
              replyTo ! OrganizationError(ProblemDetails(
                `type` = "https://api.tjmpaas.com/errors/parent-not-found",
                title = "Parent Organization Not Found",
                status = 404,
                detail = s"Parent organization $pid not found",
                tenantId = Some(tenantId)
              ))
              return Behaviors.same
            }
          }
          
          // Create organization
          try {
            val org = Organization(
              id = OrganizationId.generate(),
              tenantId = tenantId,
              name = name,
              parentId = parentId
            )
            
            persistOrganization(org)
            replyTo ! OrganizationCreated(org)
            Behaviors.same
            
          } catch {
            case ex: DatabaseException =>
              context.log.error("Database error creating organization", ex)
              replyTo ! OrganizationError(ProblemDetails(
                `type` = "https://api.tjmpaas.com/errors/database-error",
                title = "Database Error",
                status = 500,
                detail = "Failed to create organization. Please try again.",
                tenantId = Some(tenantId)
              ))
              Behaviors.same
          }
      }
    }
}
```

---

## References

### Industry Standards

- **RFC 7807**: Problem Details for HTTP APIs - https://tools.ietf.org/html/rfc7807
- **RFC 7231**: HTTP/1.1 Semantics and Content (Status Codes) - https://tools.ietf.org/html/rfc7231
- **Google API Design Guide**: Error Handling - https://cloud.google.com/apis/design/errors
- **Microsoft REST API Guidelines**: Error Handling - https://github.com/microsoft/api-guidelines/blob/vNext/Guidelines.md#7102-error-condition-responses

### Implementation References

- **Akka HTTP Exception Handling**: https://doc.akka.io/docs/akka-http/current/routing-dsl/exception-handling.html
- **Akka Actor Supervision**: https://doc.akka.io/docs/akka/current/typed/fault-tolerance.html
- **Pekko Actor Supervision**: https://pekko.apache.org/docs/pekko/current/typed/fault-tolerance.html
- **Circuit Breaker Pattern**: https://doc.akka.io/docs/akka/current/common/circuitbreaker.html

### Related TJMPaaS Standards

- [SECURITY-JWT-PERMISSIONS.md](./SECURITY-JWT-PERMISSIONS.md) - JWT authentication errors (401, 403)
- [API-DESIGN-STANDARDS.md](./API-DESIGN-STANDARDS.md) - HTTP API conventions
- [MULTI-TENANT-SEAM-ARCHITECTURE.md](./MULTI-TENANT-SEAM-ARCHITECTURE.md) - Tenant isolation in errors

---

**Version History**:
- **v1.0.0** (2025-12-14): Initial standard defining error handling patterns, RFC 7807 adoption, multi-tenant error handling, actor supervision, circuit breaker errors, logging, metrics, and Scala implementation patterns

**Maintenance**: This standard should be reviewed quarterly and updated as patterns evolve or new error categories emerge.

**Questions/Feedback**: Contact TJM Solutions architecture team
