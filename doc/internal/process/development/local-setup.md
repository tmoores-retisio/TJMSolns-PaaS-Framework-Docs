# TJMPaaS Local Development Guide

**Version**: 1.0  
**Date**: December 14, 2025  
**Owner**: Tony Moores, TJM Solutions LLC  
**Status**: Active

## Overview

This guide provides practical instructions for developing TJMPaaS services on the monsoon workstation using local infrastructure. Per [ADR-0008: Local-First Development Strategy](./governance/ADRs/ADR-0008-local-first-development.md), Phases 0-2 use 100% local development to optimize costs (~$1,200 savings) while maintaining cloud-ready architecture.

## Prerequisites

### Hardware Requirements

**Monsoon Specifications** (validated):
- CPU: Intel Core i7-7700 (4 cores, 8 threads @ 4.2GHz)
- RAM: 64 GB DDR4
- Storage: 2.73 TB (2x 1TB SSD + 1TB external)
- Network: Gigabit Ethernet
- OS: Linux Mint Debian Edition 7 (LMDE 7 Gigi)

**Capacity**: Can run full TJMPaaS stack (infrastructure + 5-6 services + dev tools) with 20GB+ RAM free.

### Software Requirements

**Installed**:
- Docker (verified operational)
- Docker Compose
- Git
- OpenJDK 17 or 21 (LTS)
- Mill build tool
- Text editor or IDE (VS Code with Metals, or IntelliJ IDEA)

**To Install** (if needed):
```bash
# Docker (if not installed)
sudo apt update
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER
# Log out and back in for group to take effect

# OpenJDK 21
sudo apt install openjdk-21-jdk

# Mill
curl -L https://github.com/com-lihaoyi/mill/releases/download/0.11.6/0.11.6 > mill
chmod +x mill
sudo mv mill /usr/local/bin/

# VS Code with Metals
# Download from https://code.visualstudio.com/
# Install Scala (Metals) extension
```

## Quick Start (5 Minutes)

### 1. Start Local Infrastructure

```bash
# Navigate to local infrastructure directory
cd ~/TJMSolns/Projects/TJMPaaS/local-infra

# Start all infrastructure services
docker-compose up -d

# Verify all services are healthy (wait ~30 seconds)
docker-compose ps

# Expected output:
# NAME                     STATUS    PORTS
# tjmpaas-postgres         healthy   0.0.0.0:5432->5432/tcp
# tjmpaas-postgres-tenants healthy   0.0.0.0:5433->5432/tcp
# tjmpaas-redis            healthy   0.0.0.0:6379->6379/tcp
# tjmpaas-zookeeper        running   0.0.0.0:2181->2181/tcp
# tjmpaas-kafka            healthy   0.0.0.0:9092->9092/tcp
# tjmpaas-kafka-ui         running   0.0.0.0:8080->8080/tcp
# tjmpaas-prometheus       running   0.0.0.0:9090->9090/tcp
# tjmpaas-grafana          running   0.0.0.0:3000->3000/tcp
# tjmpaas-jaeger           running   0.0.0.0:16686->16686/tcp
# tjmpaas-adminer          running   0.0.0.0:8081->8080/tcp

# Create Kafka topics
./kafka-topics.sh
```

### 2. Verify Infrastructure

Open in browser:
- **Kafka UI**: http://localhost:8080 (manage Kafka topics and messages)
- **Grafana**: http://localhost:3000 (metrics visualization, login: admin/admin)
- **Prometheus**: http://localhost:9090 (metrics collection)
- **Jaeger**: http://localhost:16686 (distributed tracing)
- **Adminer**: http://localhost:8081 (database management)

### 3. Develop a Service

