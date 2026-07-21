from collections.abc import Callable
from datetime import UTC, datetime

from fastapi import HTTPException, status

from app.modules.identity.models import User, UserRole
from app.modules.loyalty.models import (
    AuditEventType,
    Mission,
    RewardRedeemScope,
    RewardSettlementPolicy,
    RewardTemplate,
)
from app.modules.loyalty.repository import LoyaltyRepository
from app.modules.loyalty.schemas import (
    ActiveStatusUpdate,
    MissionCreate,
    MissionUpdate,
    RewardTemplateCreate,
    RewardTemplateUpdate,
)

AuditRecorder = Callable[..., None]


class LoyaltyCatalogService:
    def __init__(self, repository: LoyaltyRepository, audit: AuditRecorder) -> None:
        self.repository = repository
        self._audit = audit

    def create_mission(self, owner: User, payload: MissionCreate) -> Mission:
        self._require_owner_business(owner, payload.business_id)
        mission = Mission(
            business_id=payload.business_id,
            name=payload.name,
            description=payload.description,
            mission_type=payload.mission_type,
            point_value=payload.point_value,
        )
        self.repository.add_mission(mission)
        self._audit(
            event_type=AuditEventType.MISSION_CREATED,
            actor_user_id=owner.id,
            business_id=payload.business_id,
            entity_type="mission",
            entity_id=mission.id,
            metadata={
                "mission_type": payload.mission_type.value,
                "point_value": payload.point_value,
            },
        )
        return mission

    def list_missions(self, owner: User, business_id) -> list[Mission]:
        self._require_owner_business(owner, business_id)
        missions = self.repository.list_business_missions(business_id)
        now = datetime.now(UTC)
        for mission in missions:
            self._set_usage_capabilities(
                mission,
                is_used=self.repository.mission_has_usage(mission.id),
                has_open_campaign=self.repository.mission_has_open_campaign(
                    mission_id=mission.id, now=now
                ),
            )
        return missions

    def update_mission(
        self, owner: User, *, business_id, mission_id, payload: MissionUpdate
    ) -> Mission:
        self._require_owner_business(owner, business_id)
        mission = self.repository.get_business_mission(
            mission_id=mission_id, business_id=business_id
        )
        if mission is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mission not found")
        if self.repository.mission_has_usage(mission_id):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Mission is already used",
            )
        mission.name = payload.name
        mission.description = payload.description
        mission.point_value = payload.point_value
        return mission

    def delete_mission(self, owner: User, *, business_id, mission_id) -> None:
        self._require_owner_business(owner, business_id)
        mission = self.repository.get_business_mission(
            mission_id=mission_id, business_id=business_id
        )
        if mission is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mission not found")
        if self.repository.mission_has_usage(mission_id):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Mission is already used",
            )
        self.repository.delete_mission(mission)

    def set_mission_active(
        self, owner: User, *, business_id, mission_id, payload: ActiveStatusUpdate
    ) -> Mission:
        self._require_owner_business(owner, business_id)
        mission = self.repository.get_business_mission(
            mission_id=mission_id, business_id=business_id
        )
        if mission is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mission not found")
        now = datetime.now(UTC)
        if (
            payload.is_active is False
            and self.repository.mission_has_open_campaign(mission_id=mission.id, now=now)
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Mission is used by an active campaign",
            )
        self.repository.set_mission_active(mission, payload.is_active)
        self._set_usage_capabilities(
            mission,
            is_used=self.repository.mission_has_usage(mission.id),
            has_open_campaign=self.repository.mission_has_open_campaign(
                mission_id=mission.id, now=now
            ),
        )
        return mission

    def create_reward_template(
        self, owner: User, payload: RewardTemplateCreate
    ) -> RewardTemplate:
        self._require_owner_business(owner, payload.business_id)
        template = self.repository.add_reward_template(
            RewardTemplate(
                business_id=payload.business_id,
                issuer_business_id=payload.business_id,
                name=payload.name,
                description=payload.description,
                reward_type=payload.reward_type,
                redeem_scope=RewardRedeemScope.ISSUER_BUSINESS_ONLY,
                settlement_policy=RewardSettlementPolicy.ISSUER_PAYS,
                gift_name=payload.gift_name,
                discount_percent=payload.discount_percent,
                discount_amount_minor=payload.discount_amount_minor,
                currency_code=payload.currency_code,
                valid_days=payload.valid_days,
                is_active=True,
            )
        )
        self._audit(
            event_type=AuditEventType.REWARD_TEMPLATE_CREATED,
            actor_user_id=owner.id,
            business_id=payload.business_id,
            entity_type="reward_template",
            entity_id=template.id,
            metadata={
                "reward_type": payload.reward_type.value,
                "redeem_scope": RewardRedeemScope.ISSUER_BUSINESS_ONLY.value,
                "settlement_policy": RewardSettlementPolicy.ISSUER_PAYS.value,
            },
        )
        return template

    def list_reward_templates(self, owner: User, business_id) -> list[RewardTemplate]:
        self._require_owner_business(owner, business_id)
        templates = self.repository.list_reward_templates(business_id)
        now = datetime.now(UTC)
        for template in templates:
            self._set_usage_capabilities(
                template,
                is_used=self.repository.reward_template_has_usage(template.id),
                has_open_campaign=self.repository.reward_template_has_open_campaign(
                    reward_template_id=template.id, now=now
                ),
            )
        return templates

    def update_reward_template(
        self, owner: User, *, business_id, reward_template_id, payload: RewardTemplateUpdate
    ) -> RewardTemplate:
        self._require_owner_business(owner, business_id)
        template = self.repository.get_reward_template_for_business(
            reward_template_id=reward_template_id, business_id=business_id
        )
        if template is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reward template not found",
            )
        if self.repository.reward_template_has_usage(reward_template_id):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Reward template is already used",
            )
        template.name = payload.name
        template.description = payload.description
        template.gift_name = payload.gift_name
        template.valid_days = payload.valid_days
        return template

    def delete_reward_template(
        self, owner: User, *, business_id, reward_template_id
    ) -> None:
        self._require_owner_business(owner, business_id)
        template = self.repository.get_reward_template_for_business(
            reward_template_id=reward_template_id, business_id=business_id
        )
        if template is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reward template not found",
            )
        if self.repository.reward_template_has_usage(reward_template_id):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Reward template is already used",
            )
        self.repository.delete_reward_template(template)

    def set_reward_template_active(
        self, owner: User, *, business_id, reward_template_id, payload: ActiveStatusUpdate
    ) -> RewardTemplate:
        self._require_owner_business(owner, business_id)
        template = self.repository.get_reward_template_for_business(
            reward_template_id=reward_template_id, business_id=business_id
        )
        if template is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reward template not found",
            )
        now = datetime.now(UTC)
        if (
            payload.is_active is False
            and self.repository.reward_template_has_open_campaign(
                reward_template_id=template.id, now=now
            )
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Reward template is used by an active campaign",
            )
        self.repository.set_reward_template_active(template, payload.is_active)
        self._set_usage_capabilities(
            template,
            is_used=self.repository.reward_template_has_usage(template.id),
            has_open_campaign=self.repository.reward_template_has_open_campaign(
                reward_template_id=template.id, now=now
            ),
        )
        return template

    def _require_owner_business(self, owner: User, business_id) -> None:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

    @staticmethod
    def _set_usage_capabilities(item, *, is_used: bool, has_open_campaign: bool) -> None:
        item.can_edit = not is_used
        item.can_delete = not is_used
        item.can_archive = is_used and item.is_active and not has_open_campaign

    @staticmethod
    def _require_role(user: User, role: UserRole) -> None:
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
