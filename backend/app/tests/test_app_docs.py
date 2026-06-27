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
    monkeypatch.setenv("APP_ENV", "production")
    get_settings.cache_clear()
    app = create_app()

    with TestClient(app) as client:
        assert client.get("/docs").status_code == 404
        assert client.get("/redoc").status_code == 404
        assert client.get("/openapi.json").status_code == 404

    get_settings.cache_clear()
