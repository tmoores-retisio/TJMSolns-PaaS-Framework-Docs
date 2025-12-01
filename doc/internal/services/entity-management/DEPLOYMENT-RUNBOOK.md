# Entity Management Service - Deployment Runbook

**Status**: Active  
**Version**: 1.0.0  
**Last Updated**: 2025-11-29  
**Template**: [DEPLOYMENT-RUNBOOK.md](../../governance/templates/DEPLOYMENT-RUNBOOK.md)

---

## Deployment Overview

**Strategy**: Blue-Green deployment with multi-tenant seam validation  
**Platform**: Kubernetes (GKE)  
**Automation**: GitHub Actions CI/CD pipeline  
**Rollback**: Automated on health check failure

---

## Pre-Deployment Checklist

- [ ] All tests passing (unit, integration, E2E, isolation tests)
- [ ] Code coverage >80%
- [ ] Security scan passing (no critical/high vulnerabilities)
- [ ] Database migrations reviewed and tested
- [ ] Kafka topic `entity-events` exists with 10 partitions
- [ ] PostgreSQL database created with proper user/permissions
- [ ] ConfigMap and Secrets updated in target environment
- [ ] Monitoring dashboards configured
- [ ] Alerts configured and tested
- [ ] Runbook reviewed by team

---

## Deployment Steps

### 1. Build and Test

```bash
# Run full test suite
./mill entity-management.test

# Run isolation tests (critical for multi-tenant)
./mill entity-management.test.only "*IsolationSpec"

# Build Docker image
./mill entity-management.dockerBuild

# Tag image
docker tag entity-management:latest gcr.io/tjmpaas/entity-management:v1.0.0
docker tag entity-management:latest gcr.io/tjmpaas/entity-management:latest

# Push to registry
docker push gcr.io/tjmpaas/entity-management:v1.0.0
docker push gcr.io/tjmpaas/entity-management:latest
```

### 2. Database Migrations

```bash
# Review migrations
ls src/main/resources/db/migration/

# Dry-run migrations (staging)
./scripts/migrate-dry-run.sh staging

# Apply migrations (staging)
./scripts/migrate.sh staging

# Verify migrations
psql -h <db-host> -U entity_mgmt_user -d entity_mgmt_db -c "\d"
```

**Migration Checklist**:
- [ ] Migrations reviewed for tenant isolation (all tables have tenant_id)
- [ ] Indexes on tenant_id columns
- [ ] No data loss in migrations
- [ ] Rollback migrations prepared

### 3. Deploy to Staging

```bash
# Apply Kubernetes manifests (staging)
kubectl apply -f k8s/staging/ --namespace=entity-management-staging

# Wait for deployment
kubectl rollout status deployment/entity-management --namespace=entity-management-staging

# Check pods
kubectl get pods --namespace=entity-management-staging
```

### 4. Smoke Tests (Staging)

```bash
# Health checks
curl https://api-staging.tjmpaas.com/api/v1/health/live
curl https://api-staging.tjmpaas.com/api/v1/health/ready

# Create test tenant
curl -X POST https://api-staging.tjmpaas.com/api/v1/tenants \
  -H "Authorization: Bearer $JWT" \
  -H "X-Tenant-ID: test-tenant-id" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-tenant-id",
    "name": "Test Tenant",
    "subscription_plan": "bronze"
  }'

# Verify event published to Kafka
./scripts/consume-kafka-events.sh staging entity-events

# Delete test tenant
curl -X DELETE https://api-staging.tjmpaas.com/api/v1/tenants/test-tenant-id \
  -H "Authorization: Bearer $JWT" \
  -H "X-Tenant-ID: test-tenant-id"
```

### 5. Multi-Tenant Isolation Validation

**Critical**: Run automated isolation tests against staging environment.

```bash
# Run isolation test suite
./mill entity-management.integrationTest.only "*IsolationSpec"
```

**Tests**:
- [ ] Seam 1: Tenant boundary - no cross-tenant data access
- [ ] Seam 2: Service entitlement - features respect subscription plan
- [ ] Seam 3: Feature limits - quota enforcement working
- [ ] Seam 4: Role permissions - RBAC working correctly

