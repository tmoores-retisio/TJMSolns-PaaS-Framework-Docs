# TJMPaaS Technology Stack Summary

**Purpose**: Consolidated technology choices from architectural decisions

**Last Updated**: 2025-11-26

---

## Core Stack

### Language and Build

| Component | Choice | Version | Governance | Rationale |
|-----------|--------|---------|------------|-----------|
| **Language** | Scala | 3.3+ | [ADR-0004](../governance/ADRs/ADR-0004-scala3-technology-stack.md) | FP support, type safety, modern features, JVM ecosystem |
| **Build Tool** | Mill | Latest | [ADR-0004](../governance/ADRs/ADR-0004-scala3-technology-stack.md) | Fast, simple, Scala-native, 40% faster than sbt |
| **JVM** | OpenJDK | 17 or 21 (LTS) | [ADR-0004](../governance/ADRs/ADR-0004-scala3-technology-stack.md) | LTS support, mature, well-tested |

**Industry Validation**: LinkedIn/Spotify Scala 3 adoption; VirtusLab reports 40% faster builds with Mill; 2-3x compilation speed vs Scala 2.13

---

## Concurrency and Effects

### Actor Systems (max 3 per PDR-0005)

| Framework | License | Status | Governance | Use Case |
|-----------|---------|--------|------------|----------|
| **Pekko** | Apache 2.0 | **Recommended** | [ADR-0006](../governance/ADRs/ADR-0006-agent-patterns.md) | New services; community-driven Akka fork |
| **Akka Typed** | Apache 2.0 (2.6.x) | Acceptable | [ADR-0006](../governance/ADRs/ADR-0006-agent-patterns.md) | Mature ecosystem; 2.7+ uses BSL (avoid) |
| **ZIO Actors** | Apache 2.0 | Alternative | [ADR-0006](../governance/ADRs/ADR-0006-agent-patterns.md) | ZIO-first architectures |

**Industry Validation**: PayPal 99.999% uptime with actors; LinkedIn 15K+ actors, 100M+ req/day; ING Bank 10x throughput improvement

**Recommendation**: **Pekko** for new services (open-source, actively maintained, Akka-compatible)

### Effect Systems (max 3 per PDR-0005)

| Framework | License | Status | Use Case |
|-----------|---------|--------|----------|
| **ZIO** | Apache 2.0 | Primary | Comprehensive effect system, batteries included |
| **Cats Effect** | Apache 2.0 | Alternative | FP foundation, Typelevel ecosystem |

**Industry Validation**: Facebook study shows 57% fewer defects with FP; Jane Street $100B+ daily volume with FP

---

## Architecture Patterns

### Reactive Manifesto (ADR-0005)

| Principle | Implementation | Benefit |
|-----------|---------------|---------|
| **Responsive** | < 200ms p95 SLA | Fast response = better conversion |
| **Resilient** | Circuit breakers, supervision | Failures isolated |
| **Elastic** | Kubernetes HPA | Scale with demand |
| **Message-Driven** | Actors, Kafka, async | Decoupling, backpressure |

**Industry Validation**: Netflix 2B+ API req/day; Walmart 40% cost reduction, 50% latency improvement; LinkedIn 100M+ req/day, 99.99% uptime

### CQRS Patterns (ADR-0007)

| Level | Description | TJMPaaS Usage | Example Services |
|-------|-------------|---------------|------------------|
| **Level 1** | Simple CQRS (same DB, separate methods) | Rarely used | Simple config services |
| **Level 2** | Standard CQRS (separate models/DBs, no ES) | **Default** | Cart, product catalog, profiles |
| **Level 3** | Full CQRS/ES (event sourcing, complete audit) | Audit-critical | Orders, payments, inventory |

**Industry Validation**: ING Bank 60% cost reduction; eBay 1B+ products, sub-10ms query latency; Capital One 70% latency reduction

**Document in Service Canvas**: Each service specifies CQRS level (PDR-0006)

### Event-Driven Architecture (ADR-0007)

