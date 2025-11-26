---
**Status**: Legacy - Previous Project  
**Authority**: Reference Only - NOT for TJMPaaS Use  
**Origin**: RETISIO project  
**Superseded By**: [SERVICE-CANVAS.md](../../templates/SERVICE-CANVAS.md)  
**Archived**: 2025-11-26  
---

⚠️ **DEPRECATED**: This template is from a previous project. For TJMPaaS, use [SERVICE-CANVAS.md](../../templates/SERVICE-CANVAS.md).

---

| *Version:* v0.0.0| **MICROSERVICENAME CANVAS** | *Domain:* MICROSERVICEDOMAIN |
|:--------------------------|:--------------------------:|--------------------------:|
| | **Internal Details** | |
| *Product Manager:* PRODUCTMANAGER | *Chief Architect:* CHIEFARCHITECT | *SME:* SME |
| [Wiki](#) | [Git](#) | [Jira](#) |
|*Charter*|*Value Proposition*|*Positioning*|
|PRODUCTMANAGER, please replace this text with a short mission statement for this service|PRODUCTMANAGER, please replace this text with a short, "elevator pitch," describing the principal value proposition of the service|PRODUCTMANAGER, please replace this text with a short description of the ideal customer and/or target audience of this service.|
| | **Dependencies** | |
| *Type* | *Target* | *Version* |
| RETISIO Service | [microservice-name-linked-to-canvas](#) | v0.0.* |
| RETISIO Frontend | [microfrontend-name-linked-to-canvas](#) | v0.0.* |
| RETISIO Product | [product-name-linked-to-canvas](#) | v0.0.* |
| External/3rd Party Service | [asset-name-linked-to-src](#) | v0.0.* |
| External/3rd Party Product| [asset-name-linked-to-src](#) | v0.0.* |
| | [**MICROSERVICENAME API**](#) | |
| **Commands** | **Reasonable Use** | **Warning Threshold** |
| syn-command&Rarr; | 1 &lt; calls/session &lt; 5 | &gt;10 calls/session |
| syn-command&Rarr; | 1 &lt; calls/hour &lt; 10 | &gt;100 calls/hour |
| syn-command&Rarr; | 1 &lt; calls/order &lt; 5 | &gt;10 calls/order |
| async-command&rarrb; | 1 &lt; calls/session &lt; 5 | &gt;10 calls/session |
| async-command&rarrb;; | 1 &lt; calls/hour &lt; 10 | &gt;100 calls/hour |
| async-command&rarrb; | 1 &lt; calls/order &lt; 5 | &gt;10 calls/order |
| **Queries** | **Reasonable Use** | **Warning Threshold** |
| query | 1 &lt; calls/session &lt; 5 | &gt;10 calls/session |
| query | 1 &lt; calls/hour &lt; 10 | &gt;100 calls/hour |
| query | 1 &lt; calls/order &lt; 5 | &gt;10 calls/order |
| **Events** | **Reasonable Use** | **Warning Threshold** |
| outbound-event&rarr; | 1 &lt; calls/min &lt; 5 | &gt;10 calls/min |
| inbound-event&larr; | 1 &lt; calls/min &lt; 10 | &gt;100 calls/min |
| | Non-Functional Requirements | |
| **Requirement/SLA** | **Average** | **SLA** |
| *Availability* | 99.999 | **99.90** |
| *Foo Rate* | 100 foos/min | **10 foos/min** |
| *Bar Rate* | 500 bars/min | **50 foos/min** |
| | **Observability** | |
| **Metric** | **Description** | **Notes** |
| [Health Check](#) | Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.  | Mandatory for all services |
| [Foo](#) | Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. | Shows in dashboard: x |
| [Bar](#) | Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. | Shows in stream: x |
| | **Runbooks** | |
| [Provisioning](#) | [Maintenance](#) | [Upgrading](#) |
| [Deprovisioning](#) | [Testing & Troubleshooting](#) | [Suspension](#) |
