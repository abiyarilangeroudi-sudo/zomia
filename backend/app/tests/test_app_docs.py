from fastapi.testclient import TestClient

from app.core.config import get_settings
from app.main import create_app


def test_api_docs_are_available_outside_production(monkeypatch) -> None:
    monkeypatch.setenv("APP_ENV", "local")
    get_settings.cache_clear()
    app = create_app()

    with TestClient(app) as client:
        assert client.get("/docs").status_code == 200
        assert client.get("/openapi.json").status_code == 200

    get_settings.cache_clear()


def test_api_docs_are_disabled_in_production(monkeypatch) -> None:
    production_env = {
        "APP_ENV": "production",
        "JWT_SECRET_KEY": "a-production-secret-with-more-than-32-characters",
        "EMAIL_DELIVERY_MODE": "smtp",
        "FRONTEND_BASE_URL": "https://zomia.eu/webapp",
        "CORS_ALLOWED_ORIGINS": "https://zomia.eu",
        "SMTP_HOST": "smtp.example.com",
        "SMTP_USERNAME": "smtp-user",
        "SMTP_PASSWORD": "smtp-password",
        "SMTP_FROM_EMAIL": "noreply@example.com",
    }
    for key, value in production_env.items():
        monkeypatch.setenv(key, value)
    get_settings.cache_clear()
    app = create_app()

    with TestClient(app) as client:
        assert client.get("/docs").status_code == 404
        assert client.get("/redoc").status_code == 404
        assert client.get("/openapi.json").status_code == 404

    get_settings.cache_clear()
