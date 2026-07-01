from fastapi.testclient import TestClient

from app.main import create_app


def test_health_get_returns_ok() -> None:
    app = create_app()

    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_health_head_returns_ok_without_body() -> None:
    app = create_app()

    with TestClient(app) as client:
        response = client.head("/health")

    assert response.status_code == 200
    assert response.content == b""