```bash
# Clone service template
cd ~/TJMSolns/Projects
git clone https://github.com/TJMSolns/TJMSolns-ServiceTemplate.git TJMSolns-MyService
cd TJMSolns-MyService

# Implement service (see Entity Management Service design for reference)
# Edit src/main/scala/...

# Compile
mill myservice.compile

# Run tests
mill myservice.test

# Run service locally (connects to localhost infrastructure)
mill myservice.run
# Service starts on http://localhost:8082
# Connects to:
#   - PostgreSQL: localhost:5432
#   - Kafka: localhost:9092
#   - Redis: localhost:6379
```

### 4. Verify Service Operation

```bash
# Check health
curl http://localhost:8082/health
# Expected: {"status":"UP"}

# Check readiness
curl http://localhost:8082/ready
# Expected: {"status":"READY","dependencies":["postgres","kafka","redis"]}

# Check metrics
curl http://localhost:8082/metrics
# Expected: Prometheus metrics output

# Test API endpoint
curl -X POST http://localhost:8082/api/v1/tenants \
  -H "Content-Type: application/json" \
  -d '{"name":"ACME Corp","plan":"professional"}'
# Expected: {"id":"tenant-xxx","name":"ACME Corp","plan":"professional"}
```

### 5. Monitor Service

- **Logs**: Check service stdout/stderr
- **Metrics**: http://localhost:9090 → Query: `http_requests_total`
- **Traces**: http://localhost:16686 → Search for service traces
- **Events**: http://localhost:8080 → View Kafka topics
- **Database**: http://localhost:8081 → Connect to PostgreSQL

## Infrastructure Services

### PostgreSQL (Primary Database)

**Connection Details**:
- **Host**: localhost
- **Port**: 5432
- **User**: tjmpaas
- **Password**: (from local-infra/.env, default: tjmpaas_dev)
- **Databases**: entity_management, cart_service, order_service, product_catalog, provisioning_service

**Usage**:
```bash
# Connect via psql
psql -h localhost -p 5432 -U tjmpaas -d entity_management

# Connect via Adminer
# Open http://localhost:8081
# System: PostgreSQL
# Server: postgres
# Username: tjmpaas
# Password: (from .env)
# Database: entity_management
```

**Schema Management**:
- Services create their own schemas on startup
- Use Flyway or Liquibase for migrations (in service code)
- Read-only user available: tjmpaas_readonly

### PostgreSQL (Multi-Tenant Database)

**Connection Details**:
- **Host**: localhost
- **Port**: 5433 (different port!)
- **User**: tjmpaas
- **Password**: (from local-infra/.env, default: tjmpaas_dev)
- **Database**: tenants

**Purpose**: Separate database for multi-tenant metadata (tenant registry, subscription plans, etc.)

### Redis (Caching and Session Store)

**Connection Details**:
- **Host**: localhost
- **Port**: 6379
- **No password** (local development only)

**Usage**:
```bash
# Connect via redis-cli
redis-cli -h localhost -p 6379

# Test connection
redis-cli ping
# Expected: PONG

# Set/get value
redis-cli SET mykey "hello"
redis-cli GET mykey
```

**Typical Use Cases**:
- Session storage (user sessions, shopping cart sessions)
- Cache (product catalog cache, permission cache)
- Rate limiting counters
- Temporary data (OTP codes, email verification tokens)

### Apache Kafka (Event Streaming)

**Connection Details**:
- **Bootstrap Servers**: localhost:9092
- **Zookeeper**: localhost:2181

**Topics** (auto-created by kafka-topics.sh):
- `entity-management.tenants.v1` (3 partitions)
- `entity-management.organizations.v1` (3 partitions)
- `entity-management.users.v1` (3 partitions)
- `entity-management.roles.v1` (3 partitions)
- `entity-management.audit.v1` (6 partitions)
- `cart.events.v1` (3 partitions)
- `order.events.v1` (6 partitions)
- `product.events.v1` (3 partitions)

