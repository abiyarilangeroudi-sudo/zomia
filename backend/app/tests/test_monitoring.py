from types import SimpleNamespace

import app.core.monitoring as monitoring
from app.core.config import Settings
from app.core.monitoring import _scrub_sentry_event, setup_sentry


def test_sentry_is_disabled_without_dsn() -> None:
    settings = Settings(APP_ENV="production", SENTRY_DSN=None)

    setup_sentry(settings)


def test_sentry_is_disabled_outside_production() -> None:
    settings = Settings(APP_ENV="local", SENTRY_DSN="https://example@sentry.invalid/1")

    setup_sentry(settings)


def test_sentry_initializes_in_production_with_dsn(monkeypatch) -> None:
    calls = []

    def fake_init(**kwargs) -> None:
        calls.append(kwargs)

    monkeypatch.setattr(monitoring, "_sentry_initialized", False)
    monkeypatch.setitem(__import__("sys").modules, "sentry_sdk", SimpleNamespace(init=fake_init))
    settings = Settings(
        APP_ENV="production",
        SENTRY_DSN="https://example@sentry.invalid/1",
        SENTRY_TRACES_SAMPLE_RATE=0.0,
    )

    setup_sentry(settings)
    setup_sentry(settings)

    assert len(calls) == 1
    assert calls[0]["dsn"] == "https://example@sentry.invalid/1"
    assert calls[0]["environment"] == "production"
    assert calls[0]["send_default_pii"] is False
    assert calls[0]["traces_sample_rate"] == 0.0


def test_sentry_event_scrubs_sensitive_values() -> None:
    event = {
        "request": {
            "headers": {"Authorization": "Bearer secret-token"},
            "data": {"password": "secret", "otp": "123456", "name": "Visible"},
        },
        "extra": {"qr_token": "raw-token", "count": 1},
    }

    scrubbed = _scrub_sentry_event(event, {})

    assert scrubbed["request"]["headers"]["Authorization"] == "[Filtered]"
    assert scrubbed["request"]["data"]["password"] == "[Filtered]"
    assert scrubbed["request"]["data"]["otp"] == "[Filtered]"
    assert scrubbed["request"]["data"]["name"] == "Visible"
    assert scrubbed["extra"]["qr_token"] == "[Filtered]"
    assert scrubbed["extra"]["count"] == 1
