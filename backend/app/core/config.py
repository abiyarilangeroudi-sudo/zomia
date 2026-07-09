from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = Field(default="local", alias="APP_ENV")
    database_url: str = Field(
        default="postgresql+psycopg://zomia:zomia@localhost:5432/zomia",
        alias="DATABASE_URL",
    )
    jwt_secret_key: str = Field(default="change-me-in-production", alias="JWT_SECRET_KEY")
    jwt_issuer: str = Field(default="zomia-api", alias="JWT_ISSUER")
    access_token_minutes: int = Field(default=60, alias="ACCESS_TOKEN_MINUTES")
    refresh_token_days: int = Field(default=30, alias="REFRESH_TOKEN_DAYS")
    email_delivery_mode: str = Field(default="disabled", alias="EMAIL_DELIVERY_MODE")
    otp_expires_minutes: int = Field(default=10, alias="OTP_EXPIRES_MINUTES")
    otp_test_code: str | None = Field(default=None, alias="OTP_TEST_CODE")
    frontend_base_url: str = Field(default="http://localhost:8080", alias="FRONTEND_BASE_URL")
    staff_invitation_expires_hours: int = Field(
        default=24, alias="STAFF_INVITATION_EXPIRES_HOURS"
    )
    smtp_host: str | None = Field(default=None, alias="SMTP_HOST")
    smtp_port: int = Field(default=587, alias="SMTP_PORT")
    smtp_username: str | None = Field(default=None, alias="SMTP_USERNAME")
    smtp_password: str | None = Field(default=None, alias="SMTP_PASSWORD")
    smtp_from_email: str | None = Field(default=None, alias="SMTP_FROM_EMAIL")
    smtp_from_name: str = Field(default="Zomia", alias="SMTP_FROM_NAME")
    smtp_use_tls: bool = Field(default=True, alias="SMTP_USE_TLS")
    sentry_dsn: str | None = Field(default=None, alias="SENTRY_DSN")
    sentry_traces_sample_rate: float = Field(default=0.0, alias="SENTRY_TRACES_SAMPLE_RATE")
    cors_allowed_origins: str = Field(
        default="http://localhost:8080,http://127.0.0.1:8080",
        alias="CORS_ALLOWED_ORIGINS",
    )

    @model_validator(mode="after")
    def validate_production_settings(self) -> "Settings":
        if self.app_env.lower() != "production":
            return self

        errors: list[str] = []
        if self.jwt_secret_key == "change-me-in-production" or len(self.jwt_secret_key) < 32:
            errors.append("JWT_SECRET_KEY must contain at least 32 characters")
        if self.otp_test_code is not None:
            errors.append("OTP_TEST_CODE must not be set")
        if self.email_delivery_mode != "smtp":
            errors.append("EMAIL_DELIVERY_MODE must be smtp")
        if not self.frontend_base_url.startswith("https://"):
            errors.append("FRONTEND_BASE_URL must use https")
        if any(not origin.startswith("https://") for origin in self.cors_origins):
            errors.append("CORS_ALLOWED_ORIGINS must contain only https origins")
        if any(
            value is None
            for value in (
                self.smtp_host,
                self.smtp_username,
                self.smtp_password,
                self.smtp_from_email,
            )
        ):
            errors.append("SMTP settings are incomplete")
        if errors:
            raise ValueError("Invalid production configuration: " + "; ".join(errors))
        return self

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
