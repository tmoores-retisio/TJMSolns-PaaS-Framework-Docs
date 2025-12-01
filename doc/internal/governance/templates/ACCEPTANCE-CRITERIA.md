# {Service Name} Acceptance Criteria Template

**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Template Version**: 1.0

---

**Instructions**: Copy this template to feature documentation or PRs. This defines comprehensive "Definition of Done" acceptance criteria for features/services.

---

## Feature Information

**Feature Name**: {Feature Name}  
**Feature ID**: {FEATURE-ID}  
**Service**: {Service Name}  
**Status**: {Draft / In Progress / Complete}  
**Target Release**: {Version}

## Functional Acceptance Criteria

### Core Functionality

**Given-When-Then Format** (reference companion `.feature` file for complete scenarios):

1. **{Acceptance Criterion 1}**
   - **Given**: {Precondition}
   - **When**: {Action}
   - **Then**: {Expected outcome}
   - **Verification**: {How to verify manually or via test}

2. **{Acceptance Criterion 2}**
   - **Given**: {Precondition}
   - **When**: {Action}
   - **Then**: {Expected outcome}
   - **Verification**: {How to verify}

3. **{Acceptance Criterion 3}**
   - **Given**: {Precondition}
   - **When**: {Action}
   - **Then**: {Expected outcome}
   - **Verification**: {How to verify}

### Business Rules Validation

| Rule ID | Description | Test Case | Verification |
|---------|-------------|-----------|--------------|
| {BR-001} | {Business rule} | {Test scenario} | {How verified} |
| {BR-002} | {Business rule} | {Test scenario} | {How verified} |

**Example**:
| Rule ID | Description | Test Case | Verification |
|---------|-------------|-----------|--------------|
| BR-001 | Tenant name must be unique | Create tenant with duplicate name | Should return 409 Conflict |
| BR-002 | Subscription plan must be valid | Create tenant with invalid plan | Should return 422 Unprocessable Entity |

### API Contract Compliance

**REST API Requirements**:
- [ ] All endpoints documented in OpenAPI 3.1 specification
- [ ] X-Tenant-ID header required on all requests (except tenant creation)
- [ ] JWT Authentication required on all authenticated endpoints
- [ ] HATEOAS links included in all responses
- [ ] Pagination implemented for list endpoints (limit/offset)
- [ ] Error responses follow standard format (Error/ValidationError schemas)
- [ ] Rate limiting enforced per tenant SLA tier
- [ ] Idempotency supported for POST requests via Idempotency-Key header

**Command/Query/Event Contract**:
- [ ] All commands include `TenantId` field
- [ ] All queries include tenant filtering
- [ ] All events include `tenant_id` in metadata
- [ ] Event schemas conform to CloudEvents format
- [ ] Commands validated before processing
- [ ] Events published to Kafka after persistence

### User Experience

- [ ] Response times meet SLA (<200ms P95 for queries, <500ms P95 for commands)
- [ ] Error messages are clear and actionable
- [ ] Success confirmations provided
- [ ] Loading states handled appropriately (if UI)

## Non-Functional Acceptance Criteria

### Performance

| Metric | Target | Measurement Method | Verification |
|--------|--------|-------------------|--------------|
| Query Latency (P95) | <100ms | Prometheus histogram | Load test shows P95 <100ms |
| Command Latency (P95) | <500ms | Prometheus histogram | Load test shows P95 <500ms |
| Throughput | >{X} req/sec | Prometheus counter | Load test sustains >{X} req/sec |
| Concurrent Users | >{Y} users | Load test | {Y} concurrent users without degradation |
| Event Processing Lag | <1 second | Kafka consumer lag metric | Consumer lag <1000 messages under load |

**Load Testing**:
- [ ] Load test executed with {N} concurrent users
- [ ] Load test executed for {duration} minutes
- [ ] All performance targets met
- [ ] No memory leaks detected during sustained load
- [ ] No degradation after {duration} of continuous operation

### Scalability

- [ ] Service scales horizontally (tested with 1, 3, 5 replicas)
- [ ] Load distributes evenly across replicas
- [ ] Actor sharding works correctly across replicas
- [ ] No single points of contention identified
- [ ] Database queries remain efficient at scale (query plans reviewed)

### Reliability

