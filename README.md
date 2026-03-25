# Istio Service Mesh Lab

A hands-on exploration of Istio service mesh concepts using a multi-service microservices application on a local k3s Kubernetes cluster. Covers traffic management, security (mTLS), and observability.

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │              k3s Cluster                    │
                    │                                             │
  Client ──────►   │  Istio Ingress    ┌──────────┐              │
                    │  Gateway ────────►│ frontend │              │
                    │                   │ (v1)     │              │
                    │                   └────┬─────┘              │
                    │                        │                    │
                    │              ┌─────────┴──────────┐        │
                    │              ▼                     ▼        │
                    │        ┌──────────┐        ┌────────────┐  │
                    │        │ backend  │        │ order-svc   │  │
                    │        │ (v1, v2) │        │ (v1)        │  │
                    │        └──────────┘        └─────────────┘  │
                    │                                             │
                    │   ┌─────────┐  ┌───────┐  ┌───────────┐   │
                    │   │ Kiali   │  │Jaeger │  │ Prometheus │   │
                    │   │         │  │       │  │ + Grafana  │   │
                    │   └─────────┘  └───────┘  └───────────┘   │
                    └─────────────────────────────────────────────┘
```

**Three simple services** that communicate over HTTP:
- **frontend**: Receives external traffic, calls backend and order-service
- **backend** (v1 + v2): Returns data; two versions for canary/traffic splitting demos
- **order-service**: Simulates an order API; used for fault injection and timeout demos

## Prerequisites

- Linux or macOS (WSL2 works on Windows)
- Docker installed
- `kubectl` installed
- `istioctl` installed
- ~8 GB RAM free

## Quick Start

```bash
# 1. Install k3s (lightweight Kubernetes)
./scripts/01-install-k3s.sh

# 2. Install Istio + addons (Kiali, Jaeger, Prometheus, Grafana)
./scripts/02-install-istio.sh

# 3. Deploy the sample applications
./scripts/03-deploy-apps.sh

# 4. Verify everything is running
./scripts/04-verify.sh
```

## Two-Week Project Plan

### Week 1: Foundation + Traffic Management

| Day | Focus | Deliverable |
|-----|-------|-------------|
| 1-2 | Setup k3s, install Istio, deploy sample apps | Working cluster with sidecar injection |
| 3 | Istio Gateway + VirtualService basics | External traffic reaching frontend |
| 4 | Traffic splitting: route 90/10 between backend v1/v2 | Canary deployment working |
| 5 | Fault injection: inject 5s delay + 503 errors into order-service | Resilience testing demo |
| 6 | Timeouts + retries: configure timeout policies | Graceful degradation |
| 7 | Review + document Week 1 learnings | `docs/week1-traffic-management.md` |

### Week 2: Security + Observability + Evaluation

| Day | Focus | Deliverable |
|-----|-------|-------------|
| 8 | mTLS: enable STRICT mode, verify with Kiali | Encrypted service-to-service traffic |
| 9 | Authorization policies: restrict who can call order-service | RBAC between services |
| 10 | Observability: Kiali service graph, Jaeger tracing | Distributed traces visualized |
| 11 | Prometheus metrics + Grafana dashboards for Istio | Custom dashboard for mesh metrics |
| 12 | Load testing with `hey` or `k6`, observe mesh behavior | Performance baseline with/without mesh |
| 13 | Write evaluation doc: "Should we adopt Istio?" | `docs/istio-evaluation.md` |
| 14 | Polish repo, clean up README, final review | Portfolio-ready repo |

## Repository Structure

```
.
├── README.md
├── apps/
│   ├── frontend/           # Simple Go/Python HTTP service
│   ├── backend/            # Two versions (v1, v2) for traffic splitting
│   └── order-service/      # Target for fault injection demos
├── k8s/
│   ├── base/               # Deployments, Services, Namespaces
│   └── istio/
│       ├── gateway/            # Istio Gateway + ingress config
│       ├── virtual-services/   # Routing rules, traffic splits
│       ├── destination-rules/  # Subsets, load balancing, circuit breaking
│       ├── peer-authentication/ # mTLS policies
│       └── telemetry/          # Telemetry configuration
├── observability/
│   ├── prometheus/         # Custom scrape configs if needed
│   ├── grafana/            # Dashboard JSON exports
│   └── kiali/              # Kiali config overrides
├── scripts/                # Setup and teardown automation
└── docs/
    ├── week1-traffic-management.md
    ├── week2-security-observability.md
    └── istio-evaluation.md
```

## Key Concepts Covered

- **Traffic Management**: VirtualServices, DestinationRules, traffic splitting, canary deployments, fault injection, timeouts, retries
- **Security**: Mutual TLS (mTLS), PeerAuthentication, AuthorizationPolicy, RBAC between services
- **Observability**: Kiali service graph, Jaeger distributed tracing, Prometheus metrics, Grafana dashboards, Envoy access logs

## What This Is NOT

This is not a production Istio deployment. It is a learning lab designed to explore service mesh concepts hands-on, understand the operational overhead Istio introduces, and form an informed opinion on whether a service mesh is appropriate for a given Kubernetes platform.

## License

MIT
