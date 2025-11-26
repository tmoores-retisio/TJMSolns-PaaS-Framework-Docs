# POL-security-baseline: Security Baseline Requirements

**Status**: Active  
**Effective Date**: 2025-11-26  
**Review Date**: 2026-11-26  
**Owner**: Tony Moores  
**Category**: Security

## Purpose

This policy establishes baseline security requirements for all TJMPaaS services and infrastructure. These requirements ensure a consistent security posture across all services, protect sensitive data, and meet industry best practices for cloud-native applications.

## Scope

### Applies To

- All containerized services in TJMPaaS catalog
- All infrastructure components (Kubernetes, networking, storage)
- All deployment environments (development, staging, production)
- All data stores (databases, caches, object storage)
- All APIs and service interfaces
- All access control mechanisms

### Exclusions

- Local development environments (security recommended but not enforced)
- Temporary proof-of-concept services (must be clearly marked and deleted within 30 days)

## Policy Statement

All TJMPaaS services and infrastructure MUST implement the security requirements defined in this policy.

### Mandatory Requirements

#### 1. Encryption

**1.1 Data in Transit**
- All network traffic MUST use TLS 1.2 or higher
- All API endpoints MUST enforce HTTPS
- Internal service-to-service communication SHOULD use TLS (mTLS preferred)
- Unencrypted HTTP endpoints are PROHIBITED in production

**1.2 Data at Rest**
- All persistent storage MUST be encrypted
- Database encryption MUST be enabled
- Object storage MUST use server-side encryption
- Encryption keys MUST be managed via cloud KMS (GCP Cloud KMS initially)

**1.3 Secrets Management**
- Application secrets MUST use Kubernetes Secrets or cloud secret management
- Secrets MUST NOT be committed to version control
- Secrets MUST NOT appear in container images
- Secrets MUST NOT appear in logs
- Secret rotation MUST be supported

#### 2. Authentication and Authorization

**2.1 Identity**
- All services MUST authenticate callers
- Service-to-service authentication MUST use workload identity or service accounts
- User authentication MUST use industry-standard protocols (OAuth 2.0, OIDC)
- Anonymous access MUST be explicitly justified and approved

**2.2 Authorization**
- Principle of least privilege MUST be enforced
- Role-based access control (RBAC) MUST be implemented
- Service accounts MUST have minimal required permissions
- Authorization decisions MUST be logged

**2.3 Credentials**
- No shared accounts permitted
- No hardcoded credentials permitted
- Credentials MUST be rotated regularly (minimum annually)
- Default credentials MUST be changed immediately

#### 3. Network Security

**3.1 Segmentation**
- Network segmentation MUST be implemented via Kubernetes network policies
- Services MUST only accept traffic from authorized sources
- External access MUST be explicitly configured (default deny)
- Database access MUST be restricted to application tier

**3.2 Ingress Control**
- All external endpoints MUST be protected by Web Application Firewall (WAF) where available
- Rate limiting MUST be implemented on public APIs
- DDoS protection MUST be enabled
- IP allowlisting SHOULD be used where practical

#### 4. Container Security

**4.1 Images**
- Container images MUST be scanned for vulnerabilities before deployment
- Critical and high-severity vulnerabilities MUST be remediated before production deployment
- Base images MUST be from trusted sources only
- Images MUST use specific version tags (no `:latest` in production)

**4.2 Runtime**
- Containers MUST run as non-root user
- Read-only root filesystem SHOULD be used where possible
- Privileged containers are PROHIBITED unless explicitly approved
- Host network mode is PROHIBITED
- Capabilities MUST be dropped unless specifically required

**4.3 Registry**
- Container images MUST be stored in private registry (GCP Artifact Registry)
- Registry access MUST be authenticated
- Image signing SHOULD be implemented (future requirement)

#### 5. Logging and Monitoring

**5.1 Audit Logging**
- All authentication attempts MUST be logged
- All authorization failures MUST be logged
- All administrative actions MUST be logged
- All data access MUST be logged (for sensitive data)
- Logs MUST be retained for minimum 90 days

**5.2 Security Monitoring**
- Security events MUST be sent to centralized logging
- Critical security alerts MUST generate notifications
- Failed authentication attempts MUST be monitored
- Unusual access patterns MUST be detected

**5.3 Log Protection**
- Logs MUST NOT contain sensitive data (PII, credentials, secrets)
- Logs MUST be encrypted at rest
- Log tampering MUST be prevented

#### 6. Vulnerability Management

**6.1 Scanning**
- All container images MUST be scanned before deployment
- Running containers MUST be scanned regularly (weekly minimum)
- Infrastructure MUST be scanned for misconfigurations
- Dependencies MUST be scanned for known vulnerabilities

**6.2 Patching**
- Critical vulnerabilities MUST be patched within 7 days
- High vulnerabilities MUST be patched within 30 days
- Base images MUST be updated monthly minimum
- Security patches MUST be prioritized over feature development

#### 7. Incident Response

**7.1 Preparation**
- Security incident response plan MUST exist
- Security contacts MUST be documented
- Incident escalation path MUST be defined

**7.2 Detection and Response**
- Security incidents MUST be documented
- Security incidents MUST trigger post-mortem
- Security incidents MUST result in preventive improvements

### Prohibited Actions

The following actions are PROHIBITED without explicit written exception:

1. Storing credentials in version control
2. Using default credentials
3. Disabling security features for convenience
4. Granting excessive permissions
5. Exposing databases directly to internet
6. Running containers as root in production
7. Using unencrypted communication channels
8. Logging sensitive data
9. Sharing service accounts
10. Deploying known-vulnerable software

## Rationale

### Industry Standards

