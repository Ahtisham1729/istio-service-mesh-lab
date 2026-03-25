#!/bin/bash
set -euo pipefail

echo "=== Building and deploying sample applications ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Build container images locally using k3s's containerd
# k3s uses containerd, so we import images via k3s ctr
echo "Building container images..."

# Build with docker, then import to k3s
cd "$PROJECT_ROOT/apps/frontend"
docker build -t frontend:local .
docker save frontend:local | sudo k3s ctr images import -

cd "$PROJECT_ROOT/apps/backend"
docker build -t backend:local .
docker save backend:local | sudo k3s ctr images import -

cd "$PROJECT_ROOT/apps/order-service"
docker build -t order-service:local .
docker save order-service:local | sudo k3s ctr images import -

echo ""
echo "Images imported into k3s:"
sudo k3s ctr images ls | grep "local"

# Deploy base Kubernetes resources
echo ""
echo "Deploying base resources (Deployments + Services)..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/deployments.yaml"

# Wait for pods to be ready (with sidecars)
echo ""
echo "Waiting for pods to be ready (this may take a minute for sidecar injection)..."
sleep 10
kubectl -n mesh-lab wait --for=condition=ready pod --all --timeout=120s

# Deploy Istio Gateway
echo ""
echo "Deploying Istio Gateway..."
kubectl apply -f "$PROJECT_ROOT/k8s/istio/gateway/gateway.yaml"

# Deploy VirtualServices
echo ""
echo "Deploying VirtualServices..."
kubectl apply -f "$PROJECT_ROOT/k8s/istio/virtual-services/frontend-vs.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/istio/virtual-services/backend-vs.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/istio/virtual-services/order-service-vs.yaml"

# Deploy DestinationRules
echo ""
echo "Deploying DestinationRules..."
kubectl apply -f "$PROJECT_ROOT/k8s/istio/destination-rules/backend-dr.yaml"

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Pods:"
kubectl -n mesh-lab get pods -o wide
echo ""
echo "Services:"
kubectl -n mesh-lab get svc
echo ""

# Get ingress gateway URL
INGRESS_IP=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
INGRESS_PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' 2>/dev/null || echo "")

if [ -n "$INGRESS_IP" ]; then
    echo "Access the app at: http://${INGRESS_IP}"
else
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo "Access the app at: http://${NODE_IP}:${INGRESS_PORT}"
fi

echo ""
echo "Test with: curl http://<INGRESS_URL>/"
echo ""
echo "Next step: ./scripts/04-verify.sh"
