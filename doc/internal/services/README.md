# Services Documentation

This directory contains documentation for individual services within the TJMPaaS framework.

## Purpose

Service documentation provides detailed information about each containerized service:

- Service purpose and capabilities
- Configuration and deployment
- APIs and interfaces
- Dependencies and integration
- Operational considerations

## Organization

Each service should have its own subdirectory:

```text
services/
├── service-name-1/
│   ├── README.md           # Service overview
│   ├── configuration.md    # Configuration guide
│   ├── api.md             # API documentation
│   ├── deployment.md      # Deployment procedures
│   └── troubleshooting.md # Common issues
└── service-name-2/
    └── ...
```

## Service Documentation Template

Each service directory should contain:

### README.md

- **Purpose**: What the service does
- **Capabilities**: Key features
- **Dependencies**: Required services/infrastructure
- **Quick Start**: Basic usage
- **Links**: To other service docs

### configuration.md

- Environment variables
- Configuration files
- Default values
- Configuration examples
- Security considerations

### api.md (if applicable)

- Endpoints
- Request/response formats
- Authentication
- Rate limits
- Examples

### deployment.md

- Prerequisites
- Container image details
- Deployment steps
- Health checks
- Rollback procedures

### troubleshooting.md

- Common issues
- Debugging procedures
- Log locations
- Performance tuning

## Service Naming

- Use lowercase with hyphens: `service-name`
- Be descriptive but concise
- Match container/repo names when possible

## Service Lifecycle

As services are created, document them:

1. **Planning**: Create service directory with README
2. **Development**: Add configuration and API docs
3. **Deployment**: Add deployment procedures
4. **Operations**: Add troubleshooting guide
5. **Maintenance**: Keep docs updated with changes

## Service Catalog

| Service | Purpose | Status | Documentation |
|---------|---------|--------|---------------|
| _TBD_   | _TBD_   | _TBD_  | _TBD_         |

## Best Practices

1. **Keep Updated**: Update docs when service changes
2. **Include Examples**: Real-world usage examples
3. **Document Defaults**: What happens out-of-the-box
4. **Link to Architecture**: Reference architecture docs
5. **Version Carefully**: Note which versions docs apply to

## Related Documents

- [Architecture](../architecture/) - System design
- [Operations](../operations/) - Operational procedures
- [Governance ADRs](../governance/ADRs/) - Technical decisions
