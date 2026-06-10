import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.identity.dependencies import get_current_user
from app.modules.identity.models import User
from app.modules.qr.dependencies import get_qr_service
from app.modules.qr.schemas import (
    CustomerQrTokenRead,
    RegisterActionByQrRequest,
    RegisterActionByQrResponse,
    ResolveQrRequest,
    StaffServiceSummary,
    UseRewardByQrRequest,
    UseRewardByQrResponse,
)
from app.modules.qr.service import QrService

router = APIRouter(tags=["qr"])


@router.post("/customers/me/qr-token", response_model=CustomerQrTokenRead)
def issue_my_qr_token(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: QrService = Depends(get_qr_service),
) -> CustomerQrTokenRead:
    token = service.issue_customer_token(current_user)
    db.commit()
    return token


@router.post("/customers/me/qr-token/rotate", response_model=CustomerQrTokenRead)
def rotate_my_qr_token(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: QrService = Depends(get_qr_service),
) -> CustomerQrTokenRead:
    token = service.rotate_customer_token(current_user)
    db.commit()
    return token


@router.post("/staff/qr/resolve", response_model=StaffServiceSummary)
def resolve_qr(
    payload: ResolveQrRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: QrService = Depends(get_qr_service),
) -> StaffServiceSummary:
    summary = service.resolve_qr(current_user, payload)
    db.commit()
    return summary


@router.post("/staff/service/actions", response_model=RegisterActionByQrResponse)
def register_action_by_qr(
    payload: RegisterActionByQrRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: QrService = Depends(get_qr_service),
) -> RegisterActionByQrResponse:
    response = service.register_action_by_qr(current_user, payload)
    db.commit()
    return response


@router.post("/staff/service/rewards/{reward_id}/use", response_model=UseRewardByQrResponse)
def use_reward_by_qr(
    reward_id: uuid.UUID,
    payload: UseRewardByQrRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: QrService = Depends(get_qr_service),
) -> UseRewardByQrResponse:
    response = service.use_reward_by_qr(current_user, reward_id, payload)
    db.commit()
    return response
