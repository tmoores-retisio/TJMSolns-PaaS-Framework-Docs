# {Service Name} Deployment Runbook

**Status**: Active Template  
**Authority**: TJMPaaS Official  
**Last Updated**: 2025-11-28  
**Template Version**: 1.0

---

**Instructions**: Copy this template to service repository `docs/DEPLOYMENT-RUNBOOK.md`. This provides comprehensive operational procedures for deploying, maintaining, and troubleshooting the service in production.

---

## Overview

**Service**: {Service Name}  
**Repository**: `TJMSolns-{ServiceName}`  
**Kubernetes Namespace**: `{namespace}`  
**Deployment Type**: {Rolling / Blue-Green / Canary}

## Prerequisites

### Infrastructure Requirements

- Kubernetes cluster (version {X.Y+})
- PostgreSQL {version} (for event store and read models)
- Apache Kafka {version} (for event streaming)
- Container registry access (GCP Artifact Registry / Docker Hub)

### Access Requirements

- `kubectl` access to target cluster
- Container registry credentials
- Database admin credentials (for migrations)
- Kafka admin credentials (for topic creation)

### Configuration Prerequisites

- ConfigMaps created ({list})
- Secrets created ({list})
- Persistent volumes provisioned ({list if stateful})

## Deployment Procedures

### Standard Deployment (Rolling Update)

**When to use**: Normal feature releases, bug fixes, minor version updates

**Steps**:

1. **Build and push container image**
   ```bash
   # Build image
   mill {serviceName}.docker.build
   
   # Tag image
   docker tag {service-name}:latest \
     gcr.io/{project}/{service-name}:v{X.Y.Z}
   
   # Push to registry
   docker push gcr.io/{project}/{service-name}:v{X.Y.Z}
   ```

2. **Run database migrations** (if schema changes)
   ```bash
   # Backup database first
   kubectl exec -n {namespace} {db-pod} -- \
     pg_dump -U {user} {database} > backup-$(date +%Y%m%d).sql
   
   # Apply migrations
   kubectl run flyway-migrate \
     --image=gcr.io/{project}/{service-name}:v{X.Y.Z} \
     --restart=Never \
     --command -- flyway migrate
   
   # Verify migrations
   kubectl logs flyway-migrate
   ```

3. **Update Kubernetes deployment**
   ```bash
   # Update image tag in deployment
   kubectl set image deployment/{service-name} \
     {service-name}=gcr.io/{project}/{service-name}:v{X.Y.Z} \
     -n {namespace}
   
   # Or apply full manifest
   kubectl apply -f k8s/deployment.yaml -n {namespace}
   ```

4. **Monitor rollout**
   ```bash
   # Watch rollout status
   kubectl rollout status deployment/{service-name} -n {namespace}
   
   # Check pod health
   kubectl get pods -n {namespace} -l app={service-name}
   
   # View logs
   kubectl logs -f deployment/{service-name} -n {namespace}
   ```

5. **Verify deployment**
   ```bash
   # Health check
   curl https://{service-url}/api/v1/health
   
   # Readiness check
   curl https://{service-url}/api/v1/ready
   
   # Smoke test key endpoints
   curl -H "X-Tenant-ID: {test-tenant}" \
        -H "Authorization: Bearer {test-jwt}" \
        https://{service-url}/api/v1/{resource}
   ```

6. **Validate multi-tenant isolation**
   ```bash
   # Run isolation test suite
   kubectl run isolation-tests \
     --image=gcr.io/{project}/{service-name}-tests:v{X.Y.Z} \
     --restart=Never \
     --command -- ./run-isolation-tests.sh
   
   # Check results
   kubectl logs isolation-tests
   ```

7. **Update monitoring dashboards**
   - Verify Grafana dashboards showing new version
   - Check Prometheus metrics for new deployment
   - Validate alert rules still active

### Blue-Green Deployment

**When to use**: Major releases, risky changes, zero-downtime requirement

**Steps**:

1. **Deploy green environment** (parallel to blue)
   ```bash
   # Deploy green version with different label
   kubectl apply -f k8s/deployment-green.yaml -n {namespace}
   
   # Wait for green pods ready
   kubectl wait --for=condition=ready pod \
     -l app={service-name},version=green \
     -n {namespace} \
     --timeout=300s
   ```

