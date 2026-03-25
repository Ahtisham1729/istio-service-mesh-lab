#!/bin/bash
set -euo pipefail

ISTIO_VERSION="1.24.2"

echo "=== Installing Istio ${ISTIO_VERSION} ==="
echo ""

# Download istioctl if not present
if ! command -v istioctl &> /dev/null; then
    echo "Downloading istioctl..."
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
    sudo cp istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/
    echo "istioctl installed."
fi

# Install Istio with demo profile (includes most features, good for learning)
# Demo profile enables: istiod, istio-ingressgateway, istio-egressgateway
echo ""
echo "Installing Istio with demo profile..."
istioctl install --set profile=demo -y

# Wait for Istio pods
echo ""
echo "Waiting for Istio pods to be ready..."
kubectl -n istio-system wait --for=condition=ready pod --all --timeout=300s

# Create the mesh-lab namespace with auto sidecar injection
echo ""
echo "Creating namespace 'mesh-lab' with Istio sidecar injection..."
kubectl create namespace mesh-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace mesh-lab istio-injection=enabled --overwrite

# Install addons: Kiali, Jaeger, Prometheus, Grafana
echo ""
echo "Installing observability addons..."
ADDONS_DIR="istio-${ISTIO_VERSION}/samples/addons"

if [ -d "$ADDONS_DIR" ]; then
    kubectl apply -f ${ADDONS_DIR}/prometheus.yaml
    kubectl apply -f ${ADDONS_DIR}/grafana.yaml
    kubectl apply -f ${ADDONS_DIR}/jaeger.yaml
    kubectl apply -f ${ADDONS_DIR}/kiali.yaml

    echo "Waiting for addon pods..."
    sleep 10
    kubectl -n istio-system wait --for=condition=ready pod -l app=kiali --timeout=300s
    kubectl -n istio-system wait --for=condition=ready pod -l app=grafana --timeout=300s
else
    echo "WARNING: Addons directory not found at ${ADDONS_DIR}"
    echo "You can install addons manually from: https://istio.io/latest/docs/ops/integrations/"
fi

echo ""
echo "=== Istio installation complete ==="
echo ""
echo "Installed components:"
istioctl version
echo ""
echo "Istio pods:"
kubectl -n istio-system get pods
echo ""
echo "Access dashboards with:"
echo "  Kiali:      istioctl dashboard kiali"
echo "  Grafana:    istioctl dashboard grafana"
echo "  Jaeger:     istioctl dashboard jaeger"
echo "  Prometheus: istioctl dashboard prometheus"
echo ""
echo "Next step: ./scripts/03-deploy-apps.sh"
