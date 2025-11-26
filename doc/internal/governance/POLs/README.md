# Policies (POLs)

This directory contains enforceable policies, standards, and guidelines for TJMPaaS.

## Purpose

Policies establish mandatory rules and standards that must be followed. Unlike ADRs and PDRs which explain decisions, POLs define requirements and compliance boundaries.

## Naming Convention

`POL-category-policy-name.md`

**Categories**:
- `security-` - Security policies
- `compliance-` - Regulatory/compliance policies
- `quality-` - Quality assurance policies
- `operational-` - Operations policies
- `data-` - Data governance policies

**Examples**:
- `POL-security-data-encryption.md`
- `POL-compliance-audit-logging.md`
- `POL-quality-code-coverage.md`
- `POL-operational-backup-retention.md`
- `POL-data-pii-handling.md`

## Template

Use `TEMPLATE.md` in this directory as the starting point for new policies.

## Index

| Category | Policy | Status | Effective Date |
|----------|--------|--------|----------------|
| Security | [Security Baseline Requirements](POL-security-baseline.md) | Active | 2025-11-26 |
| Quality  | [Code Quality Standards](POL-quality-code-standards.md) | Active | 2025-11-26 |
| Example  | [Template](TEMPLATE.md) | Example | - |

## Creating a New Policy

1. Copy `TEMPLATE.md` to new file with appropriate category prefix
2. Clearly define requirements, not suggestions
3. Include compliance verification methods
4. Specify consequences of non-compliance
5. Update the index table above
6. Commit with descriptive message: `docs: add POL-category-name`

## When to Create a Policy

Create a policy when establishing:

- **Security Requirements**: Encryption standards, access controls, vulnerability management
- **Compliance Obligations**: Regulatory requirements, audit trails, data residency
- **Quality Standards**: Code coverage, testing requirements, performance baselines
- **Operational Rules**: Backup procedures, disaster recovery, change management
- **Data Governance**: PII handling, data retention, privacy requirements

## Policy vs Decision Record

- **Use POL** when: "We must do X" (requirement, mandate, rule)
- **Use ADR/PDR** when: "We decided to do X because Y" (choice, rationale, context)

Policies often result from decisions, but the policy document focuses on the requirement, not the reasoning.

## Review and Updates

- Review all policies annually
- Review security policies whenever threat landscape changes
- Review compliance policies when regulations change
- Document policy versions and change history
- Superseded policies should be marked as such but retained for audit trail

## Compliance Tracking

Each policy should include:
- **Verification Method**: How compliance is checked
- **Frequency**: How often compliance is verified
- **Owner**: Who is responsible for enforcement
- **Exceptions**: Process for requesting policy exceptions

## Related Documents

- [Governance README](../README.md) - Governance framework overview
- [Security Documentation](../../architecture/security/) - Security architecture
- [Operations Documentation](../../operations/) - Operational procedures