2. **Smoke test green environment**
   ```bash
   # Port forward to green service
   kubectl port-forward svc/{service-name}-green 8080:8080 -n {namespace}
   
   # Run test suite against localhost:8080
   ./run-tests.sh localhost:8080
   ```

3. **Switch traffic to green**
   ```bash
   # Update service selector to point to green
   kubectl patch service {service-name} -n {namespace} \
     -p '{"spec":{"selector":{"version":"green"}}}'
   
   # Verify traffic switched
   curl https://{service-url}/api/v1/health
   ```

4. **Monitor green environment**
   - Watch metrics for 15-30 minutes
   - Check error rates
   - Verify logs show normal operation

5. **Decommission blue environment** (if green stable)
   ```bash
   # Scale down blue deployment
   kubectl scale deployment/{service-name}-blue --replicas=0 -n {namespace}
   
   # Delete blue deployment after 24 hours
   kubectl delete deployment/{service-name}-blue -n {namespace}
   ```

### Canary Deployment

**When to use**: Gradual rollout, testing with production traffic subset

**Steps**:

1. **Deploy canary with small replica count**
   ```bash
   # Deploy canary (1 replica)
   kubectl apply -f k8s/deployment-canary.yaml -n {namespace}
   
   # Verify canary ready
   kubectl get pods -l app={service-name},version=canary
   ```

2. **Configure traffic split** (e.g., 10% canary, 90% stable)
   ```bash
   # Using Istio VirtualService or similar
   kubectl apply -f k8s/traffic-split-10-90.yaml -n {namespace}
   ```

3. **Monitor canary metrics**
   - Error rate compared to stable
   - Latency compared to stable
   - Resource usage
   - User-reported issues

4. **Gradually increase canary traffic**
   ```bash
   # 25% canary
   kubectl apply -f k8s/traffic-split-25-75.yaml
   
   # Monitor for 30 minutes
   
   # 50% canary
   kubectl apply -f k8s/traffic-split-50-50.yaml
   
   # Monitor for 30 minutes
   
   # 100% canary (promote)
   kubectl apply -f k8s/traffic-split-100-0.yaml
   ```

5. **Promote canary to stable**
   ```bash
   # Update stable deployment to canary version
   kubectl set image deployment/{service-name} \
     {service-name}=gcr.io/{project}/{service-name}:v{X.Y.Z}
   
   # Remove canary deployment
   kubectl delete deployment/{service-name}-canary
   ```

## Rollback Procedures

### Immediate Rollback (Kubernetes)

**When**: Critical bug, service unavailable, data corruption risk

```bash
# Rollback to previous revision
kubectl rollout undo deployment/{service-name} -n {namespace}

# Or rollback to specific revision
kubectl rollout history deployment/{service-name} -n {namespace}
kubectl rollout undo deployment/{service-name} --to-revision={N} -n {namespace}

# Verify rollback
kubectl rollout status deployment/{service-name} -n {namespace}
kubectl get pods -n {namespace} -l app={service-name}
```

### Database Rollback

**When**: Schema migration caused issues

```bash
# Restore from backup
kubectl exec -n {namespace} {db-pod} -- \
  psql -U {user} {database} < backup-{date}.sql

# Or run Flyway undo (if migrations support it)
kubectl run flyway-undo \
  --image=gcr.io/{project}/{service-name}:v{previous} \
  --restart=Never \
  --command -- flyway undo

# Verify schema reverted
kubectl exec -n {namespace} {db-pod} -- \
  psql -U {user} {database} -c '\dt'
```

### Event Store Rollback

**When**: Event schema change caused issues

```bash
# Stop service (prevent more events)
kubectl scale deployment/{service-name} --replicas=0

# Run event migration/repair script
kubectl run event-repair \
  --image=gcr.io/{project}/{service-name}-tools:latest \
  --restart=Never \
  --command -- ./repair-events.sh

# Verify events repaired
kubectl logs event-repair

# Restart service with previous version
kubectl set image deployment/{service-name} \
  {service-name}=gcr.io/{project}/{service-name}:v{previous}
kubectl scale deployment/{service-name} --replicas=3
```

## Configuration Management

### ConfigMaps

**Create ConfigMap**:
```bash
kubectl create configmap {service-name}-config \
  --from-file=config/application.conf \
  -n {namespace}
```