These requirements align with:
- OWASP Top 10 security risks
- CIS Benchmarks for containers and Kubernetes
- Cloud Security Alliance (CSA) guidance
- PCI DSS principles (for future payment processing)
- SOC 2 Type II requirements (for future commercial offering)

### Risk Mitigation

Security baseline reduces risk of:
- Data breaches
- Unauthorized access
- Service disruption
- Compliance violations
- Reputational damage
- Financial loss

### Commercial Viability

Strong security posture:
- Enables enterprise sales
- Supports compliance certifications
- Reduces liability
- Builds customer trust
- Differentiates from competitors

## Implementation

### Technical Controls

#### Encryption
- Enable TLS on all Kubernetes ingresses
- Configure GCP Cloud SQL with encryption
- Enable GCS bucket encryption
- Use GCP Cloud KMS for key management
- Configure Istio service mesh for mTLS (when implemented)

#### Access Control
- Implement Kubernetes RBAC policies
- Use GCP Workload Identity for service accounts
- Configure network policies in Kubernetes
- Implement OAuth 2.0 for user authentication

#### Scanning
- Integrate vulnerability scanning in CI/CD pipeline
- Use GCP Container Analysis for image scanning
- Implement runtime security monitoring
- Configure security dashboards

### Administrative Controls

- Security checklist for service deployment
- Security review before production deployment
- Regular security audits (quarterly)
- Security training (when team expands)
- Incident response drills (annually)

### Required Documentation

Each service MUST document:
- Authentication and authorization model
- Data classification and encryption approach
- Network security configuration
- Vulnerability scan results
- Security incident contacts

## Compliance

### Verification Method

**Automated**:
- CI/CD pipeline blocks on vulnerability scan failures
- Infrastructure scans run weekly
- Security policy violations detected by admission controllers
- Monitoring alerts on security events

**Manual**:
- Quarterly security audit of all services
- Annual penetration testing (when commercialization approaches)
- Regular review of access permissions
- Review of security logs

### Verification Frequency

| Control | Frequency | Method |
|---------|-----------|--------|
| Container vulnerability scanning | Every build | Automated |
| Running container scanning | Weekly | Automated |
| Network policy enforcement | Continuous | Automated |
| Access permission review | Quarterly | Manual |
| Security audit | Quarterly | Manual |
| Penetration testing | Annually | External (future) |

### Responsible Party

- **Owner**: Tony Moores
- **Enforcement**: CI/CD pipeline, Kubernetes admission controllers
- **Monitoring**: Cloud Operations (GCP)
- **Review**: Tony Moores (quarterly)

### Non-Compliance Consequences

**Development/Staging**:
- First violation: Warning, remediation required within 7 days
- Repeated violations: Service disabled until compliant

**Production**:
- Critical violations: Immediate service suspension
- High violations: Remediation required within 24 hours
- Medium violations: Remediation required within 7 days

## Exceptions

### Exception Process

Exceptions to this policy may be granted for:
- Technical limitations requiring alternative controls
- Time-limited security research
- Approved proof-of-concept work

**Process**:
1. Document business justification
2. Document compensating controls
3. Define exception duration
4. Submit to Owner (Tony) for approval
5. Document in security exception register

### Exception Approval Authority

Tony Moores (Owner) has sole authority to approve exceptions.

### Exception Duration

- Maximum 90 days for technical limitations
- Maximum 30 days for POC work
- Renewal requires re-justification

### Exception Review

All active exceptions reviewed quarterly.

## Roles and Responsibilities

| Role | Responsibility |
|------|---------------|
| Owner (Tony) | Establish policy; approve exceptions; enforce compliance; conduct audits |
| Service Developers (Tony) | Implement security controls; document security approach; remediate vulnerabilities |
| CI/CD Pipeline | Enforce automated security checks; block non-compliant deployments |
| Monitoring Systems | Detect and alert on security events |

## Related Policies

- POL-quality-code-standards (future) - Code quality includes security practices
- POL-data-classification (future) - Data handling requirements
- POL-incident-response (future) - Security incident procedures

## Related Standards

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Cloud Security Alliance](https://cloudsecurityalliance.org/)

## References

- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Container Security](https://cloud.google.com/architecture/best-practices-for-building-containers)
- [ADR-0001: GCP as Pilot Platform](../ADRs/ADR-0001-gcp-pilot-platform.md)
- [ADR-0003: Containerization Strategy](../ADRs/ADR-0003-containerization-strategy.md)

## Definitions

| Term | Definition |
|------|------------|
| **TLS** | Transport Layer Security - Cryptographic protocol for secure communication |
| **mTLS** | Mutual TLS - Both client and server authenticate each other |
| **KMS** | Key Management Service - System for managing encryption keys |
| **RBAC** | Role-Based Access Control - Authorization based on user roles |
| **WAF** | Web Application Firewall - Firewall for HTTP/HTTPS traffic |
| **OIDC** | OpenID Connect - Authentication layer on OAuth 2.0 |
| **PII** | Personally Identifiable Information - Data that can identify individuals |

## Review and Maintenance

### Review Schedule

This policy will be reviewed:
- **Annually**: Comprehensive review and update
- **Quarterly**: Quick compliance check
- **When**: Security incidents occur, major technology changes, compliance requirements change

### Update Process

1. Identify need for update
2. Draft changes with rationale
3. Review impact on existing services
4. Communicate changes to stakeholders (future)
5. Update policy version
6. Set new review date

### Notification

Policy changes communicated via:
- Git commit notifications
- Session summary documentation
- Direct communication (when team expands)

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-26 | Initial policy | Tony Moores |

## Approval

| Role | Name | Date |
|------|------|------|
| Policy Owner | Tony Moores | 2025-11-26 |
| Approver | Tony Moores | 2025-11-26 |
