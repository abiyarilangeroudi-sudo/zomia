from __future__ import annotations

from typing import Any

from app.core.config import Settings


SENSITIVE_KEYS = {
    "authorization",
    "cookie",
    "database_url",
    "dsn",
    "email_body",
    "jwt_secret_key",
    "otp",
    "password",
    "qr_token",
    "refresh_token",
    "secret",
    "smtp_password",
    "token",
}

_sentry_initialized = False


def setup_sentry(settings: Settings) -> None:
    global _sentry_initialized
    if settings.app_env.lower() != "production" or not settings.sentry_dsn:
        return
    if _sentry_initialized:
        return

    import sentry_sdk

    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.app_env.lower(),
        send_default_pii=False,
        traces_sample_rate=settings.sentry_traces_sample_rate,
        before_send=_scrub_sentry_event,
    )
    _sentry_initialized = True


def _scrub_sentry_event(event: dict[str, Any], hint: dict[str, Any]) -> dict[str, Any]:
    return _scrub_value(event)


def _scrub_value(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: "[Filtered]" if _is_sensitive_key(key) else _scrub_value(child)
            for key, child in value.items()
        }
    if isinstance(value, list):
        return [_scrub_value(item) for item in value]
    return value


def _is_sensitive_key(key: Any) -> bool:
    normalized = str(key).lower()
    return any(sensitive_key in normalized for sensitive_key in SENSITIVE_KEYS)
