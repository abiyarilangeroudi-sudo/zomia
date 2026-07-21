import os
import subprocess
import sys
import uuid
from pathlib import Path

from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

from app.core.config import Settings


BACKEND_DIR = Path(__file__).resolve().parents[1]


def main() -> None:
    settings = Settings()
    if settings.app_env.lower() == "production":
        raise SystemExit("Migration check must not run against production")

    source_url = make_url(settings.database_url)
    if not source_url.drivername.startswith("postgresql"):
        raise SystemExit("Migration check requires PostgreSQL")

    database_name = f"zomia_migration_check_{uuid.uuid4().hex[:12]}"
    admin_url = source_url.set(database="postgres")
    check_url = source_url.set(database=database_name)
    admin_engine = create_engine(admin_url, isolation_level="AUTOCOMMIT")

    with admin_engine.connect() as connection:
        connection.execute(text(f'CREATE DATABASE "{database_name}"'))

    try:
        env = os.environ.copy()
        env["APP_ENV"] = "local"
        env["DATABASE_URL"] = check_url.render_as_string(hide_password=False)
        subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", "head"],
            cwd=BACKEND_DIR,
            env=env,
            check=True,
        )
        current = subprocess.run(
            [sys.executable, "-m", "alembic", "current"],
            cwd=BACKEND_DIR,
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )
        if "(head)" not in current.stdout:
            raise RuntimeError(f"Migration check did not reach head: {current.stdout.strip()}")
        print(current.stdout.strip())
        print("Fresh PostgreSQL migration check passed")
    finally:
        with admin_engine.connect() as connection:
            connection.execute(text(f'DROP DATABASE IF EXISTS "{database_name}" WITH (FORCE)'))
        admin_engine.dispose()


if __name__ == "__main__":
    main()
