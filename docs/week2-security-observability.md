# Week 2: Security and Observability Experiments

## Day 8: mTLS

### Experiment 7: Verify mTLS status (before STRICT mode)

```bash
# Check current mTLS status
istioctl x describe pod <frontend-pod-name> -n mesh-lab

# Check if traffic is encrypted in Kiali
# Look for the lock icon on service edges
istioctl dashboard kiali
```

### Experiment 8: Enable STRICT mTLS

```bash
kubectl apply -f k8s/istio/peer-authentication/strict-mtls.yaml

# Verify: try calling a service from a pod WITHOUT a sidecar
# Create a test pod in a namespace without istio injection
kubectl create namespace no-mesh
kubectl run test-client --namespace=no-mesh --image=curlimages/curl --rm -it -- \
  curl -v http://frontend.mesh-lab.svc.cluster.local:8080/health

# Expected: connection refused or reset (no valid mTLS cert)
```

### Experiment 9: Verify certificates

```bash
# Check the certificate chain Istio provisions
istioctl proxy-config secret <frontend-pod-name> -n mesh-lab

# View the actual certificate details
istioctl proxy-config secret <frontend-pod-name> -n mesh-lab -o json | \
  jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | \
  base64 -d | openssl x509 -text -noout
```

## Day 9: Authorization Policies

### Experiment 10: Apply RBAC

```bash
kubectl apply -f k8s/istio/peer-authentication/authz-policy.yaml

# Test: frontend calling order-service should work
curl http://<GATEWAY_URL>/

# Test: try calling order-service directly from backend (should be denied)
kubectl exec -n mesh-lab <backend-pod> -c backend -- \
  curl -s http://order-service.mesh-lab.svc.cluster.local:8080/api/orders

# Expected: RBAC: access denied (if using separate service accounts)
```

## Day 10-11: Observability Deep Dive

### Experiment 11: Kiali service graph

```bash
# Generate traffic first
./scripts/05-load-test.sh

# Open Kiali
istioctl dashboard kiali

# Navigate to: Graph > mesh-lab namespace
# Observe:
# - Service topology
# - Request rates and error rates
# - mTLS indicators
# - Response time distribution
```

### Experiment 12: Distributed tracing with Jaeger

```bash
istioctl dashboard jaeger

# Search for traces:
# - Service: frontend.mesh-lab
# - Look for the full trace: frontend -> backend + frontend -> order-service
# - Compare trace durations with and without fault injection
```

### Experiment 13: Prometheus metrics

Key Istio metrics to explore:

```promql
# Request rate by service
rate(istio_requests_total{namespace="mesh-lab"}[5m])

# Error rate (5xx)
rate(istio_requests_total{namespace="mesh-lab",response_code=~"5.."}[5m])

# P99 latency
histogram_quantile(0.99, rate(istio_request_duration_milliseconds_bucket{namespace="mesh-lab"}[5m]))

# TCP bytes sent
rate(istio_tcp_sent_bytes_total{namespace="mesh-lab"}[5m])
```

### Experiment 14: Grafana dashboards

```bash
istioctl dashboard grafana

# Check built-in Istio dashboards:
# - Istio Mesh Dashboard (overall mesh health)
# - Istio Service Dashboard (per-service metrics)
# - Istio Workload Dashboard (per-pod metrics)
```

## Day 12: Performance Impact

### Experiment 15: Measure Istio overhead

Compare latency with and without the sidecar:

```bash
# With sidecar (normal)
./scripts/05-load-test.sh > results-with-sidecar.txt

# Disable sidecar for frontend temporarily
kubectl -n mesh-lab patch deployment frontend -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"false"}}}}}'
kubectl -n mesh-lab rollout status deployment/frontend

./scripts/05-load-test.sh > results-without-sidecar.txt

# Re-enable sidecar
kubectl -n mesh-lab patch deployment frontend -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"true"}}}}}'

# Compare the two results
diff results-with-sidecar.txt results-without-sidecar.txt
```

## Day 13: Evaluation Document

Use your experiment results to write `docs/istio-evaluation.md` covering:

1. **What Istio provides**: traffic management, security, observability (with your hands-on evidence)
2. **Operational cost**: resource overhead (memory/CPU of sidecars), complexity of CRDs, learning curve
3. **When it makes sense**: team size, number of services, security requirements
4. **When it does not**: small clusters, few services, team unfamiliar with mesh concepts
5. **Recommendation for your team**: based on what you know about the current stack
6. **Alternatives considered**: Linkerd (lighter weight), Cilium service mesh (eBPF-based, no sidecars)
