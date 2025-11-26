# Process Decision Records (PDRs)

This directory contains records of significant process and workflow decisions made for TJMPaaS development and operations.

## Purpose

PDRs document how we work, not what we build. They capture decisions about:

- Development workflows
- Operational procedures
- Documentation practices
- Testing strategies
- Release processes
- Communication protocols

## Naming Convention

`PDR-NNNN-short-title.md`

**Examples**:
- `PDR-0001-documentation-structure.md`
- `PDR-0002-git-branching-strategy.md`
- `PDR-0003-deployment-approval-process.md`

## Template

Use `TEMPLATE.md` in this directory as the starting point for new PDRs.

## Index

| PDR # | Title | Status | Date |
|-------|-------|--------|------|
| 0001  | [Documentation Structure and Standards](PDR-0001-documentation-standards.md) | Accepted | 2025-11-26 |
| 0002  | [Governance Decision Framework](PDR-0002-governance-framework.md) | Accepted | 2025-11-26 |
| 0003  | [Governance Document Lifecycle](PDR-0003-governance-document-lifecycle.md) | Accepted | 2025-11-26 |
| 0004  | [Repository Organization Strategy](PDR-0004-repository-organization.md) | Accepted | 2025-11-26 |
| 0005  | [Framework and Library Selection Policy](PDR-0005-framework-selection-policy.md) | Accepted | 2025-11-26 |
| 0006  | [Service Canvas Documentation Standard](PDR-0006-service-canvas-standard.md) | Accepted | 2025-11-26 |
| 0007  | [Research-Backed Best Practices Framework](PDR-0007-best-practices-research.md) | Accepted | 2025-11-26 |
| -     | [Template](TEMPLATE.md) | Example | - |

## Creating a New PDR

1. Copy `TEMPLATE.md` to new file with next sequential number
2. Fill in all sections, focusing on process impact
3. Update the index table above
4. Share with stakeholders if process affects collaboration
5. Commit with descriptive message: `docs: add PDR-NNNN - <short title>`

## When to Create a PDR

Create a PDR when making decisions about:

- **Development**: Code review process, testing requirements, quality gates
- **Operations**: Deployment procedures, incident response, maintenance windows
- **Documentation**: Structure, standards, review process
- **Communication**: Status updates, decision-making authority, escalation paths
- **Tools**: Development tools, automation, productivity enhancements
- **Quality**: Definition of done, acceptance criteria, performance benchmarks

## Review and Updates

- Review PDRs quarterly or when process friction is identified
- PDRs can be updated if the process evolves (unlike ADRs)
- Major process changes should result in a new PDR that supersedes the old one
- Document lessons learned in the "Consequences" section over time

## Related Documents

- [Governance README](../README.md) - Governance framework overview
- [Operations Documentation](../../operations/) - Operational procedures
