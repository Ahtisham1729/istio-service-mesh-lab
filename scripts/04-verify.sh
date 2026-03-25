#!/bin/bash
set -euo pipefail

echo "=== Verifying Istio Service Mesh Lab ==="
echo ""

# 1. Check Istio control plane
echo "--- Istio Control Plane ---"
istioctl version
echo ""

# 2. Check Istio injection
echo "--- Namespace Labels ---"
kubectl get namespace mesh-lab --show-labels
echo ""

# 3. Check pods (should have 2/2 containers = app + sidecar)
echo "--- Pods (expecting 2/2 READY = sidecar injected) ---"
kubectl -n mesh-lab get pods
echo ""

# 4. Verify sidecar injection
echo "--- Sidecar Proxy Status ---"
for pod in $(kubectl -n mesh-lab get pods -o jsonpath='{.items[*].metadata.name}'); do
    containers=$(kubectl -n mesh-lab get pod "$pod" -o jsonpath='{.spec.containers[*].name}')
    echo "  $pod: $containers"
done
echo ""

# 5. Check Istio configs
echo "--- Istio Configuration ---"
echo "Gateways:"
kubectl -n mesh-lab get gateways
echo ""
echo "VirtualServices:"
kubectl -n mesh-lab get virtualservices
echo ""
echo "DestinationRules:"
kubectl -n mesh-lab get destinationrules
echo ""

# 6. Validate Istio config
echo "--- Istio Config Validation ---"
istioctl analyze -n mesh-lab
echo ""

# 7. Test connectivity
echo "--- Testing Connectivity ---"
INGRESS_IP=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
INGRESS_PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' 2>/dev/null || echo "")

if [ -n "$INGRESS_IP" ]; then
    GATEWAY_URL="${INGRESS_IP}"
else
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    GATEWAY_URL="${NODE_IP}:${INGRESS_PORT}"
fi

echo "Gateway URL: http://${GATEWAY_URL}"
echo ""
echo "Sending test request..."
curl -s "http://${GATEWAY_URL}/" | python3 -m json.tool 2>/dev/null || echo "Request failed - check pod logs"

echo ""
echo "=== Verification complete ==="
echo ""
echo "Dashboards:"
echo "  istioctl dashboard kiali"
echo "  istioctl dashboard grafana"
echo "  istioctl dashboard jaeger"
