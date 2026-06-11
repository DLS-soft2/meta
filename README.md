# DLS-2 -- Food Delivery Platform

## Quick Start

**Prerequisites:** Git

```bash
git clone https://github.com/DLS-soft2/meta.git dls-2
cd dls-2
./clone-all.sh
# Open in VS Code:
code dls2-system.code-workspace
```

## System Overview

DLS-2 is a distributed food delivery platform built as a microservice architecture for the "Development of Large Systems" course at KEA Copenhagen. The system handles the full order lifecycle from placement through payment, restaurant preparation, courier assignment, and delivery.

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

### Shared Libraries and Infrastructure

| Library | Stack | Purpose |
|---------|-------|---------|
| auth-lib-python | Python | Shared RBAC library for Python services |
| auth-lib-java | Java | Shared RBAC library for Java services |
| shared-workflows | GitHub Actions | Reusable CI/CD workflows |
| infra | Docker / K8s | Docker Compose, Kubernetes manifests |
| docs | Markdown | System-wide documentation |

## Key Technologies

- Kafka (choreography-based saga)
- Keycloak (OAuth2/OIDC, JWT)
- PostgreSQL, MongoDB, Redis
- Docker Compose (dev), Kubernetes (prod simulation)
- REST + GraphQL APIs

## Organisation

GitHub: <https://github.com/DLS-soft2>
