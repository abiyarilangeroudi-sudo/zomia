import uuid

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.identity.dependencies import get_current_user
from app.modules.identity.models import User
from app.modules.loyalty.dependencies import get_loyalty_service
from app.modules.loyalty.schemas import (
    ActiveStatusUpdate,
    CampaignCreate,
    CampaignProgressRead,
    CustomerCampaignProgressRead,
    CustomerStatusRead,
    CampaignRead,
    CampaignStatusUpdate,
    CustomerPointsRead,
    GeneratedRewardRead,
    MissionCreate,
    MissionRead,
    MissionUpdate,
    OwnerActivityRead,
    RegisterActionRequest,
    RegisterActionResponse,
    RewardTemplateCreate,
    RewardTemplateRead,
    RewardTemplateUpdate,
    UseRewardRequest,
    UseRewardResponse,
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


@router.patch("/owner/missions/{mission_id}", response_model=MissionRead)
def update_mission(
    mission_id: uuid.UUID,
    payload: MissionUpdate,
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    mission = service.update_mission(
        current_user, business_id=business_id, mission_id=mission_id, payload=payload
    )
    db.commit()
    db.refresh(mission)
    return mission


@router.delete("/owner/missions/{mission_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_mission(
    mission_id: uuid.UUID,
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    service.delete_mission(current_user, business_id=business_id, mission_id=mission_id)
    db.commit()


@router.patch("/owner/missions/{mission_id}/active", response_model=MissionRead)
def set_mission_active(
    mission_id: uuid.UUID,
    payload: ActiveStatusUpdate,
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    mission = service.set_mission_active(
        current_user, business_id=business_id, mission_id=mission_id, payload=payload
    )
    db.commit()
    db.refresh(mission)
    return mission


@router.post("/owner/campaigns", response_model=CampaignRead, status_code=status.HTTP_201_CREATED)
def create_campaign(
    payload: CampaignCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    campaign = service.create_campaign(current_user, payload)
    db.commit()
    db.refresh(campaign)
    return campaign


@router.get("/owner/campaigns", response_model=list[CampaignRead])
def list_campaigns(
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    return service.list_campaigns(current_user, business_id)


@router.patch("/owner/campaigns/{campaign_id}/status", response_model=CampaignRead)
def update_campaign_status(
    campaign_id: uuid.UUID,
    payload: CampaignStatusUpdate,
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    campaign = service.update_campaign_status(
        current_user, business_id=business_id, campaign_id=campaign_id, payload=payload
    )
    db.commit()
    db.refresh(campaign)
    return campaign


@router.post(
    "/owner/reward-templates",
    response_model=RewardTemplateRead,
    status_code=status.HTTP_201_CREATED,
)
def create_reward_template(
    payload: RewardTemplateCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    template = service.create_reward_template(current_user, payload)
    db.commit()
    db.refresh(template)
    return template


@router.get("/owner/reward-templates", response_model=list[RewardTemplateRead])
def list_reward_templates(
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    return service.list_reward_templates(current_user, business_id)


@router.patch("/owner/reward-templates/{reward_template_id}", response_model=RewardTemplateRead)
def update_reward_template(
    reward_template_id: uuid.UUID,
    payload: RewardTemplateUpdate,
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    template = service.update_reward_template(
        current_user,
        business_id=business_id,
        reward_template_id=reward_template_id,
        payload=payload,
    )
    db.commit()
    db.refresh(template)
    return template


@router.delete("/owner/reward-templates/{reward_template_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reward_template(
    reward_template_id: uuid.UUID,
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    service.delete_reward_template(
        current_user, business_id=business_id, reward_template_id=reward_template_id
    )
    db.commit()


@router.patch(
    "/owner/reward-templates/{reward_template_id}/active",
    response_model=RewardTemplateRead,
)
def set_reward_template_active(
    reward_template_id: uuid.UUID,
    payload: ActiveStatusUpdate,
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    template = service.set_reward_template_active(
        current_user,
        business_id=business_id,
        reward_template_id=reward_template_id,
        payload=payload,
    )
    db.commit()
    db.refresh(template)
    return template


@router.get("/owner/activity/recent", response_model=list[OwnerActivityRead])
def list_owner_recent_activity(
    business_id: uuid.UUID = Query(...),
    limit: int = Query(default=20, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> list[OwnerActivityRead]:
    return service.list_owner_recent_activity(current_user, business_id, limit=limit)


@router.post(
    "/staff/actions", response_model=RegisterActionResponse, status_code=status.HTTP_201_CREATED
)
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


@router.get("/customers/me/status", response_model=CustomerStatusRead)
def get_my_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> CustomerStatusRead:
    status_read = service.get_customer_status(current_user)
    db.commit()
    return status_read


@router.get("/customers/me/campaigns/progress", response_model=list[CustomerCampaignProgressRead])
def list_my_campaign_progresses(
    current_user: User = Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> list[CustomerCampaignProgressRead]:
    return service.list_customer_campaign_progresses(current_user)


@router.get("/customers/me/campaigns/{campaign_id}/progress", response_model=CampaignProgressRead)
def get_my_campaign_progress(
    campaign_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> CampaignProgressRead:
    return service.get_campaign_progress(current_user, campaign_id)


@router.get("/customers/me/rewards", response_model=list[GeneratedRewardRead])
def get_my_rewards(
    business_id: uuid.UUID = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> list[GeneratedRewardRead]:
    rewards = service.list_customer_rewards(current_user, business_id)
    db.commit()
    return rewards


@router.post("/staff/rewards/{reward_id}/use", response_model=UseRewardResponse)
def use_reward(
    reward_id: uuid.UUID,
    payload: UseRewardRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: LoyaltyService = Depends(get_loyalty_service),
) -> UseRewardResponse:
    response = service.use_reward(current_user, reward_id, payload)
    db.commit()
    return response