**Usage**:
```bash
# List topics
docker exec tjmpaas-kafka kafka-topics --list --bootstrap-server localhost:9092

# Describe topic
docker exec tjmpaas-kafka kafka-topics --describe \
  --topic entity-management.tenants.v1 \
  --bootstrap-server localhost:9092

# Consume messages (testing)
docker exec tjmpaas-kafka kafka-console-consumer \
  --topic entity-management.tenants.v1 \
  --from-beginning \
  --bootstrap-server localhost:9092

# Produce message (testing)
docker exec -it tjmpaas-kafka kafka-console-producer \
  --topic entity-management.tenants.v1 \
  --bootstrap-server localhost:9092
# Type message, press Ctrl+D to send
```

**Kafka UI**: http://localhost:8080
- View topics, partitions, messages
- Consumer group management
- Schema registry (if enabled)

### Prometheus (Metrics Collection)

**Connection Details**:
- **URL**: http://localhost:9090

**Configuration**: `local-infra/prometheus.yml`
- Scrapes service metrics every 15 seconds
- Configured for all TJMPaaS services (ports 8082-8086)

**Usage**:
1. Open http://localhost:9090
2. Graph tab → Query: `http_requests_total`
3. Execute → View metric graph

**Useful Queries**:
- `http_requests_total` - Total HTTP requests
- `http_request_duration_seconds` - Request latency
- `jvm_memory_used_bytes` - JVM memory usage
- `process_cpu_seconds_total` - CPU usage
- `pekko_actor_mailbox_size` - Actor mailbox depth

### Grafana (Metrics Visualization)

**Connection Details**:
- **URL**: http://localhost:3000
- **Username**: admin
- **Password**: (from local-infra/.env, default: admin)

**Setup**:
- Prometheus datasource pre-configured
- Import dashboards:
  - JVM Micrometer (ID: 4701)
  - Pekko/Akka Metrics (ID: 7559)
  - Kafka (ID: 7589)

**Creating Dashboards**:
1. Login to Grafana
2. Dashboards → Import → Enter dashboard ID
3. Select Prometheus datasource
4. Import

### Jaeger (Distributed Tracing)

**Connection Details**:
- **UI**: http://localhost:16686
- **Agent Port**: 6831/udp (services send traces here)

**Usage**:
1. Open http://localhost:16686
2. Select service from dropdown
3. Find Traces
4. Click trace to see spans

**Service Configuration** (example):
```scala
// In service code
val jaegerConfig = JaegerConfig(
  serviceName = "entity-management-service",
  agentHost = "localhost",
  agentPort = 6831
)
```

### Adminer (Database Management)

**Connection Details**:
- **URL**: http://localhost:8081
- **System**: PostgreSQL
- **Server**: postgres (for primary) or postgres-tenants
- **Username**: tjmpaas
- **Password**: (from .env)

**Usage**:
- Browse tables
- Run SQL queries
- Export/import data
- View table structures

## Service Development Workflow

### Step 1: Clone Service Template

```bash
cd ~/TJMSolns/Projects
git clone https://github.com/TJMSolns/TJMSolns-ServiceTemplate.git TJMSolns-MyService
cd TJMSolns-MyService
```

### Step 2: Configure Service

**Edit build.sc**:
```scala
object myservice extends ScalaModule {
  def scalaVersion = "3.3.1"
  
  def ivyDeps = Agg(
    ivy"org.apache.pekko::pekko-actor-typed:1.0.1",
    ivy"dev.zio::zio:2.0.19",
    ivy"org.http4s::http4s-ember-server:0.23.24",
    ivy"org.postgresql:postgresql:42.7.1",
    // ... other dependencies
  )
}
```

**Edit src/main/resources/application.conf**:
```hocon
myservice {
  http {
    host = "0.0.0.0"
    port = 8082
  }
  
  postgres {
    host = "localhost"
    port = 5432
    database = "myservice_db"
    username = "tjmpaas"
    password = ${?POSTGRES_PASSWORD}
  }
  
  kafka {
    bootstrap-servers = "localhost:9092"
  }
  
  redis {
    host = "localhost"
    port = 6379
  }
}
```

