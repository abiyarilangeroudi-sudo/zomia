# Decision 0002: تکنولوژی‌های MVP لوکال

## وضعیت

Zomia فعلاً یک پروژه local MVP است. بنابراین نباید از ابتدا با ابزارهای production مثل Nginx، Systemd، CI/CD کامل، monitoring و server hardening سنگین شود.

از طرف دیگر، MVP باید با دیتابیس واقعی و معماری قابل ادامه ساخته شود؛ بنابراین SQLite برای مسیر اصلی کافی نیست.

## تصمیم

برای MVP لوکال از stack زیر استفاده می‌کنیم:

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

- Frontend بعد از تکمیل core backend شروع می‌شود.
- Frontend اصلی با Flutter ساخته می‌شود.

## فعلاً استفاده نمی‌کنیم

این موارد برای MVP لوکال لازم نیستند:

- Nginx
- Systemd
- GitHub Actions کامل
- Certbot
- UFW
- Prometheus
- Grafana
- OAuth
- Admin panel کامل

## دلیل

- Docker Compose محیط PostgreSQL را قابل تکرار می‌کند.
- FastAPI و OpenAPI اجازه می‌دهند قبل از Frontend، workflow را با API verify کنیم.
- Flutter مناسب محصول نهایی است، اما شروع زودهنگام آن قبل از stable شدن core backend ریسک دوباره‌کاری را بالا می‌برد.

## پیامدها

- Sprint 1 با Docker Compose و PostgreSQL واقعی بسته شده است.
- قدم بعدی طراحی و اجرای Sprint 2 است.
- Flutter تا بعد از core backend وارد implementation نمی‌شود.
- تمام Sprintهای backend باید تست و migration قابل اجرا داشته باشند.

## وضعیت اجرا

- Docker Compose و `.env.example` اضافه شده‌اند.
- Docker روی ماشین فعلی نصب و تأیید شده است.
- PostgreSQL با Docker Compose اجرا شده است.
- Migration اولیه روی PostgreSQL واقعی اجرا شده است.
