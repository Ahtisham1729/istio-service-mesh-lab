#!/bin/bash
set -euo pipefail

echo "=== Tearing down Istio Service Mesh Lab ==="
echo ""

read -p "This will remove all lab resources. Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove application resources
echo "Removing application resources..."
kubectl delete namespace mesh-lab --ignore-not-found

# Remove Istio
echo "Removing Istio..."
istioctl uninstall --purge -y
kubectl delete namespace istio-system --ignore-not-found

# Optionally remove k3s
read -p "Also uninstall k3s? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing k3s..."
    /usr/local/bin/k3s-uninstall.sh
    echo "k3s removed."
fi

echo ""
echo "=== Teardown complete ==="
