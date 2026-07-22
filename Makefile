.PHONY: backend-install backend-test backend-lint backend-run frontend-build-local frontend-build-production frontend-deploy-production production-smoke db-up db-down db-logs migrate migration-check verify

backend-install:
	cd backend && python3 -m venv .venv && .venv/bin/python -m pip install --upgrade pip && .venv/bin/python -m pip install -c constraints-runtime.txt -c constraints-dev.txt -e ".[dev]"

backend-test:
	cd backend && .venv/bin/python -m pytest

backend-lint:
	cd backend && .venv/bin/ruff check app alembic

backend-run:
	cd backend && .venv/bin/fastapi dev app/main.py --host 127.0.0.1 --port $${PORT:-8000}

frontend-build-production:
	./scripts/build_frontend_production.sh

frontend-deploy-production:
	./scripts/deploy_frontend_production.sh

production-smoke:
	./scripts/check_production_smoke.sh

frontend-build-local:
	./scripts/build_frontend_local.sh

db-up:
	docker compose up -d postgres

db-down:
	docker compose down

db-logs:
	docker compose logs -f postgres

migrate:
	cd backend && .venv/bin/alembic upgrade head

migration-check:
	cd backend && .venv/bin/python scripts/check_migrations.py

verify: backend-test backend-lint migration-check