- [ ] Circuit breakers configured for all external dependencies
- [ ] Retry logic implemented with exponential backoff
- [ ] Timeouts configured for all external calls
- [ ] Graceful degradation when dependencies unavailable
- [ ] Health checks (liveness/readiness) implemented correctly
- [ ] Service recovers automatically from transient failures

### Security

| Requirement | Verification | Status |
|-------------|--------------|--------|
| Authentication required | Attempt unauthenticated request → 401 | ☐ |
| Authorization enforced | Attempt unauthorized access → 403 | ☐ |
| Tenant isolation enforced | Cross-tenant access attempt → 404/403 | ☐ |
| Input validation | Send invalid data → 422 with details | ☐ |
| SQL injection prevention | Attempt SQL injection → No data leaked | ☐ |
| XSS prevention | Attempt XSS payload → Escaped/rejected | ☐ |
| Sensitive data encrypted at-rest | Check database → Encrypted columns | ☐ |
| Sensitive data encrypted in-transit | Check TLS → All connections use TLS 1.3 | ☐ |
| Audit logging complete | Check logs → All actions logged | ☐ |

**Penetration Testing**:
- [ ] OWASP Top 10 vulnerabilities tested
- [ ] No critical or high severity vulnerabilities found
- [ ] Security scan passed (e.g., Snyk, SonarQube)

### Data Integrity

- [ ] All state changes persisted as events
- [ ] Event sourcing maintains complete audit trail
- [ ] Read models eventually consistent with event store
- [ ] No data loss during failures (events persisted before acknowledgment)
- [ ] Database constraints prevent invalid data
- [ ] Idempotency prevents duplicate operations

## Multi-Tenant Acceptance Criteria

### Tenant Isolation

**Critical Requirements** (all must pass):
- [ ] X-Tenant-ID header required on all requests
- [ ] JWT `tenant_id` claim matches X-Tenant-ID header
- [ ] Database queries filtered by `tenant_id` (verified in query logs)
- [ ] Events include `tenant_id` in metadata
- [ ] Actor sharding by tenant (actors isolated per tenant)
- [ ] No cross-tenant data leakage (isolation tests pass)

**Isolation Test Results**:
```scala
// Test: Tenant A cannot access Tenant B data
describe("Multi-tenant isolation") {
  it("should prevent cross-tenant access") {
    // Create resource in tenant A
    val resourceA = createResource(tenantIdA, data)
    
    // Attempt access from tenant B
    val response = getResource(tenantIdB, resourceA.id)
    
    // Verify 404 or 403 (not 200 with data)
    response.status shouldBe Status.NotFound
  }
}
```

**Isolation Test Coverage**:
- [ ] Cross-tenant GET requests blocked
- [ ] Cross-tenant PUT requests blocked
- [ ] Cross-tenant DELETE requests blocked
- [ ] Cross-tenant event consumption blocked (events filtered by tenant_id)
- [ ] Actor messages reject cross-tenant operations

### Seam Level Compliance

**Seam Levels Affected** (from MULTI-TENANT-SEAM-ARCHITECTURE.md):
- [ ] **Seam 1 (Tenant)**: Tenant-level isolation enforced
- [ ] **Seam 2 (Tenant-Service)**: Service-level entitlements enforced
- [ ] **Seam 3 (Tenant-Service-Feature)**: Feature-level capabilities enforced
- [ ] **Seam 4 (Tenant-Service-Role)**: Role-based permissions enforced

**Seam Validation Tests**:
- [ ] Seam 1: Tenant cannot be created without valid subscription plan
- [ ] Seam 2: Service entitlement checked before allowing service access
- [ ] Seam 3: Feature flag checked before allowing feature usage
- [ ] Seam 4: User role checked before allowing operation

### Rate Limiting by Tenant

| Tier | Rate Limit | Burst | Test Result |
|------|------------|-------|-------------|
| Bronze | 100 req/min | 150 | ☐ Enforced correctly |
| Silver | 1000 req/min | 1500 | ☐ Enforced correctly |
| Gold | 10000 req/min | 15000 | ☐ Enforced correctly |

**Rate Limit Tests**:
- [ ] Bronze tier limited at 100 req/min
- [ ] Silver tier limited at 1000 req/min
- [ ] Gold tier limited at 10000 req/min
- [ ] 429 response returned when rate limit exceeded
- [ ] X-RateLimit-* headers present in all responses

## Testing Acceptance Criteria