**Update ConfigMap**:
```bash
# Edit ConfigMap
kubectl edit configmap {service-name}-config -n {namespace}

# Restart pods to pick up changes
kubectl rollout restart deployment/{service-name} -n {namespace}
```

**ConfigMap Contents**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {service-name}-config
  namespace: {namespace}
data:
  application.conf: |
    service {
      name = "{service-name}"
      port = 8080
    }
    
    kafka {
      bootstrap-servers = "${KAFKA_BOOTSTRAP_SERVERS}"
      topics {
        events = "{service-name}-events"
      }
    }
    
    akka {
      cluster {
        seed-nodes = [
          "akka://{service-name}@{service-name}-0:2551",
          "akka://{service-name}@{service-name}-1:2551"
        ]
      }
    }
```

### Secrets

**Create Secret**:
```bash
kubectl create secret generic {service-name}-secrets \
  --from-literal=db-password={password} \
  --from-literal=jwt-secret={secret} \
  -n {namespace}
```

**Rotate Secret**:
```bash
# Create new secret version
kubectl create secret generic {service-name}-secrets-v2 \
  --from-literal=db-password={new-password} \
  -n {namespace}

# Update deployment to use new secret
kubectl patch deployment/{service-name} -n {namespace} \
  -p '{"spec":{"template":{"spec":{"volumes":[{"name":"secrets","secret":{"secretName":"{service-name}-secrets-v2"}}]}}}}'

# Delete old secret after verification
kubectl delete secret {service-name}-secrets -n {namespace}
```

## Scaling Operations

### Manual Scaling

**Scale replicas**:
```bash
# Scale up
kubectl scale deployment/{service-name} --replicas=5 -n {namespace}

# Verify scaling
kubectl get pods -n {namespace} -l app={service-name}
```

### Horizontal Pod Autoscaler (HPA)

**Create HPA**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {service-name}-hpa
  namespace: {namespace}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {service-name}
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

**Apply HPA**:
```bash
kubectl apply -f k8s/hpa.yaml -n {namespace}

# Verify HPA
kubectl get hpa -n {namespace}
kubectl describe hpa {service-name}-hpa -n {namespace}
```

### Vertical Scaling (Resource Limits)

**Update resource requests/limits**:
```bash
kubectl set resources deployment/{service-name} -n {namespace} \
  --limits=cpu=2000m,memory=2Gi \
  --requests=cpu=1000m,memory=1Gi

# Restart pods with new resources
kubectl rollout restart deployment/{service-name} -n {namespace}
```

## Monitoring and Alerting

### Health Checks

**Liveness Probe**:
```yaml
livenessProbe:
  httpGet:
    path: /api/v1/health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Readiness Probe**:
```yaml
readinessProbe:
  httpGet:
    path: /api/v1/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

**Manual Health Check**:
```bash
# Check from within cluster
kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -- \
  curl http://{service-name}.{namespace}.svc.cluster.local:8080/api/v1/health

# Check from outside (if exposed)
curl https://{service-url}/api/v1/health
```

### Metrics

**Key Metrics to Monitor**:
- Request rate (requests/sec)
- Error rate (% of requests)
- Latency (p50, p95, p99)
- Actor mailbox size
- Event processing lag (Kafka consumer lag)
- Database connection pool usage
- JVM memory usage
- CPU usage

**Prometheus Queries**:
```promql
# Request rate
rate(http_requests_total{service="{service-name}"}[5m])

# Error rate
rate(http_requests_total{service="{service-name}",status=~"5.."}[5m])
/ rate(http_requests_total{service="{service-name}"}[5m])

# P95 latency
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket{service="{service-name}"}[5m])
)

# Kafka consumer lag
kafka_consumer_lag{service="{service-name}",topic="{service-name}-events"}
```

**Grafana Dashboard**:
- Import dashboard from `k8s/grafana-dashboard.json`
- Panels: Request rate, error rate, latency, resource usage, Kafka lag

### Alerting Rules

**Prometheus Alert Rules**:
```yaml
groups:
- name: {service-name}
  rules:
  - alert: HighErrorRate
    expr: |
      rate(http_requests_total{service="{service-name}",status=~"5.."}[5m])
      / rate(http_requests_total{service="{service-name}"}[5m]) > 0.05
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate in {service-name}"
      description: "Error rate is {{ $value | humanizePercentage }}"
  
  - alert: HighLatency
    expr: |
      histogram_quantile(0.95, 
        rate(http_request_duration_seconds_bucket{service="{service-name}"}[5m])
      ) > 1.0
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High latency in {service-name}"
      description: "P95 latency is {{ $value }}s"
  
  - alert: KafkaConsumerLag
    expr: kafka_consumer_lag{service="{service-name}"} > 1000
    for: 15m
    labels:
      severity: warning
    annotations:
      summary: "Kafka consumer lag high for {service-name}"
      description: "Lag is {{ $value }} messages"
