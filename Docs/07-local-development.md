# Local Development

This document explains how to run the MVP locally.

## Prerequisites

* Python 3.12+
* Docker
* Docker Compose

Docker is already installed and verified on the current machine.

## Environment Setup

From the project root:

```bash
cp .env.example .env
make backend-install
```

## Running PostgreSQL

```bash
make db-up
```

This starts a container running PostgreSQL 16.

Default configuration:

* Database: `zomia`
* User: `zomia`
* Port: `5432`

## Running Migrations

```bash
make migrate
```

This command runs the Alembic migrations against the real PostgreSQL database.

## Running the Backend

```bash
make backend-run
```

After startup:

* API: `http://127.0.0.1:8000`
* OpenAPI Docs: `http://127.0.0.1:8000/docs`
* Health: `http://127.0.0.1:8000/health`

If port `8000` is already in use, run the backend on another port:

```bash
PORT=8010 make backend-run
```

## Verification

```bash
make verify
```

`make verify` runs backend tests and lint, then creates a temporary PostgreSQL database, applies every Alembic migration from base to head, verifies the head revision, and removes the temporary database. It never uses the application database for migration verification and refuses to run with `APP_ENV=production`.

This command verifies the tests, linting, and actual migration execution against a temporary database.

## Demo / QA Seed

If you do not have an active Reward available for manual testing, run the local QA seed:

```bash
cd backend
.venv/bin/python -m app.devtools.seed_reward_use_demo
```

This creates a fresh scenario in the local database for testing `Use Reward` and prints the required credentials to the console.

This seed is not intended for production.

## Running the Flutter Frontend

From the frontend directory:

```bash
cd frontend
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

After startup:

* Frontend: `http://127.0.0.1:8080`
* The Flutter version is displayed on the Login page

## Stopping the Database

```bash
make db-down
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
