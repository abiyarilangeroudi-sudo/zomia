.PHONY: backend-install backend-test backend-lint backend-run db-up db-down db-logs migrate migration-sql verify

backend-install:
	cd backend && python3 -m venv .venv && .venv/bin/python -m pip install --upgrade pip && .venv/bin/python -m pip install -e ".[dev]"

backend-test:
	cd backend && .venv/bin/python -m pytest

backend-lint:
	cd backend && .venv/bin/ruff check app alembic

backend-run:
	cd backend && .venv/bin/fastapi dev app/main.py --host 127.0.0.1 --port $${PORT:-8000}

db-up:
	docker compose up -d postgres

db-down:
	docker compose down

db-logs:
	docker compose logs -f postgres

migrate:
	cd backend && .venv/bin/alembic upgrade head

migration-sql:
	cd backend && .venv/bin/alembic upgrade head --sql

verify: backend-test backend-lint migration-sql
