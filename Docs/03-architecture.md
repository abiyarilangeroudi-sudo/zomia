# Architecture

Zomia should be built as a modular system. The MVP starts small, but the architectural boundaries must be aligned with the final product from the beginning.

## System Layers

```text
Presentation Layer
  Customer App / Staff Panel / Owner Panel

API Layer
  FastAPI Routers

Application Layer
  Services and Workflow Orchestration

Domain Layer
  Identity / Business / Loyalty / Rewards / QR / Audit

Persistence Layer
  PostgreSQL via SQLAlchemy

Operations Layer
  Alembic / Docker / Nginx / Systemd / GitHub Actions
```

## Backend Stack

* Python 3.12+
* FastAPI
* SQLAlchemy
* PostgreSQL
* Alembic
* Pytest
* JWT Authentication
* OpenAPI Documentation

## Frontend Stack

* Flutter is the primary frontend target.
* Frontend implementation begins after the core backend is completed.
* For rapid MVP validation, a minimal temporary UI may be built before Flutter if necessary; however, Flutter is the primary product frontend.

## Local MVP Stack

Only the following components are required for the local MVP:

### Backend

* Python 3.12+
* FastAPI
* SQLAlchemy
* Alembic
* PostgreSQL
* Pydantic
* Pytest
* Ruff

### Local Infrastructure

* Docker
* Docker Compose
* PostgreSQL container
* `.env`
* `.env.example`

### Authentication

* JWT
* Password hashing
* Role-based access control

### Frontend

* After the core backend is completed
* Flutter

## Infrastructure Stack

* Ubuntu 24.04
* Nginx
* Systemd
* GitHub Actions
* Docker for local dependencies such as PostgreSQL

Nginx, Systemd, GitHub Actions, Certbot, Prometheus, and Grafana are not required for the local MVP. They will be introduced during the production-readiness phase.

## Module Boundaries

### Identity Module

Responsible for:

* User
* Role
* Password
* JWT
* Current User Resolution

Not responsible for:

* Point
* Campaign
* Reward

### Business Module

Responsible for:

* Business Profile
* Owner Relationship
* Staff Membership

In Sprint 1, the Business model was placed inside Identity to allow for a faster and simpler start. As the product grows, it can be moved into an independent Business module.

### Loyalty Module

Responsible for:

* Mission
* Action
* Points Ledger
* Campaign Evaluation
* Participation

### Reward Module

Responsible for:

* Reward Template
* Generated Reward
* Reward Lifecycle

### QR Module

Responsible for:

* Customer QR Token
* Scan Resolution
* Staff-facing Scan Response

### Audit Module

Responsible for:

* Recording important business events
* Action Registered
* Reward Created
* Reward Used

Audit must be append-only.

## Database Design Principles

* Primary Keys should use UUIDs.
* The Points Ledger must be append-only.
* Reward Template must be separate from Generated Reward.
* Action Registration must be idempotent.
* Entities with a lifecycle must have an explicit status.
* Future-oriented enums should only be added when they do not impose premature implementation complexity.

## API Design Principles

* The Router should only validate input and return the response.
* The Service should execute business logic.
* Repository access to the database should be kept separate.
* OpenAPI must remain usable after every Sprint.
* Every endpoint with role protection must have tests.
* Before creating a new endpoint, review the [API Endpoint Inventory](./api/api-endpoint-inventory.md) and OpenAPI.
* If an existing endpoint already covers the same role, permission boundary, and product meaning, a new endpoint should not be created.
* Unused endpoints must be marked in the inventory as `deprecated` or `candidate for removal`.
