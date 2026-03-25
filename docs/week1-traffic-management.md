# Week 1: Traffic Management Experiments

## Day 3-4: Routing and Canary Deployments

### Experiment 1: Verify traffic splitting

After deploying, send 20 requests and count which backend version responds:

```bash
for i in $(seq 1 20); do
  curl -s http://<GATEWAY_URL>/ | jq -r '.backend.version'
done | sort | uniq -c
```

Expected: roughly 18 hits to v1, 2 to v2 (90/10 split).

### Experiment 2: Shift traffic to v2

Edit `k8s/istio/virtual-services/backend-vs.yaml`:
- Change weights to 50/50, apply, re-run the curl loop
- Change weights to 0/100 (full cutover), apply, re-run

```bash
kubectl apply -f k8s/istio/virtual-services/backend-vs.yaml
```

### Experiment 3: Header-based routing

Add a match rule to route requests with `x-version: v2` header directly to v2:

```yaml
http:
  - match:
      - headers:
          x-version:
            exact: v2
    route:
      - destination:
          host: backend
          subset: v2
  - route:
      - destination:
          host: backend
          subset: v1
        weight: 90
      - destination:
          host: backend
          subset: v2
        weight: 10
```

Test: `curl -H "x-version: v2" http://<GATEWAY_URL>/`

## Day 5-6: Fault Injection and Resilience

### Experiment 4: Inject delays

Uncomment the fault section in `k8s/istio/virtual-services/order-service-vs.yaml`.
Apply and observe:

```bash
kubectl apply -f k8s/istio/virtual-services/order-service-vs.yaml

# Time the requests - some should take ~5s
for i in $(seq 1 10); do
  time curl -s http://<GATEWAY_URL>/ | jq '.order_service_latency_ms'
done
```

### Experiment 5: Inject HTTP errors

With the abort section uncommented, ~10% of requests should return 503:

```bash
for i in $(seq 1 50); do
  curl -s -o /dev/null -w '%{http_code}\n' http://<GATEWAY_URL>/
done | sort | uniq -c
```

### Experiment 6: Timeouts and retries

Add timeout and retry config to the order-service VirtualService.
Observe how Istio retries failed requests automatically.
Check Kiali for retry traffic patterns.

## Key Observations to Document

For each experiment, note:
1. What you configured (the YAML change)
2. What you expected to happen
3. What actually happened (include curl output)
4. What you saw in Kiali/Grafana
5. What would this mean in production?

This becomes your `docs/week1-traffic-management.md` writeup.
