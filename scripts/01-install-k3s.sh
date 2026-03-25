#!/bin/bash
set -euo pipefail

echo "=== Installing k3s (lightweight Kubernetes) ==="
echo ""

# k3s with Traefik disabled (Istio will handle ingress)
# --disable=traefik prevents conflict with Istio's ingress gateway
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Wait for k3s to be ready
echo "Waiting for k3s to start..."
sleep 10

# Setup kubeconfig for current user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Verify cluster is running
echo ""
echo "=== Verifying cluster ==="
kubectl cluster-info
kubectl get nodes

echo ""
echo "=== k3s installed successfully ==="
echo ""
echo "Node resources:"
kubectl top nodes 2>/dev/null || echo "(metrics-server not yet ready, this is normal)"
echo ""
echo "Next step: ./scripts/02-install-istio.sh"
