"""
Order service: simulates an order API.
Target for fault injection, timeout, and retry demos.
"""

from flask import Flask, jsonify
import os

app = Flask(__name__)
VERSION = os.getenv("VERSION", "v1")


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "order-service", "version": VERSION})


@app.route("/api/orders")
def get_orders():
    return jsonify({
        "service": "order-service",
        "version": VERSION,
        "orders": [
            {"id": "ord-001", "item": "Widget A", "status": "shipped"},
            {"id": "ord-002", "item": "Widget B", "status": "processing"},
        ],
    })


@app.route("/api/orders/<order_id>")
def get_order(order_id):
    return jsonify({
        "service": "order-service",
        "version": VERSION,
        "order": {"id": order_id, "item": "Widget A", "status": "shipped"},
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
