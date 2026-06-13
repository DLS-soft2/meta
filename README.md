# DLS-2 -- Food Delivery Platform

## System Overview

DLS-2 is a distributed food delivery platform built as a microservice architecture. The system handles the full order lifecycle from placement through payment, restaurant preparation, courier assignment, and delivery.

## Architecture

### Services

| Service | Stack | Purpose |
|---------|-------|---------|
| api-gateway | Python / FastAPI | JWT authentication, request routing, reverse proxy |
| order-service | Python / FastAPI | Order lifecycle, saga state management |
| payment-service | Python / FastAPI | Payment processing via Kafka events |
| restaurant-service | Java / Spring Boot | Restaurant menus, hours, order acceptance |
| courier-service | Java / Spring Boot | Courier assignment and delivery tracking |
| notification-service | Python / FastAPI | Real-time notifications via WebSocket |
| user-service | Python / FastAPI | User profiles, GraphQL API |
| ai-service | Python / FastAPI | AI-powered courier scoring and ETA |
| frontend | React / TypeScript / Vite | Customer-facing web application (REST + GraphQL) |

### Shared Libraries and Infrastructure

| Library | Stack | Purpose |
|---------|-------|---------|
| auth-lib-python | Python | Shared RBAC library for Python services |
| auth-lib-java | Java | Shared RBAC library for Java services |
| shared-workflows | GitHub Actions | Reusable CI/CD workflows |
| infra | Docker / K8s | Docker Compose, Kubernetes manifests |
| docs | Markdown | System-wide documentation |

## Quick Start

**Prerequisites:** Git

```bash
git clone https://github.com/DLS-soft2/meta.git dls-2
cd dls-2
./clone-all.sh
# Open in VS Code:
code dls2-system.code-workspace
```

## Prerequisites

| Tool | Required for |
|------|-------------|
| Docker + Docker Compose | Running the full stack |
| Git | Cloning the repositories |

Python, Java, and Node.js are **not** needed to run the containerised stack — only for local non-container development. If you develop Python services outside Docker, run `alembic upgrade head` to create the database schema (the Docker stack handles migrations automatically).

## Run the Full Stack

```bash
# From the workspace root (the directory containing all service repos + infra/)
docker compose -f infra/docker/docker-compose.yaml up --build
```

The main compose file automatically includes `docker-compose.kafka.yaml`, so a single command starts everything: databases, Kafka, Keycloak, Ollama, and all application services.

> **First run** pulls the Ollama model (~2.5 GB) and builds all images — expect 5-10 minutes.

### Service URLs

| Service | URL |
|---------|-----|
| Frontend | <http://localhost:3000> |
| API Gateway | <http://localhost:8000> |
| Keycloak Admin | <http://localhost:8080> (user: `admin`, password: `admin`) |
| Kafka UI | <http://localhost:9080> |
| Order Service | <http://localhost:8001> |
| Payment Service | <http://localhost:8002> |
| Restaurant Service | <http://localhost:8003> |
| Courier Service | <http://localhost:8004> |
| Notification Service | <http://localhost:8005> |
| AI Service | <http://localhost:8006> |
| User Service | <http://localhost:8007> |

## Run on Kubernetes (Production Simulation)

The K8s stack targets **Minikube** and deploys everything into a `dls` namespace.

### K8s Prerequisites

