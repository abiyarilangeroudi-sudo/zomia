# معماری

Zomia باید modular ساخته شود. MVP کوچک شروع می‌شود، اما مرزهای معماری باید از ابتدا با محصول نهایی هماهنگ باشند.

## لایه‌های سیستم

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

- Python 3.12+
- FastAPI
- SQLAlchemy
- PostgreSQL
- Alembic
- Pytest
- JWT Authentication
- OpenAPI Documentation

## Frontend Stack

- Flutter هدف اصلی Frontend است.
- Frontend بعد از تکمیل core backend وارد فاز implementation می‌شود.
- برای validation سریع MVP، اگر لازم شد می‌توان قبل از Flutter یک UI حداقلی موقت ساخت؛ اما frontend اصلی محصول Flutter است.

## Local MVP Stack

برای MVP لوکال فقط این موارد لازم‌اند:

### Backend

- Python 3.12+
- FastAPI
- SQLAlchemy
- Alembic
- PostgreSQL
- Pydantic
- Pytest
- Ruff

### Local Infrastructure

- Docker
- Docker Compose
- PostgreSQL container
- `.env`
- `.env.example`

### Authentication

- JWT
- Password hashing
- Role-based access control

### Frontend

- بعد از تکمیل core backend
- Flutter

## Infrastructure Stack

- Ubuntu 24.04
- Nginx
- Systemd
- GitHub Actions
- Docker برای dependencyهای local مثل PostgreSQL

Nginx، Systemd، GitHub Actions، Certbot، Prometheus و Grafana برای MVP لوکال ضروری نیستند. این‌ها در فاز production readiness وارد می‌شوند.

## مرز ماژول‌ها

### Identity Module

مسئول:

- User
- Role
- Password
- JWT
- Current User Resolution

مسئول نیست:

- Point
- Campaign
- Reward

### Business Module

مسئول:

- Business Profile
- Owner Relationship
- Staff Membership

در Sprint 1 مدل Business داخل Identity قرار گرفته تا سریع‌تر و ساده‌تر شروع کنیم. وقتی محصول بزرگ‌تر شد، می‌توان آن را به ماژول مستقل Business منتقل کرد.

### Loyalty Module

مسئول:

- Mission
- Action
- Points Ledger
- Campaign Evaluation
- Participation

### Reward Module

مسئول:

- Reward Template
- Generated Reward
- Reward Lifecycle

### QR Module

مسئول:

- Customer QR Token
- Scan Resolution
- Staff-facing Scan Response

### Audit Module

مسئول:

- ثبت رویدادهای مهم تجاری
- Action Registered
- Reward Created
- Reward Used

Audit باید append-only باشد.

## اصول Database Design

- Primary Keyها UUID باشند.
- Points Ledger append-only باشد.
- Reward Template از Generated Reward جدا باشد.
- Action Registration باید idempotent باشد.
- Entityهایی که lifecycle دارند باید status صریح داشته باشند.
- enumهای آینده‌نگر فقط وقتی اضافه شوند که implementation زودهنگام تحمیل نکنند.

## اصول API Design

- Router فقط input را validate کند و response بدهد.
- Service منطق تجاری را اجرا کند.
- Repository دسترسی دیتابیس را جدا کند.
- OpenAPI بعد از هر Sprint باید قابل استفاده باشد.
- هر endpoint دارای role protection باید تست داشته باشد.
- قبل از ساخت endpoint جدید، [API Endpoint Inventory](./api/api-endpoint-inventory.md) و OpenAPI بررسی شود.
- اگر endpoint موجود همان role، permission boundary و product meaning را پوشش می‌دهد، endpoint جدید ساخته نشود.
- endpointهای بدون مصرف باید در inventory با وضعیت `deprecated` یا `candidate for removal` مشخص شوند.
