# Sprint 1: Identity Engine

## چه چیزی ساخته می‌شود

Sprint 1 پایه authentication و role management را می‌سازد؛ چیزی که همه workflowهای بعدی Zomia به آن وابسته‌اند.

شامل:

- ثبت‌نام Customer
- ثبت‌نام Owner همراه با ساخت اولین Business
- ساخت Staff توسط Owner
- JWT Authentication
- Role-based access control
- Migration اولیه دیتابیس
- تست‌های API برای workflow هویت

## معماری

Backend با FastAPI و ساختار modular شروع شده است:

- `core`: تنظیمات، امنیت، دیتابیس
- `modules/identity/models.py`: مدل‌های SQLAlchemy
- `modules/identity/repository.py`: دسترسی به دیتابیس
- `modules/identity/service.py`: منطق تجاری
- `modules/identity/router.py`: قراردادهای API
- `modules/identity/dependencies.py`: authentication و dependency wiring

Routerها نباید منطق تجاری داشته باشند. آن‌ها input را validate می‌کنند، Service را صدا می‌زنند و response model برمی‌گردانند.

## Database Schema

### users

- `id`
- `email`
- `phone`
- `password_hash`
- `full_name`
- `role`
- `is_active`
- `created_at`
- `updated_at`

### businesses

- `id`
- `owner_id`
- `name`
- `legal_name`
- `slug`
- `category`
- `public_email`
- `public_phone`
- `website_url`
- `address_line1`
- `address_line2`
- `city`
- `region`
- `postal_code`
- `country_code`
- `timezone`
- `currency_code`
- `status`
- `created_at`
- `updated_at`

### staff_members

- `id`
- `business_id`
- `user_id`
- `is_active`
- `created_at`
- `updated_at`

## API Contracts

- `GET /health`
- `POST /api/v1/auth/register/customer`
- `POST /api/v1/auth/register/owner`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `POST /api/v1/owner/businesses`
- `GET /api/v1/owner/businesses`
- `POST /api/v1/owner/staff`
- `GET /api/v1/owner/staff`

## تست‌ها

تست‌های Sprint 1 این موارد را پوشش می‌دهند:

- ثبت‌نام Customer، login و گرفتن profile
- ثبت‌نام Owner، ساخت Business و ساخت Staff
- جلوگیری از دسترسی Customer به APIهای مخصوص Owner

## Migration

Migration اولیه:

- `backend/alembic/versions/0001_identity_engine.py`

## Checklist

- [x] ساخت ساختار backend
- [x] ساخت FastAPI app factory
- [x] تنظیم SQLAlchemy base و session
- [x] password hashing
- [x] JWT creation و verification
- [x] مدل‌های User، Business و StaffMember
- [x] Repository layer
- [x] Service layer
- [x] API router
- [x] Alembic migration
- [x] API tests
- [x] نصب dependencyها
- [x] اجرای تست‌ها
- [x] اجرای lint
- [x] تولید SQL مخصوص PostgreSQL از migration
- [x] بررسی تولید OpenAPI schema
- [x] ساخت Docker Compose برای PostgreSQL
- [x] ساخت `.env.example`
- [x] ساخت Makefile برای اجرای دستورهای تکراری
- [x] اجرای Alembic migration روی PostgreSQL واقعی
- [x] اجرای backend با PostgreSQL واقعی
- [x] Smoke test زنده Sprint 1 با HTTP
- [x] ثبت Sprint 1 به عنوان baseline امن پروژه

## Verification Notes

- Tests: `3 passed`
- Lint: `All checks passed`
- OpenAPI: endpointهای Sprint 1 را درست تولید می‌کند
- Migration: روی PostgreSQL واقعی اجرا شد
- Local DB: PostgreSQL 16 با Docker Compose اجرا شد
- Live API: روی پورت `8010` smoke test شد، چون پورت `8000` از قبل توسط یک سرویس دیگر اشغال بود
- Live workflow: Owner registration، login، create business، create staff و customer registration موفق بود
- Live database counts بعد از smoke test: `3 users`, `2 businesses`, `1 staff_members`
- Git: baseline commit ساخته شد