### Step 3: Implement Service

**Follow TJMPaaS Patterns**:
- **Actor Model**: Use Pekko actors for stateful entities
- **CQRS**: Separate command and query models
- **Event Sourcing**: Persist events, build state from events
- **Multi-Tenant**: Include tenant_id in all data
- **Reactive**: Non-blocking, async operations

**Example Structure**:
```
src/main/scala/
├── myservice/
│   ├── Main.scala                    # Application entry point
│   ├── actors/
│   │   ├── MyEntityActor.scala      # Event-sourced actor
│   │   └── MySupervisor.scala       # Supervision hierarchy
│   ├── api/
│   │   ├── Routes.scala             # HTTP routes
│   │   ├── CommandHandlers.scala   # Command endpoints
│   │   └── QueryHandlers.scala     # Query endpoints
│   ├── domain/
│   │   ├── Commands.scala           # Command messages
│   │   ├── Events.scala             # Event messages
│   │   └── State.scala              # Domain state
│   ├── persistence/
│   │   ├── EventStore.scala         # Event persistence
│   │   └── QueryRepository.scala   # Read model queries
│   └── integration/
│       ├── KafkaProducer.scala      # Event publishing
│       └── KafkaConsumer.scala      # Event consumption
```

### Step 4: Build and Test

```bash
# Compile
mill myservice.compile

# Run tests
mill myservice.test

# Run test coverage
mill myservice.scoverage.htmlReport

# Assembly JAR
mill myservice.assembly
```

### Step 5: Run Locally

**Terminal 1** (Infrastructure):
```bash
cd ~/TJMSolns/Projects/TJMPaaS/local-infra
docker-compose up
# Leave running
```

**Terminal 2** (Service):
```bash
cd ~/TJMSolns/Projects/TJMSolns-MyService

# Set environment variables (optional, defaults work)
export POSTGRES_PASSWORD=tjmpaas_dev
export LOG_LEVEL=DEBUG

# Run service
mill myservice.run

# Service starts:
# [info] Server started on http://localhost:8082
# [info] Connected to PostgreSQL
# [info] Connected to Kafka
# [info] Connected to Redis
# [info] Service ready
```

**Terminal 3** (Testing):
```bash
# Health check
curl http://localhost:8082/health

# API calls
curl -X POST http://localhost:8082/api/v1/... \
  -H "Content-Type: application/json" \
  -d '{...}'
```

### Step 6: Monitor and Debug

**Logs**:
- Service stdout/stderr in Terminal 2
- Structured JSON logs for parsing

**Metrics**:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

**Traces**:
- Jaeger: http://localhost:16686

**Events**:
- Kafka UI: http://localhost:8080

**Database**:
- Adminer: http://localhost:8081

### Step 7: Containerize Service

**Create Dockerfile**:
```dockerfile
# Multi-stage build for smaller image
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build
COPY . .
RUN ./mill myservice.assembly

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /build/out/myservice/assembly.dest/out.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Build and Run**:
```bash
# Build image
docker build -t tjmsolns/myservice:0.1.0 .

# Run container (connected to tjmpaas-network)
docker run -d \
  --name myservice \
  --network tjmpaas-network \
  -p 8082:8080 \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_PASSWORD=tjmpaas_dev \
  -e KAFKA_BOOTSTRAP_SERVERS=kafka:9093 \
  -e REDIS_HOST=redis \
  tjmsolns/myservice:0.1.0

# Check logs
docker logs -f myservice

