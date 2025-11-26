# RETISIO Canvas Templates (Legacy)

**Status**: Legacy - Previous Project  
**Authority**: Reference Only - NOT for TJMPaaS Use  
**Origin**: RETISIO project  
**Archived**: 2025-11-26

These canvas templates are from a previous project and are preserved for reference only.

**For TJMPaaS**, use: [`doc/internal/templates/SERVICE-CANVAS.md`](../../templates/SERVICE-CANVAS.md)

## Files

- `MICROSERVICENAME-microservice-canvas.md`: Microservice canvas template
- `WEBAPPNAME-webapp-canvas.md`: Web app canvas template  
- `PRODUCTNAME-product-canvas.md`: Product canvas template
- `MICROFRONTENDNAME-microfrontend-canvas.md`: Microfrontend canvas template

## Format Differences

### RETISIO Canvas Format (Legacy)
- Product Manager, Chief Architect, SME fields
- RETISIO-specific dependencies (RETISIO Service/Frontend/Product)
- Table-based Commands/Queries/Events with "Reasonable Use" and "Warning Threshold"
- Focused on internal team structure

### TJMPaaS Service Canvas (Current)
- Framework-agnostic
- TJMPaaS governance integration (ADR/PDR references)
- CQRS maturity level documentation
- Actor/agent model section
- Comprehensive operational and security sections
- Defined in [PDR-0006](../../governance/PDRs/PDR-0006-service-canvas-standard.md)

## Why Archived

TJMPaaS has adopted a unified Service Canvas format (PDR-0006) that supersedes these templates. These are preserved for:

1. **Historical Reference**: Understanding previous canvas approaches
2. **Pattern Recognition**: Alternative ways to structure service documentation
3. **Potential Inspiration**: Elements that might enhance future TJMPaaS canvas versions
4. **Institutional Knowledge**: Lessons learned from previous projects

## Do Not Use

⚠️ **Warning**: DO NOT use these templates for new TJMPaaS services.

**Use instead**: [SERVICE-CANVAS.md](../../templates/SERVICE-CANVAS.md) from the templates directory.

## Potential Future Enhancements

Elements from these legacy templates that might inspire future TJMPaaS canvas enhancements:

- **Usage Thresholds**: "Reasonable Use" and "Warning Threshold" for API operations (useful for capacity planning)
- **Team Structure Fields**: Product Manager, Chief Architect, SME (might add to canvas if team grows)
- **Explicit Rate Limits**: Documented rate limits per operation (good for SLA definition)

These are preserved as reference, not for immediate adoption. Any incorporation into TJMPaaS would require ADR/PDR and template updates.