```

## Troubleshooting

### Common Issues

#### Pods Failing to Start

**Symptoms**: Pods in CrashLoopBackOff or Pending state

**Diagnosis**:
```bash
# Check pod status
kubectl get pods -n {namespace} -l app={service-name}

# Describe pod for events
kubectl describe pod {pod-name} -n {namespace}

# Check logs
kubectl logs {pod-name} -n {namespace}
kubectl logs {pod-name} -n {namespace} --previous  # Previous container logs
```

**Common Causes**:
- ConfigMap/Secret not found
- Database connection failed
- Kafka not reachable
- Resource limits too low
- Image pull failure

**Resolution**:
```bash
# Verify ConfigMap exists
kubectl get configmap {service-name}-config -n {namespace}

# Verify Secret exists
kubectl get secret {service-name}-secrets -n {namespace}

# Check database connectivity
kubectl run psql-test --image=postgres:15 --rm -it --restart=Never -- \
  psql -h {db-host} -U {user} -d {database}

# Check Kafka connectivity
kubectl run kafka-test --image=confluentinc/cp-kafka:latest --rm -it --restart=Never -- \
  kafka-broker-api-versions --bootstrap-server {kafka-bootstrap}
```

#### High CPU/Memory Usage

**Symptoms**: Pods being OOMKilled, CPU throttling

**Diagnosis**:
```bash
# Check resource usage
kubectl top pods -n {namespace} -l app={service-name}

# Check resource requests/limits
kubectl describe deployment/{service-name} -n {namespace} | grep -A5 "Limits\|Requests"

# Check JVM heap usage (if Java/Scala)
kubectl exec -n {namespace} {pod-name} -- jstat -gc {pid}
```

**Resolution**:
```bash
# Increase resource limits
kubectl set resources deployment/{service-name} -n {namespace} \
  --limits=cpu=4000m,memory=4Gi \
  --requests=cpu=2000m,memory=2Gi

# Restart pods
kubectl rollout restart deployment/{service-name} -n {namespace}

# Configure JVM memory settings (in ConfigMap or deployment env vars)
# -Xms2g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

#### Event Processing Lag

**Symptoms**: Kafka consumer lag increasing, read models stale

**Diagnosis**:
```bash
# Check Kafka consumer lag
kubectl run kafka-consumer-groups --image=confluentinc/cp-kafka:latest --rm -it --restart=Never -- \
  kafka-consumer-groups --bootstrap-server {kafka-bootstrap} \
  --group {service-name}-consumer --describe

# Check event processing rate
# (Prometheus query)
rate(events_processed_total{service="{service-name}"}[5m])
```

**Resolution**:
```bash
# Scale up consumers (more pods)
kubectl scale deployment/{service-name} --replicas=5 -n {namespace}

# Check for slow projections
kubectl logs -f deployment/{service-name} -n {namespace} | grep "projection"

# Reset consumer offset if corruption suspected
kubectl run kafka-consumer-groups --image=confluentinc/cp-kafka:latest --rm -it --restart=Never -- \
  kafka-consumer-groups --bootstrap-server {kafka-bootstrap} \
  --group {service-name}-consumer --reset-offsets --to-earliest --execute --topic {service-name}-events
```

#### Multi-Tenant Isolation Violation

**Symptoms**: Cross-tenant data leakage detected, isolation tests failing

**Diagnosis**:
```bash
# Run isolation test suite
kubectl run isolation-tests \
  --image=gcr.io/{project}/{service-name}-tests:latest \
  --restart=Never \
  -- ./run-isolation-tests.sh

# Check logs for tenant context errors
kubectl logs deployment/{service-name} -n {namespace} | grep -i "tenant"

# Query database for missing tenant_id filters
kubectl exec -n {namespace} {db-pod} -- \
  psql -U {user} {database} -c "SELECT * FROM {table} WHERE tenant_id IS NULL;"
```