# Test
curl http://localhost:8082/health
```

## Common Tasks

### Daily Development

**Start infrastructure** (fast, uses existing volumes):
```bash
cd ~/TJMSolns/Projects/TJMPaaS/local-infra
docker-compose up -d
```

**Check status**:
```bash
docker-compose ps
docker-compose logs -f [service-name]
```

**Stop infrastructure** (preserves data):
```bash
docker-compose stop
```

**Restart specific service**:
```bash
docker-compose restart postgres
docker-compose restart kafka
```

### Database Operations

**Create new database**:
```bash
psql -h localhost -p 5432 -U tjmpaas -c "CREATE DATABASE new_service_db;"
```

**Backup database**:
```bash
pg_dump -h localhost -p 5432 -U tjmpaas entity_management > backup.sql
```

**Restore database**:
```bash
psql -h localhost -p 5432 -U tjmpaas entity_management < backup.sql
```

**Reset database** (DANGER: loses all data):
```bash
psql -h localhost -p 5432 -U tjmpaas -c "DROP DATABASE entity_management;"
psql -h localhost -p 5432 -U tjmpaas -c "CREATE DATABASE entity_management;"
```

### Kafka Operations

**Create topic**:
```bash
docker exec tjmpaas-kafka kafka-topics --create \
  --topic my-new-topic \
  --bootstrap-server localhost:9093 \
  --partitions 3 \
  --replication-factor 1
```

**Delete topic**:
```bash
docker exec tjmpaas-kafka kafka-topics --delete \
  --topic my-topic \
  --bootstrap-server localhost:9093
```

**View messages**:
```bash
docker exec tjmpaas-kafka kafka-console-consumer \
  --topic entity-management.tenants.v1 \
  --from-beginning \
  --max-messages 10 \
  --bootstrap-server localhost:9093
```

### Cleanup Operations

**Remove stopped containers**:
```bash
docker-compose down
```

**Remove containers and volumes** (DANGER: loses all data):
```bash
cd ~/TJMSolns/Projects/TJMPaaS/local-infra
docker-compose down -v
```

**Clean Docker system**:
```bash
# Remove unused containers, networks, images
docker system prune

# Remove all unused volumes
docker volume prune
```

## Troubleshooting

### Service Won't Connect to Database

**Symptoms**: `Connection refused` or `timeout`

**Solutions**:
```bash
# Check PostgreSQL is running
docker-compose ps postgres
# Should show "healthy"

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection
psql -h localhost -p 5432 -U tjmpaas -d entity_management -c "SELECT 1;"

# Verify password
grep POSTGRES_PASSWORD local-infra/.env
```

### Service Won't Connect to Kafka

**Symptoms**: `Connection refused`, `Timeout`, or `Unknown topic`

**Solutions**:
```bash
# Check Kafka is running
docker-compose ps kafka zookeeper
# Both should be running

# Check Kafka logs
docker-compose logs kafka

# List topics
docker exec tjmpaas-kafka kafka-topics --list --bootstrap-server localhost:9093

# Recreate topics
cd ~/TJMSolns/Projects/TJMPaaS/local-infra
./kafka-topics.sh
```

### Port Already in Use

**Symptoms**: `bind: address already in use`

**Solutions**:
```bash
# Find process using port
sudo netstat -tlnp | grep :5432

# Kill process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
```

### Out of Memory

**Symptoms**: Service crashes, slow performance, `OutOfMemoryError`

**Solutions**:
```bash
# Check Docker memory usage
docker stats

# Check system memory
free -h

# Stop unused services
docker-compose stop [unused-service]

# Increase JVM heap (in service startup)
mill myservice.run -Xmx2g -Xms1g
```

### Slow Performance

**Symptoms**: High latency, slow queries

**Solutions**:
```bash
# Check disk space
df -h

# Check Docker stats
docker stats

# Clean up Docker
docker system prune
docker volume prune

# Check PostgreSQL query performance
psql -h localhost -p 5432 -U tjmpaas entity_management \
  -c "SELECT * FROM pg_stat_activity;"

# Check Kafka lag
docker exec tjmpaas-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9093 \
  --list
```

### Infrastructure Won't Start

**Symptoms**: Services crash on startup

**Solutions**:
```bash
# Check logs
docker-compose logs

