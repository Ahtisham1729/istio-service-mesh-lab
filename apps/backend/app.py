"""
Backend service: returns data with version info.
Run with VERSION=v1 or VERSION=v2 to simulate different deployments.
Used for traffic splitting and canary deployment demos.
"""

from flask import Flask, jsonify
import os

app = Flask(__name__)
VERSION = os.getenv("VERSION", "v1")


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "backend", "version": VERSION})


@app.route("/api/data")
def get_data():
    if VERSION == "v1":
        return jsonify({
            "service": "backend",
            "version": VERSION,
            "data": {"message": "Response from stable v1", "items": [1, 2, 3]},
        })
    else:
        return jsonify({
            "service": "backend",
            "version": VERSION,
            "data": {"message": "Response from canary v2", "items": [1, 2, 3, 4, 5],
                      "new_feature": True},
        })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
