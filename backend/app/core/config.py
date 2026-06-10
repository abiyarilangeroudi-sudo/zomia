from functools import lru_cache

from pydantic import Field
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


@lru_cache
def get_settings() -> Settings:
    return Settings()
