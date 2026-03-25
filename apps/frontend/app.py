"""
Frontend service: receives external traffic, calls backend and order-service.
Intentionally simple - the goal is to learn Istio, not build a complex app.
"""

from flask import Flask, jsonify
import requests
import os
import time

app = Flask(__name__)

BACKEND_URL = os.getenv("BACKEND_URL", "http://backend.mesh-lab.svc.cluster.local:8080")
ORDER_URL = os.getenv("ORDER_URL", "http://order-service.mesh-lab.svc.cluster.local:8080")


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "frontend", "version": "v1"})


@app.route("/")
def index():
    results = {"frontend": "v1"}

    # Call backend
    try:
        start = time.time()
        resp = requests.get(f"{BACKEND_URL}/api/data", timeout=10)
        results["backend"] = resp.json()
        results["backend_latency_ms"] = round((time.time() - start) * 1000, 2)
    except Exception as e:
        results["backend"] = {"error": str(e)}

    # Call order-service
    try:
        start = time.time()
        resp = requests.get(f"{ORDER_URL}/api/orders", timeout=10)
        results["order_service"] = resp.json()
        results["order_service_latency_ms"] = round((time.time() - start) * 1000, 2)
    except Exception as e:
        results["order_service"] = {"error": str(e)}

    return jsonify(results)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