**Manual Verification**:
```bash
# Create two test tenants
TENANT_A="tenant-a-id"
TENANT_B="tenant-b-id"

# Create organization in Tenant A
ORG_A=$(curl -X POST .../tenants/$TENANT_A/organizations -H "X-Tenant-ID: $TENANT_A" ...)

# Attempt to access Tenant A org from Tenant B (should fail 403)
curl -X GET .../organizations/$ORG_A -H "X-Tenant-ID: $TENANT_B" -H "Authorization: Bearer $JWT_TENANT_B"
# Expected: 403 Forbidden

# Verify database isolation
psql -h ... -c "SELECT * FROM organization_view WHERE id = '$ORG_A' AND tenant_id = '$TENANT_B';"
# Expected: 0 rows
```

### 6. Deploy to Production

**Blue-Green Strategy**:

```bash
# Label current deployment as "blue"
kubectl label deployment/entity-management color=blue --namespace=entity-management-prod

# Deploy new version as "green"
kubectl apply -f k8s/prod/deployment-green.yaml --namespace=entity-management-prod

# Wait for green deployment
kubectl rollout status deployment/entity-management-green --namespace=entity-management-prod

# Run smoke tests against green
curl https://entity-management-green.internal/health/ready

# Switch service to green
kubectl patch service entity-management --namespace=entity-management-prod \
  -p '{"spec":{"selector":{"color":"green"}}}'

# Monitor for 15 minutes
./scripts/monitor-deployment.sh prod 15

# If successful, scale down blue
kubectl scale deployment/entity-management-blue --replicas=0 --namespace=entity-management-prod

# If rollback needed
kubectl patch service entity-management --namespace=entity-management-prod \
  -p '{"spec":{"selector":{"color":"blue"}}}'
```

### 7. Post-Deployment Verification

```bash
# Check deployment status
kubectl get deployments --namespace=entity-management-prod

# Check pod health
kubectl get pods --namespace=entity-management-prod

# Check logs
kubectl logs -f deployment/entity-management --namespace=entity-management-prod

# Verify metrics
curl https://api.tjmpaas.com/api/v1/metrics | grep entity_

# Check Grafana dashboards
open https://grafana.tjmpaas.com/d/entity-management-overview

# Verify alerts not firing
open https://alertmanager.tjmpaas.com/#/alerts?filter={service="entity-management"}
```

**Checklist**:
- [ ] All pods running and ready
- [ ] Health checks passing
- [ ] No error spikes in logs
- [ ] Latency within SLA (P95 <200ms queries, <500ms commands)
- [ ] Event publishing working (check Kafka consumer lag)
- [ ] No multi-tenant isolation violations
- [ ] Dashboards showing healthy metrics
- [ ] No critical alerts firing

---

## Rollback Procedure

**Automated Rollback** (triggered by health check failures):
1. Service detects 3 consecutive health check failures
2. Kubernetes automatically switches traffic back to blue deployment
3. Green deployment scaled down
4. Alerts fired to on-call team

**Manual Rollback**:
```bash
# Switch service back to blue
kubectl patch service entity-management --namespace=entity-management-prod \
  -p '{"spec":{"selector":{"color":"blue"}}}'

# Scale down green deployment
kubectl scale deployment/entity-management-green --replicas=0 --namespace=entity-management-prod

# Verify blue deployment healthy
kubectl get pods -l color=blue --namespace=entity-management-prod

# Check logs for issues in green
kubectl logs deployment/entity-management-green --namespace=entity-management-prod --tail=500
```

**Database Rollback**:
```bash
# Rollback migrations (if needed)
./scripts/migrate-rollback.sh prod V001

# Verify database state
psql -h ... -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;"
```

---

## Configuration

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: entity-management-config
  namespace: entity-management-prod
data:
  DATABASE_URL: "jdbc:postgresql://cloudsql-proxy:5432/entity_mgmt_db"
  KAFKA_BROKERS: "kafka-1:9092,kafka-2:9092,kafka-3:9092"
  KAFKA_TOPIC: "entity-events"
  KAFKA_PARTITIONS: "10"
  REDIS_URL: "redis://redis-master:6379"
  LOG_LEVEL: "INFO"
  FEATURE_ORG_ENABLED: "true"
  FEATURE_TEAM_ENABLED: "true"
  RATE_LIMIT_BRONZE: "1000"
  RATE_LIMIT_SILVER: "10000"
  RATE_LIMIT_GOLD: "100000"