| Tool | Install |
|------|---------|
| [Minikube](https://minikube.sigs.k8s.io/docs/start/) | `minikube version` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `kubectl version --client` |
| [Helm](https://helm.sh/docs/intro/install/) | `helm version` (used by KEDA + monitoring installs) |
| [Docker](https://docs.docker.com/get-docker/) | `docker --version` (Minikube driver) |

GHCR container packages are **public**. The 8 backend Deployment manifests use `imagePullPolicy: IfNotPresent`, so Kubernetes automatically pulls the `:latest` images from `ghcr.io/dls-soft2/`. The frontend is the only image built locally (see below).

### Start Cluster and Deploy

```bash
# 1. Start Minikube (minimum: 8 CPU, 16 GB RAM, 40 GB disk)
minikube start --cpus=8 --memory=16384 --driver=docker --disk-size=40g

# 2. Deploy everything (namespace, infra, Keycloak, services, KEDA, monitoring)
./infra/k8s/deploy.sh
```

`deploy.sh` builds the **frontend** image locally inside Minikube's Docker daemon (because it needs the Minikube IP baked into `VITE_KEYCLOAK_URL`, and these are not runtime envs).

> **Optional — local backend builds:** If you need to test locally-modified or uncommitted service code (or work fully offline), you can build individual backend images inside Minikube before running `deploy.sh`. Because the manifests use `imagePullPolicy: IfNotPresent`, a locally-built image takes precedence over the remote one.
>
> ```bash
> eval $(minikube docker-env)
> docker build -t ghcr.io/dls-soft2/order-service:latest order-service/
> # … repeat for any services you've changed locally
> ./infra/k8s/deploy.sh
> ```

`deploy.sh` checks prerequisites, creates the namespace and secrets, deploys infrastructure pods (Postgres, MongoDB, Redis, Kafka, Ollama), waits for readiness, deploys Keycloak, then all 9 application services, installs KEDA and Prometheus/Grafana via Helm, and prints access URLs.

> **Google OAuth:** If `infra/docker/.env` contains `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`, the deploy script patches them into the K8s secret. Without them, Google login is disabled.

### Access Points

`deploy.sh` automatically starts a port-forward for the frontend. Keycloak JS requires the Web Crypto API, which is only available on `https://` or `localhost` — so the frontend must be accessed via `localhost`, not the Minikube IP.

| Service | URL | Notes |
|---------|-----|-------|
| Frontend | `http://localhost:3000` | Port-forwarded by `deploy.sh` |
| Keycloak | `http://<MINIKUBE_IP>:30080` | `minikube ip` for the IP |
| API Gateway | `http://<MINIKUBE_IP>:30000` | |
| Grafana | `http://<MINIKUBE_IP>:30030` | user: `admin`, password: `admin` |

### Test Users

| Username | Password | Role | Notes |
|----------|----------|------|-------|
| `testuser` | `password` | customer | Places orders |
| `testcourier` | `password` | courier | Linked to courier "Ox" |
| `testrestaurant` | `password` | restaurant | |
| `courier-dls` | `pass` | courier | Linked to courier "DLS" |
| `courier-flash` | `pass` | courier | Linked to courier "Flash" |
| `restaurant-baan` | `pass` | restaurant | Linked to "Baan Thai Kitchen" |
| `restaurant-sakura` | `pass` | restaurant | Linked to "Sakura Sushi" |

### Demo: Full Saga Flow

1. Log in as `testuser` / `password` (customer) and place an order at one of the seeded restaurants (e.g. **Pops Pizza** or **Baan Pad Thai**)
2. Payment is processed automatically (PENDING → PAID)
3. Log in as the **restaurant owner** for that restaurant and **accept** the order (PAID → PREPARING):
   - Pops Pizza → `testrestaurant` / `password`
   - Baan Pad Thai → `restaurant-baan` / `pass`
   - Sakura Sushi → `restaurant-sakura` / `pass`
4. Courier is assigned automatically by the AI-service (PREPARING → OUT_FOR_DELIVERY) — note the courier name shown (e.g. "Ox", "Flash")
5. Log in as the **assigned courier** and **mark delivered** (OUT_FOR_DELIVERY → DELIVERED):
   - Ox → `testcourier` / `password`
   - DLS → `courier-dls` / `pass`
   - Flash → `courier-flash` / `pass`
   - Turbo → `courier-turbo` / `pass`
   - Blaze → `courier-blaze` / `pass`
   - Dash → `courier-dash` / `pass`

All status transitions are visible in real-time via WebSocket notifications in the frontend.

### Validate and Teardown

```bash
# Check all pods are Running + test HTTP connectivity
./infra/k8s/validate.sh

# Remove everything (dls namespace, KEDA, monitoring)
./infra/k8s/teardown.sh
```

## Organisation

GitHub: <https://github.com/DLS-soft2>
