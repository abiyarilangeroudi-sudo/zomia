from fastapi import Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.loyalty.dependencies import get_loyalty_service
from app.modules.loyalty.service import LoyaltyService
from app.modules.qr.repository import QrRepository
from app.modules.qr.service import QrService


def get_qr_repository(db: Session = Depends(get_db)) -> QrRepository:
    return QrRepository(db)


def get_qr_service(
    repository: QrRepository = Depends(get_qr_repository),
    loyalty_service: LoyaltyService = Depends(get_loyalty_service),
) -> QrService:
    return QrService(repository=repository, loyalty_service=loyalty_service)
