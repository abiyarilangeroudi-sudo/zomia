# Local Development

این سند روش اجرای MVP لوکال را توضیح می‌دهد.

## پیش‌نیازها

- Python 3.12+
- Docker
- Docker Compose

Docker روی ماشین فعلی نصب و تأیید شده است.

## تنظیم محیط

از ریشه پروژه:

```bash
cp .env.example .env
make backend-install
```

## اجرای PostgreSQL

```bash
make db-up
```

این دستور یک container با PostgreSQL 16 بالا می‌آورد.

تنظیمات پیش‌فرض:

- Database: `zomia`
- User: `zomia`
- Port: `5432`

## اجرای Migration

```bash
make migrate
```

این دستور Alembic migrationها را روی PostgreSQL واقعی اجرا می‌کند.

## اجرای Backend

```bash
make backend-run
```

بعد از اجرا:

- API: `http://127.0.0.1:8000`
- OpenAPI Docs: `http://127.0.0.1:8000/docs`
- Health: `http://127.0.0.1:8000/health`

اگر پورت `8000` از قبل اشغال بود، backend را روی پورت دیگری اجرا کنید:

```bash
PORT=8010 make backend-run
```

## Verification

```bash
make verify
```

این دستور تست‌ها، lint و تولید SQL migration را اجرا می‌کند.

## بستن دیتابیس

```bash
make db-down
```