**Resolution**:
```bash
# Immediate: Disable affected feature flag
kubectl patch configmap {service-name}-config -n {namespace} \
  -p '{"data":{"feature.{feature-name}.enabled":"false"}}'
kubectl rollout restart deployment/{service-name} -n {namespace}

# Fix code (ensure all queries include tenant_id filter)
# Redeploy with fix

# Verify isolation restored
kubectl run isolation-tests --restart=Never ...
```

### Logs

**View live logs**:
```bash
# All pods
kubectl logs -f deployment/{service-name} -n {namespace}

# Specific pod
kubectl logs -f {pod-name} -n {namespace}

# Last 100 lines
kubectl logs --tail=100 {pod-name} -n {namespace}

# Logs from previous crashed container
kubectl logs {pod-name} -n {namespace} --previous
```

**Search logs** (if using logging aggregation):
```bash
# Example: Elasticsearch/Kibana
# Query: service:"{service-name}" AND level:ERROR AND tenant_id:"{tenant-id}"
```

### Database Queries

**Connect to database**:
```bash
kubectl exec -it -n {namespace} {db-pod} -- \
  psql -U {user} {database}
```

**Useful queries**:
```sql
-- Check event journal size
SELECT COUNT(*) FROM event_journal;

-- Check recent events
SELECT persistence_id, sequence_number, tags, created_at
FROM event_journal
ORDER BY ordering DESC
LIMIT 100;

-- Check tenant counts
SELECT tenant_id, COUNT(*) as resource_count
FROM {table}
GROUP BY tenant_id;

-- Check for missing tenant_id (isolation bug)
SELECT COUNT(*) FROM {table} WHERE tenant_id IS NULL;

-- Check read model lag
SELECT MAX(sequence_number) as current_seq FROM event_journal WHERE persistence_id = '{entity-type}';
SELECT MAX(sequence_number) as projected_seq FROM read_model_offsets WHERE projection_name = '{projection-name}';
```

## Disaster Recovery

### Backup Procedures

**Database Backup**:
```bash
# Full backup
kubectl exec -n {namespace} {db-pod} -- \
  pg_dump -U {user} {database} | \
  gzip > backups/{service-name}-$(date +%Y%m%d-%H%M%S).sql.gz

# Automated backup (CronJob)
kubectl apply -f k8s/backup-cronjob.yaml
```

**Event Store Backup**:
```bash
# Backup event journal table
kubectl exec -n {namespace} {db-pod} -- \
  pg_dump -U {user} {database} -t event_journal | \
  gzip > backups/{service-name}-events-$(date +%Y%m%d-%H%M%S).sql.gz
```

### Restore Procedures

**Restore Database**:
```bash
# Scale down service (prevent writes)
kubectl scale deployment/{service-name} --replicas=0 -n {namespace}

# Restore from backup
gunzip < backups/{service-name}-{date}.sql.gz | \
  kubectl exec -i -n {namespace} {db-pod} -- \
  psql -U {user} {database}

# Verify restore
kubectl exec -n {namespace} {db-pod} -- \
  psql -U {user} {database} -c "SELECT COUNT(*) FROM {table};"

# Scale up service
kubectl scale deployment/{service-name} --replicas=3 -n {namespace}
```

**Event Replay** (rebuild read models):
```bash
# Truncate read models
kubectl exec -n {namespace} {db-pod} -- \
  psql -U {user} {database} -c "TRUNCATE TABLE {read_model_table};"

# Reset projection offsets
kubectl exec -n {namespace} {db-pod} -- \
  psql -U {user} {database} -c "DELETE FROM read_model_offsets WHERE projection_name = '{projection-name}';"

# Restart service (triggers event replay)
kubectl rollout restart deployment/{service-name} -n {namespace}

# Monitor replay progress
kubectl logs -f deployment/{service-name} -n {namespace} | grep "projection"
```

## Related Documentation

- [SERVICE-ARCHITECTURE.md](./SERVICE-ARCHITECTURE.md) - Architecture details
- [API-SPECIFICATION.md](./API-SPECIFICATION.md) - API reference
- [TELEMETRY-SPECIFICATION.md](./TELEMETRY-SPECIFICATION.md) - Monitoring details

## Revision History

| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial runbook | {Name} |