| Component | Choice | Purpose |
|-----------|--------|---------|
| **Event Streaming** | Apache Kafka | High-throughput, durable, scalable |
| **Event Sourcing** | Akka/Pekko Persistence | Immutable event log, audit trail |
| **Integration** | Async message boundaries | Service decoupling, resilience |

**Industry Validation**: Netflix 1 trillion events/day, 50-60% cost reduction; Uber 100B+ events/day; Shopify 1M+ events/sec peak

---

## HTTP and APIs

### HTTP Frameworks (max 3 per PDR-0005)

| Framework | License | Status | Use Case |
|-----------|---------|--------|----------|
| **http4s** | Apache 2.0 | Primary | Pure functional HTTP, mature |
| **ZIO HTTP** | Apache 2.0 | Alternative | ZIO-native HTTP server |

### JSON Libraries (max 3 per PDR-0005)

| Library | License | Status | Use Case |
|---------|---------|--------|----------|
| **circe** | Apache 2.0 | Primary | Popular, well-documented |
| **zio-json** | Apache 2.0 | Alternative | ZIO-native, performant |

---

## Persistence and Data

### Event Sourcing (max 3 per PDR-0005)

| Framework | License | Status | Use Case |
|-----------|---------|--------|----------|
| **Pekko Persistence** | Apache 2.0 | Recommended | Event sourcing for Pekko actors |
| **Akka Persistence** | Apache 2.0 (2.6.x) | Acceptable | Event sourcing for Akka actors |

### Storage Options

| Type | Technology | Use Case |
|------|-----------|----------|
| **Event Store** | PostgreSQL, Cassandra, Kafka | Event journal storage |
| **Read Models** | PostgreSQL (relational), MongoDB (flexible), Elasticsearch (search) | Optimized query projections |
| **Message Broker** | Apache Kafka (primary), RabbitMQ (alternative) | Event streaming, integration |

---

## Testing (max 3 per PDR-0005)

| Framework | License | Status | Use Case |
|-----------|---------|--------|----------|
| **munit** | Apache 2.0 | Primary | Fast, simple, Scala-native |
| **scalatest** | Apache 2.0 | Alternative | Comprehensive, mature |

---

## Containerization and Deployment

### Containers (ADR-0003)

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Container Format** | OCI/Docker | Industry standard, cloud-portable |
| **Orchestration** | Kubernetes | Multi-cloud, mature ecosystem |
| **Cloud Platform** | GCP (GKE initial) | Pilot platform, multi-cloud later |
| **Base Images** | Alpine, Distroless | Minimal size, security |
| **Registry** | GCP Artifact Registry | Secure, integrated with GCP |

**Best Practices**:
- Multi-stage builds
- Non-root user execution
- Health check endpoints (`/health`, `/ready`)
- Graceful shutdown (SIGTERM)
- 12-factor app principles

---

## Framework Selection Policy (PDR-0005)

### Rules

1. **Best Fit Per Service**: Choose best framework for service needs
2. **Max 3 Per Category**: Limit to 3 frameworks per category **across ALL TJMSolns projects**
3. **Open-Source Only**: Apache 2.0, MIT, BSD, EPL licenses only (no commercial/BSL)
4. **Document Choices**: ADRs document selections and rationale
5. **Prefer Convergence**: New services prefer existing choices unless compelling reason

### Current Allocations

| Category | Allocated | Available Slots |
|----------|-----------|-----------------|
| Actor Systems | 3 (Pekko, Akka 2.6.x, ZIO) | 0 - FULL |
| Effect Systems | 2 (ZIO, Cats Effect) | 1 |
| HTTP Frameworks | 2 (http4s, ZIO HTTP) | 1 |
| Event Sourcing | 2 (Pekko Persistence, Akka Persistence) | 1 |
| JSON Libraries | 2 (circe, zio-json) | 1 |
| Testing | 2 (munit, scalatest) | 1 |

**Adding 4th Framework**: Requires explicit ADR, must retire one existing

---

## Licensing Policy

### Acceptable Licenses

- ✅ **Apache License 2.0** (preferred)
- ✅ **MIT License**
- ✅ **BSD Licenses** (2-clause, 3-clause)
- ✅ **Eclipse Public License (EPL)**

### Unacceptable

