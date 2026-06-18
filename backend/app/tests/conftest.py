from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import Settings, get_settings
from app.core.database import Base, get_db
from app.main import create_app
from app.modules.identity.dependencies import get_email_sender


class CapturingEmailSender:
    def __init__(self) -> None:
        self.sent: list[dict[str, str]] = []

    def send_email(self, *, to_email: str, subject: str, body: str) -> None:
        self.sent.append({"to_email": to_email, "subject": subject, "body": body})


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite+pysqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    testing_session = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    with testing_session() as session:
        yield session
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client(db_session: Session) -> Generator[TestClient, None, None]:
    app = create_app()
    email_sender = CapturingEmailSender()

    def override_db() -> Generator[Session, None, None]:
        yield db_session

    def override_settings() -> Settings:
        return Settings(
            DATABASE_URL="sqlite+pysqlite:///:memory:",
            JWT_SECRET_KEY="test-secret",
            JWT_ISSUER="zomia-test",
            EMAIL_DELIVERY_MODE="test",
            OTP_TEST_CODE="123456",
        )

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_settings] = override_settings
    app.dependency_overrides[get_email_sender] = lambda: email_sender
    app.state.email_sender = email_sender
    with TestClient(app) as test_client:
        yield test_client