# Start services individually
docker-compose up postgres
docker-compose up zookeeper kafka

# Remove volumes and restart (DANGER: loses data)
docker-compose down -v
docker-compose up -d
```

## Best Practices

### Development

1. **Start Infrastructure First**: Always start `docker-compose up -d` before running services
2. **Use Health Checks**: Verify `/health` and `/ready` endpoints work
3. **Check Logs**: Monitor service logs for errors
4. **Test Incrementally**: Test each feature as implemented
5. **Use Metrics**: Monitor Prometheus metrics during development

### Testing

1. **Unit Tests**: Test business logic in isolation
2. **Integration Tests**: Test with real PostgreSQL, Kafka, Redis (via TestContainers)
3. **API Tests**: Test HTTP endpoints
4. **Performance Tests**: Use `wrk` or `ab` for load testing
5. **Multi-Tenant Tests**: Verify tenant isolation

### Code Quality

1. **Follow TJMPaaS Standards**: See [BEST-PRACTICES-GUIDE.md](./BEST-PRACTICES-GUIDE.md)
2. **Use Scala 3 Features**: Enums, union types, opaque types
3. **Functional Programming**: Immutability, pure functions, effect systems
4. **Actor Model**: Pekko actors for concurrency
5. **CQRS**: Separate command and query models
6. **Event Sourcing**: Persist events, build state from events

### Documentation

1. **Service Canvas**: Maintain `SERVICE-CANVAS.md` in service root
2. **API Documentation**: Document all endpoints with examples
3. **Architecture**: Document key design decisions
4. **Runbooks**: Document operational procedures

## Performance Tips

### JVM Tuning

```bash
# For development (default)
mill myservice.run

# For better performance (more heap)
mill myservice.run -Xmx4g -Xms2g

# For profiling
mill myservice.run -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints
```

### PostgreSQL Tuning

```sql
-- Increase connection pool (in service config)
-- Default: 10 connections
-- Increase if seeing "too many connections" errors

-- Check current connections
SELECT count(*) FROM pg_stat_activity;

-- Kill idle connections
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' 
AND state_change < now() - interval '1 hour';
```

### Kafka Tuning

```bash
# Increase batch size for higher throughput (in service config)
batch.size=16384

# Increase linger time for better batching
linger.ms=10

# Increase buffer memory
buffer.memory=33554432
```

## Migrating to Cloud (Phase 3+)

When ready to deploy to GCP (Phase 3+), see [ADR-0008 Migration Checklist](./governance/ADRs/ADR-0008-local-first-development.md#migration-checklist-local--cloud).

**Key Steps**:
1. Push Docker image to Artifact Registry
2. Create Kubernetes namespace
3. Create Cloud SQL instance
4. Create Pub/Sub topics
5. Deploy service to GKE
6. Verify health checks and metrics
7. Update DNS

**Migration Time**: < 1 day per service (target)

## Additional Resources

### Documentation

- [ADR-0008: Local-First Development Strategy](./governance/ADRs/ADR-0008-local-first-development.md)
- [CHARTER.md](./CHARTER.md) - Project mission and scope
- [ROADMAP.md](./ROADMAP.md) - Timeline and milestones
- [BEST-PRACTICES-GUIDE.md](./BEST-PRACTICES-GUIDE.md) - Research and patterns

### External Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Pekko Documentation](https://pekko.apache.org/)
- [Scala 3 Documentation](https://docs.scala-lang.org/scala3/)
- [Mill Build Tool](https://mill-build.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)

## Getting Help

**Issues**:
- Check [Troubleshooting](#troubleshooting) section above
- Review service logs
- Check infrastructure health: `docker-compose ps`

**Questions**:
- Review relevant ADRs in `doc/internal/governance/ADRs/`
- Consult SERVICE-CANVAS.md for service-specific information
- See BEST-PRACTICES-GUIDE.md for patterns and recommendations

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-12-14 | Initial version for local-first development | Tony Moores |