- ❌ **Commercial/Proprietary** (licensing costs)
- ❌ **Business Source License (BSL)** (e.g., Akka 2.7+)
- ❌ **GPL** (too restrictive for commercial use)
- ❌ **Licenses with usage restrictions**

**Rationale**: Zero licensing costs, no vendor lock-in, commercial flexibility

---

## Non-Functional Requirements (ADR-0005)

### Performance Targets

| Metric | Target | Governance |
|--------|--------|------------|
| **Response Time** | < 200ms p95 | ADR-0005 |
| **Availability** | 99.9% minimum | ADR-0005 |
| **Throughput** | Scales horizontally | ADR-0005 |
| **Recovery Time** | < 60 seconds | ADR-0005 |
| **Startup Time** | < 30 seconds | ADR-0003 |

### Reactive Alignment

| Principle | Validation | Evidence |
|-----------|-----------|----------|
| Responsive | < 200ms p95 | Every 100ms latency costs ~1% conversion |
| Resilient | Circuit breakers, supervision | Failures isolated via actor boundaries |
| Elastic | Kubernetes HPA | Scale with demand, cost optimization |
| Message-Driven | Actors, Kafka, async | Decoupling, backpressure, flow control |

---

## Service Documentation Requirements (PDR-0006)

Every service must include:

1. **README.md**: Entry point, quick start
2. **SERVICE-CANVAS.md**: Comprehensive single-page overview (mandatory)
3. **docs/**: Detailed documentation
   - ARCHITECTURE.md
   - API.md
   - DEPLOYMENT.md
   - runbooks/

**Service Canvas Sections**: Identity, Dependencies, Architecture, API Contract (Commands/Queries/Events), NFRs, Observability, Operations, Security, Testing, DR

**Template**: `doc/internal/governance/templates/SERVICE-CANVAS.md`

---

## Quick Decision Guide

### Choosing an Actor System

- **New service?** → **Pekko** (recommended: open-source, actively maintained)
- **Already know Akka?** → **Akka Typed 2.6.x** (acceptable, stay on 2.6.x)
- **ZIO-first architecture?** → **ZIO Actors** (lightweight, tight integration)

### Choosing an Effect System

- **Comprehensive, batteries included?** → **ZIO**
- **Typelevel ecosystem, FP foundation?** → **Cats Effect**

### Choosing a CQRS Level

- **Simple CRUD?** → No CQRS (just regular service)
- **High read volume, independent scaling?** → **Level 2 (Standard CQRS)**
- **Audit-critical (orders, payments)?** → **Level 3 (Full CQRS/ES)**

### Choosing HTTP Framework

- **Pure functional HTTP?** → **http4s**
- **ZIO-native?** → **ZIO HTTP**

---

## References

**Governance**:
- [ADR-0003: Containerization](../governance/ADRs/ADR-0003-containerization-strategy.md)
- [ADR-0004: Scala 3 Stack](../governance/ADRs/ADR-0004-scala3-technology-stack.md)
- [ADR-0005: Reactive Manifesto](../governance/ADRs/ADR-0005-reactive-manifesto-alignment.md)
- [ADR-0006: Actor Patterns](../governance/ADRs/ADR-0006-agent-patterns.md)
- [ADR-0007: CQRS/Event-Driven](../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md)
- [PDR-0005: Framework Selection Policy](../governance/PDRs/PDR-0005-framework-selection-policy.md)
- [PDR-0006: Service Canvas Standard](../governance/PDRs/PDR-0006-service-canvas-standard.md)

**Best Practices Research**:
- [Actor Patterns](../best-practices/architecture/actor-patterns.md)
- [CQRS Patterns](../best-practices/architecture/cqrs-patterns.md)
- [Event-Driven Architecture](../best-practices/architecture/event-driven.md)
- [Functional Programming](../best-practices/architecture/functional-programming.md)
- [Reactive Manifesto](../best-practices/architecture/reactive-manifesto.md)
- [Scala 3](../best-practices/development/scala3.md)
- [Mill Build Tool](../best-practices/development/mill-build-tool.md)

---

**For Complete Details**: Consult referenced ADRs, PDRs, and best practices research documents