```

### Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: entity-management-secrets
  namespace: entity-management-prod
type: Opaque
data:
  DATABASE_PASSWORD: <base64-encoded>
  KAFKA_API_KEY: <base64-encoded>
  KAFKA_API_SECRET: <base64-encoded>
  JWT_PUBLIC_KEY: <base64-encoded>
  REDIS_PASSWORD: <base64-encoded>
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_NAME` | Service identifier | `entity-management-service` |
| `SERVICE_VERSION` | Deployed version | `1.0.0` |
| `ENVIRONMENT` | Deployment environment | `prod` |
| `DATABASE_URL` | PostgreSQL connection | `jdbc:postgresql://...` |
| `KAFKA_BROKERS` | Kafka broker list | `kafka-1:9092,...` |
| `LOG_LEVEL` | Logging level | `INFO` |

---

## Monitoring During Deployment

### Key Metrics to Watch

**Latency**:
- Query P95 latency: <200ms
- Command P95 latency: <500ms
- Event publishing latency: <100ms

**Error Rate**:
- HTTP 5xx errors: <1%
- Command failures: <2%
- Event publishing failures: <0.1%

**Throughput**:
- Requests per second
- Commands per second
- Events published per second

**Actor System**:
- Actor count stable
- Mailbox depth <100
- Actor restart rate <1/minute

### Dashboards

1. **Deployment Dashboard**: Track deployment progress, pod readiness
2. **Service Overview**: Request rate, latency, error rate
3. **Actor System**: Actor count, message throughput, restarts
4. **Per-Tenant**: Tenant-specific metrics (for SLA monitoring)

### Alerts During Deployment

**Suppressed** (during deployment window):
- Instance down alerts (expected during blue-green switch)

**Active** (not suppressed):
- High error rate (>5%)
- Multi-tenant isolation violation
- Database connection failures
- Kafka publishing failures

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> --namespace=entity-management-prod

# Check events
kubectl get events --namespace=entity-management-prod --sort-by=.lastTimestamp

# Common issues:
# - Image pull failure: Verify image exists in registry
# - ConfigMap/Secret missing: kubectl get configmap,secret -n entity-management-prod
# - Resource limits: Check if cluster has capacity
```

### Health Checks Failing

```bash
# Check logs
kubectl logs <pod-name> --namespace=entity-management-prod

# Test health endpoints
kubectl exec -it <pod-name> --namespace=entity-management-prod -- curl localhost:8080/health/ready

# Common issues:
# - Database not reachable
# - Kafka not reachable
# - Actor system not initialized
```

### High Latency

```bash
# Check database query performance
psql -h ... -c "SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# Check actor mailbox depth
kubectl logs <pod-name> | grep "mailbox.*depth"

# Check resource usage
kubectl top pods --namespace=entity-management-prod
```

### Cross-Tenant Access Detected

**Immediate Actions**:
1. Alert security team
2. Review audit logs for affected tenant
3. Identify root cause (code bug vs malicious)
4. If bug: Hotfix and redeploy immediately
5. If malicious: Block user, notify tenant, investigate

```bash
# Query audit logs
psql -h ... -c "SELECT * FROM audit_log WHERE tenant_id = '<affected>' ORDER BY timestamp DESC LIMIT 100;"

# Check application logs
kubectl logs deployment/entity-management | grep "tenant_id.*mismatch"
```

---

## Post-Deployment

### Monitoring Period

**15-Minute Watch**: Monitor dashboards and alerts closely for first 15 minutes.

**2-Hour Observation**: Check metrics hourly for first 2 hours.

**24-Hour Review**: Full review after 24 hours in production.

### Post-Deployment Checklist

- [ ] All metrics within normal ranges
- [ ] No alerts firing
- [ ] Event consumers processing normally (check lag)
- [ ] Customer-reported issues (check support tickets)
- [ ] Performance regression testing passed
- [ ] Deployment documented in changelog
- [ ] Team notified of successful deployment

---

## Related Documentation

- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md)
- [TELEMETRY-SPECIFICATION.md](./TELEMETRY-SPECIFICATION.md)
- [SECURITY-REQUIREMENTS.md](./SECURITY-REQUIREMENTS.md)

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-29 | Initial runbook | Platform Team |
