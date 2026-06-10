import uuid

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.identity.dependencies import get_current_user
from app.modules.identity.models import User
from app.modules.loyalty.dependencies import get_loyalty_service
from app.modules.loyalty.schemas import (
    CustomerPointsRead,
    MissionCreate,
    MissionRead,
    RegisterActionRequest,
    RegisterActionResponse,
)
from app.modules.loyalty.service import LoyaltyService

router = APIRouter(tags=["loyalty"])


@router.post("/owner/missions", response_model=MissionRead, status_code=status.HTTP_201_CREATED)
def create_mission(
    payload: MissionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    mission = service.create_mission(current_user, payload)
    db.commit()
    db.refresh(mission)
    return mission


@router.get("/owner/missions", response_model=list[MissionRead])
def list_missions(
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    return service.list_missions(current_user, business_id)


@router.post("/staff/actions", response_model=RegisterActionResponse, status_code=status.HTTP_201_CREATED)
def register_action(
    payload: RegisterActionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> RegisterActionResponse:
    response = service.register_action(current_user, payload)
    db.commit()
    return response


@router.get("/customers/me/points", response_model=CustomerPointsRead)
def get_my_points(
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> CustomerPointsRead:
    return service.get_customer_points(current_user, business_id)

