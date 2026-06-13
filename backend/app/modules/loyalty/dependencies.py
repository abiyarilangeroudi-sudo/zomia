from fastapi import Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.loyalty.repository import LoyaltyRepository
from app.modules.loyalty.service import LoyaltyService


def get_loyalty_repository(db: Session = Depends(get_db)) -> LoyaltyRepository:
    return LoyaltyRepository(db)


def get_loyalty_service(
    repository: LoyaltyRepository = Depends(get_loyalty_repository),
) -> LoyaltyService:
    return LoyaltyService(repository)
