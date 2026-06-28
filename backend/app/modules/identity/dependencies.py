import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.database import get_db
from app.core.email import EmailSender
from app.core.security import decode_access_token
from app.modules.identity.models import User
from app.modules.identity.repository import IdentityRepository
from app.modules.identity.service import IdentityService

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_identity_repository(db: Session = Depends(get_db)) -> IdentityRepository:
    return IdentityRepository(db)


def get_email_sender(settings: Settings = Depends(get_settings)) -> EmailSender:
    return EmailSender(settings)


def get_identity_service(
    repository: IdentityRepository = Depends(get_identity_repository),
    settings: Settings = Depends(get_settings),
    email_sender: EmailSender = Depends(get_email_sender),
) -> IdentityService:
    return IdentityService(repository, settings, email_sender)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    repository: IdentityRepository = Depends(get_identity_repository),
    settings: Settings = Depends(get_settings),
) -> User:
    payload = decode_access_token(
        token=token, secret_key=settings.jwt_secret_key, issuer=settings.jwt_issuer
    )
    try:
        user_id = uuid.UUID(payload["sub"])
    except (KeyError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        ) from None
    user = repository.get_user_by_id(user_id)
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Inactive user")
    if payload.get("session_version") != user.session_version:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )
    return user