### Test Coverage

**Code Coverage Targets**:
- [ ] Unit test coverage: >80%
- [ ] Integration test coverage: >70%
- [ ] E2E test coverage: All critical user flows

**Test Execution**:
- [ ] All unit tests pass (`mill {serviceName}.test`)
- [ ] All integration tests pass (`mill {serviceName}.integration`)
- [ ] All E2E tests pass (`./run-e2e-tests.sh`)
- [ ] Multi-tenant isolation tests pass
- [ ] Load tests pass (performance targets met)

### Test Types

| Test Type | Coverage | Status |
|-----------|----------|--------|
| Unit Tests (Actor behavior) | {N} tests | ☐ Pass |
| Unit Tests (Domain logic) | {N} tests | ☐ Pass |
| Integration Tests (API) | {N} tests | ☐ Pass |
| Integration Tests (Database) | {N} tests | ☐ Pass |
| Integration Tests (Kafka) | {N} tests | ☐ Pass |
| E2E Tests (User flows) | {N} tests | ☐ Pass |
| Multi-Tenant Isolation Tests | {N} tests | ☐ Pass |
| Load Tests | {N} scenarios | ☐ Pass |
| Security Tests | {N} scenarios | ☐ Pass |

### BDD Scenarios (Gherkin)

**Companion `.feature` file**: `features/{feature-name}.feature`

**Scenario Coverage**:
- [ ] All Given-When-Then scenarios documented
- [ ] All scenarios automated (Cucumber/ScalaTest)
- [ ] All scenarios passing

## Documentation Acceptance Criteria

### Service Documentation

- [ ] SERVICE-CHARTER.md created/updated
- [ ] SERVICE-ARCHITECTURE.md updated with feature details
- [ ] API-SPECIFICATION.md updated with new endpoints
- [ ] FEATURE-SPECIFICATION.md created for this feature
- [ ] DEPLOYMENT-RUNBOOK.md updated with new procedures
- [ ] TELEMETRY-SPECIFICATION.md updated with new metrics/logs
- [ ] SECURITY-REQUIREMENTS.md updated with security considerations

### API Documentation

- [ ] OpenAPI 3.1 specification updated
- [ ] All endpoints documented with examples
- [ ] Error responses documented
- [ ] Authentication requirements documented
- [ ] Rate limiting documented

### Code Documentation

- [ ] All public APIs have Scaladoc comments
- [ ] Complex algorithms explained in comments
- [ ] Configuration options documented
- [ ] Environment variables documented in README

### Runbooks

- [ ] Deployment procedure documented
- [ ] Rollback procedure documented
- [ ] Troubleshooting guide updated
- [ ] Monitoring/alerting configured

## Observability Acceptance Criteria

### Metrics

**Required Metrics** (all instrumented):
- [ ] HTTP request counter (`http_requests_total`)
- [ ] HTTP request duration histogram (`http_requests_duration_seconds`)
- [ ] Command counter (`commands_total`)
- [ ] Command duration (`commands_duration_seconds`)
- [ ] Query counter (`queries_total`)
- [ ] Event counter (`events_persisted_total`, `events_published_total`)
- [ ] Actor mailbox gauge (`actors_mailbox_size`)
- [ ] Database connection pool gauge (`db_connection_pool_active`)

**Metrics Validation**:
- [ ] All metrics exposed on `/metrics` endpoint
- [ ] All metrics include `tenant_id` label
- [ ] Prometheus scraping configured
- [ ] Grafana dashboard created/updated

### Logging

**Required Log Events**:
- [ ] Request/response logged (INFO level)
- [ ] Command success/failure logged (INFO/ERROR level)
- [ ] Event persistence logged (INFO level)
- [ ] Event publishing logged (INFO level)
- [ ] Errors logged with stack traces (ERROR level)
- [ ] All logs include `tenant_id`, `trace_id`, `request_id`

**Log Format**:
- [ ] Structured JSON logging
- [ ] All required fields present (timestamp, level, service, tenant_id, message)
- [ ] Log aggregation working (logs visible in Elasticsearch/Kibana)

### Tracing

**Distributed Tracing**:
- [ ] OpenTelemetry instrumentation added
- [ ] Trace context propagated across HTTP requests
- [ ] Trace context propagated across Kafka messages
- [ ] Trace context propagated across actor messages
- [ ] Traces visible in Jaeger/Zipkin
- [ ] Trace sampling configured appropriately

