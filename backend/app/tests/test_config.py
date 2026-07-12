import pytest
from pydantic import ValidationError

from app.core.config import Settings


def production_settings(**overrides) -> Settings:
    values = {
        "APP_ENV": "production",
        "OTP_TEST_CODE": None,
        "JWT_SECRET_KEY": "a-production-secret-with-more-than-32-characters",
        "EMAIL_DELIVERY_MODE": "smtp",
        "FRONTEND_BASE_URL": "https://zomia.eu/webapp",
        "CORS_ALLOWED_ORIGINS": "https://zomia.eu",
        "SMTP_HOST": "smtp.example.com",
        "SMTP_USERNAME": "smtp-user",
        "SMTP_PASSWORD": "smtp-password",
        "SMTP_FROM_EMAIL": "noreply@example.com",
    }
    values.update(overrides)
    return Settings(**values)


def test_valid_production_settings_pass_validation() -> None:
    settings = production_settings()

    assert settings.app_env == "production"


@pytest.mark.parametrize(
    ("override", "message"),
    [
        ({"JWT_SECRET_KEY": "short"}, "JWT_SECRET_KEY"),
        ({"OTP_TEST_CODE": "123456"}, "OTP_TEST_CODE"),
        ({"EMAIL_DELIVERY_MODE": "disabled"}, "EMAIL_DELIVERY_MODE"),
        ({"FRONTEND_BASE_URL": "http://zomia.eu"}, "FRONTEND_BASE_URL"),
        ({"CORS_ALLOWED_ORIGINS": "http://localhost:8080"}, "CORS_ALLOWED_ORIGINS"),
        ({"SMTP_PASSWORD": None}, "SMTP settings"),
    ],
)
def test_invalid_production_settings_fail_fast(override: dict, message: str) -> None:
    with pytest.raises(ValidationError, match=message):
        production_settings(**override)
