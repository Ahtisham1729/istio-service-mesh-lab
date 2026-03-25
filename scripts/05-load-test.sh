#!/bin/bash
set -euo pipefail

echo "=== Load Testing the Mesh ==="
echo ""
echo "This script sends repeated requests to observe traffic patterns in Kiali"
echo "and measure latency with/without fault injection."
echo ""

# Get gateway URL
INGRESS_IP=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
INGRESS_PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' 2>/dev/null || echo "")

if [ -n "$INGRESS_IP" ]; then
    GATEWAY_URL="http://${INGRESS_IP}"
else
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    GATEWAY_URL="http://${NODE_IP}:${INGRESS_PORT}"
fi

echo "Target: ${GATEWAY_URL}"
echo ""

# Check if 'hey' is installed, otherwise use curl loop
if command -v hey &> /dev/null; then
    echo "Using 'hey' for load testing..."
    echo ""

    echo "--- Baseline: 200 requests, 10 concurrent ---"
    hey -n 200 -c 10 "${GATEWAY_URL}/"

    echo ""
    echo "--- Sustained: 30 seconds, 5 concurrent ---"
    hey -z 30s -c 5 "${GATEWAY_URL}/"
else
    echo "'hey' not installed. Install with: go install github.com/rakyll/hey@latest"
    echo "Falling back to curl loop..."
    echo ""

    TOTAL=100
    SUCCESS=0
    FAIL=0
    TOTAL_TIME=0

    for i in $(seq 1 $TOTAL); do
        START=$(date +%s%N)
        HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "${GATEWAY_URL}/" --max-time 15 2>/dev/null || echo "000")
        END=$(date +%s%N)
        ELAPSED=$(( (END - START) / 1000000 ))
        TOTAL_TIME=$((TOTAL_TIME + ELAPSED))

        if [ "$HTTP_CODE" = "200" ]; then
            SUCCESS=$((SUCCESS + 1))
        else
            FAIL=$((FAIL + 1))
        fi

        # Progress every 10 requests
        if [ $((i % 10)) -eq 0 ]; then
            echo "  [$i/$TOTAL] Last: ${HTTP_CODE} ${ELAPSED}ms | OK: $SUCCESS Fail: $FAIL"
        fi
    done

    AVG=$((TOTAL_TIME / TOTAL))
    echo ""
    echo "=== Results ==="
    echo "Total:    $TOTAL requests"
    echo "Success:  $SUCCESS"
    echo "Failed:   $FAIL"
    echo "Avg time: ${AVG}ms"
fi

echo ""
echo "Now check Kiali for traffic visualization: istioctl dashboard kiali"
echo "Check Grafana for metrics: istioctl dashboard grafana"