### Alerts

**Required Alerts**:
- [ ] High error rate alert configured
- [ ] High latency alert configured
- [ ] Kafka consumer lag alert configured
- [ ] Multi-tenant isolation violation alert configured
- [ ] All alerts tested (trigger condition verified)

## Deployment Acceptance Criteria

### Deployment Process

- [ ] Container image builds successfully
- [ ] Container image pushed to registry
- [ ] Kubernetes manifests valid (kubectl apply --dry-run)
- [ ] Database migrations execute successfully
- [ ] Service deploys to staging environment
- [ ] Health checks pass after deployment
- [ ] Smoke tests pass in staging
- [ ] Service deploys to production environment
- [ ] Health checks pass in production
- [ ] Smoke tests pass in production

### Rollback Capability

- [ ] Rollback procedure tested in staging
- [ ] Rollback completes in <5 minutes
- [ ] Service fully functional after rollback
- [ ] Database migrations reversible (or forward-compatible)

### Configuration

- [ ] ConfigMaps created
- [ ] Secrets created (credentials, API keys)
- [ ] Environment variables documented
- [ ] Configuration validated

## Code Quality Acceptance Criteria

### Code Review

- [ ] Code reviewed by at least 1 other developer
- [ ] All review comments addressed
- [ ] Code follows project style guide
- [ ] No code smells or anti-patterns identified

### Static Analysis

- [ ] Scalafmt applied (code formatted)
- [ ] Scalafix applied (no linting errors)
- [ ] No compiler warnings
- [ ] SonarQube scan passed (no critical/high issues)
- [ ] Dependency vulnerability scan passed (Snyk/Dependabot)

### Best Practices

- [ ] Immutable data structures used
- [ ] Pure functions preferred
- [ ] Error handling comprehensive (no naked Exceptions)
- [ ] Resource cleanup handled (e.g., connections closed)
- [ ] No hardcoded credentials or secrets

## Compliance Acceptance Criteria

### Regulatory Compliance

- [ ] GDPR compliance (if handling EU personal data)
  - [ ] Consent management implemented
  - [ ] Right to erasure supported
  - [ ] Data portability supported
- [ ] PCI-DSS compliance (if handling payment data)
  - [ ] No cardholder data stored
  - [ ] PCI scope minimized
- [ ] HIPAA compliance (if handling health data)
  - [ ] PHI encrypted at-rest and in-transit
  - [ ] Audit logging comprehensive

### Audit Requirements

- [ ] All state changes logged
- [ ] Audit logs immutable (append-only)
- [ ] Audit logs retained for {N} years
- [ ] Audit logs include user_id, tenant_id, timestamp, action

## Sign-Off

### Feature Acceptance

**Acceptance Checklist Summary**:
- [ ] All functional acceptance criteria met
- [ ] All non-functional acceptance criteria met
- [ ] All multi-tenant acceptance criteria met
- [ ] All testing acceptance criteria met
- [ ] All documentation acceptance criteria met
- [ ] All observability acceptance criteria met
- [ ] All deployment acceptance criteria met
- [ ] All code quality acceptance criteria met
- [ ] All compliance acceptance criteria met

**Sign-Off**:
- **Developer**: {Name} - {Date} - ☐
- **QA**: {Name} - {Date} - ☐
- **Product Owner**: {Name} - {Date} - ☐
- **Security Review**: {Name} - {Date} - ☐ (if required)
- **Compliance Review**: {Name} - {Date} - ☐ (if required)

### Production Readiness

- [ ] Feature flag enabled in staging (validated)
- [ ] Feature flag ready for production enablement
- [ ] Rollback plan documented and tested
- [ ] On-call team notified
- [ ] Monitoring dashboards updated
- [ ] Alerts configured and tested

## Related Documentation

- [FEATURE-SPECIFICATION.md](./FEATURE-SPECIFICATION.md) - Detailed feature design
- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Architecture context
- [API-SPECIFICATION.md](./API-SPECIFICATION.md) - API details
- [DEPLOYMENT-RUNBOOK.md](./DEPLOYMENT-RUNBOOK.md) - Deployment procedures
- [SECURITY-REQUIREMENTS.md](./SECURITY-REQUIREMENTS.md) - Security requirements

## Revision History

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial acceptance criteria | {Name} |
