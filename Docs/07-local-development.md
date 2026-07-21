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

`make verify` runs backend tests and lint, then creates a temporary PostgreSQL
database, applies every Alembic migration from base to head, verifies the head
revision, and removes the temporary database. It never uses the application
database for migration verification and refuses to run with `APP_ENV=production`.

این دستور تست‌ها، lint و اجرای واقعی migrationها روی دیتابیس موقت را بررسی می‌کند.

## Demo / QA Seed

اگر برای تست دستی Reward فعال ندارید، seed مخصوص local QA را اجرا کنید:

```bash
cd backend
.venv/bin/python -m app.devtools.seed_reward_use_demo
```

این دستور در دیتابیس local یک سناریوی تازه برای تست `Use Reward` می‌سازد و credentialهای لازم را در خروجی چاپ می‌کند.

این seed برای production نیست.

## اجرای Flutter Frontend

از ریشه frontend:

```bash
cd frontend
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

بعد از اجرا:

- Frontend: `http://127.0.0.1:8080`
- نسخه Flutter در صفحه Login نمایش داده می‌شود

## بستن دیتابیس

```bash
make db-down
```
