import uuid

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.modules.identity.models import Business, StaffMember, User, UserRole
from app.modules.loyalty.models import (
    AuditEvent,
    Campaign,
    CampaignCompletion,
    CampaignMission,
    CampaignParticipationMode,
    CampaignProgressMetric,
    CampaignScopeType,
    CampaignStatus,
    CampaignType,
    GeneratedReward,
    LoyaltyAction,
    LoyaltyActionItem,
    Mission,
    PointsLedgerEntry,
    RewardStatus,
    RewardTemplate,
    RewardUsage,
    RewardGenerationSourceType,
)


class LoyaltyRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_user(self, user_id: uuid.UUID) -> User | None:
        return self.db.get(User, user_id)

    def get_owner_business(self, *, business_id: uuid.UUID, owner_id: uuid.UUID) -> Business | None:
        return self.db.scalar(
            select(Business).where(Business.id == business_id, Business.owner_id == owner_id)
        )

    def get_staff_membership(
        self, *, business_id: uuid.UUID, staff_user_id: uuid.UUID
    ) -> StaffMember | None:
        return self.db.scalar(
            select(StaffMember).where(
                StaffMember.business_id == business_id,
                StaffMember.user_id == staff_user_id,
                StaffMember.is_active.is_(True),
            )
        )

    def add_mission(self, mission: Mission) -> Mission:
        self.db.add(mission)
        self.db.flush()
        return mission

    def list_business_missions(self, business_id: uuid.UUID) -> list[Mission]:
        return list(self.db.scalars(select(Mission).where(Mission.business_id == business_id)))

    def get_active_missions_by_ids(
        self, *, business_id: uuid.UUID, mission_ids: set[uuid.UUID]
    ) -> dict[uuid.UUID, Mission]:
        if not mission_ids:
            return {}
        missions = self.db.scalars(
            select(Mission).where(
                Mission.business_id == business_id,
                Mission.id.in_(mission_ids),
                Mission.is_active.is_(True),
            )
        )
        return {mission.id: mission for mission in missions}

    def add_campaign(self, campaign: Campaign) -> Campaign:
        self.db.add(campaign)
        self.db.flush()
        return campaign

    def add_campaign_mission(self, campaign_mission: CampaignMission) -> CampaignMission:
        self.db.add(campaign_mission)
        self.db.flush()
        return campaign_mission

    def list_business_campaigns(self, business_id: uuid.UUID) -> list[Campaign]:
        return list(
            self.db.scalars(
                select(Campaign)
                .where(Campaign.creator_business_id == business_id)
                .order_by(Campaign.created_at.desc())
            )
        )

    def get_campaign(self, campaign_id: uuid.UUID) -> Campaign | None:
        return self.db.get(Campaign, campaign_id)

    def get_active_individual_campaigns_for_action(
        self, *, business_id: uuid.UUID, mission_ids: set[uuid.UUID], occurred_at
    ) -> list[Campaign]:
        if not mission_ids:
            return []
        return list(
            self.db.scalars(
                select(Campaign)
                .join(CampaignMission, CampaignMission.campaign_id == Campaign.id)
                .where(
                    Campaign.creator_business_id == business_id,
                    Campaign.campaign_type == CampaignType.INDIVIDUAL,
                    Campaign.scope_type == CampaignScopeType.SINGLE_BUSINESS,
                    Campaign.participation_mode == CampaignParticipationMode.AUTOMATIC,
                    Campaign.progress_metric == CampaignProgressMetric.POINTS,
                    Campaign.status == CampaignStatus.ACTIVE,
                    Campaign.starts_at <= occurred_at,
                    Campaign.ends_at >= occurred_at,
                    CampaignMission.mission_id.in_(mission_ids),
                )
                .distinct()
            )
        )

    def get_campaign_mission_ids(self, campaign_id: uuid.UUID) -> set[uuid.UUID]:
        return set(
            self.db.scalars(
                select(CampaignMission.mission_id).where(CampaignMission.campaign_id == campaign_id)
            )
        )

    def sum_campaign_points(self, *, campaign: Campaign, customer_id: uuid.UUID) -> int:
        campaign_mission_ids = self.get_campaign_mission_ids(campaign.id)
        if not campaign_mission_ids:
            return 0
        total = self.db.scalar(
            select(func.coalesce(func.sum(PointsLedgerEntry.points), 0))
            .join(LoyaltyAction, LoyaltyAction.id == PointsLedgerEntry.action_id)
            .join(LoyaltyActionItem, LoyaltyActionItem.id == PointsLedgerEntry.action_item_id)
            .where(
                PointsLedgerEntry.customer_id == customer_id,
                PointsLedgerEntry.business_id == campaign.creator_business_id,
                LoyaltyAction.occurred_at >= campaign.starts_at,
                LoyaltyAction.occurred_at <= campaign.ends_at,
                LoyaltyActionItem.mission_id.in_(campaign_mission_ids),
            )
        )
        return int(total or 0)

    def get_campaign_completion(
        self, *, campaign_id: uuid.UUID, customer_id: uuid.UUID
    ) -> CampaignCompletion | None:
        return self.db.scalar(
            select(CampaignCompletion).where(
                CampaignCompletion.campaign_id == campaign_id,
                CampaignCompletion.customer_id == customer_id,
            )
        )

    def add_campaign_completion(self, completion: CampaignCompletion) -> CampaignCompletion:
        self.db.add(completion)
        self.db.flush()
        return completion

    def mark_campaign_completion_reward_generated(
        self, completion: CampaignCompletion, generated_at
    ) -> CampaignCompletion:
        completion.reward_generated_at = generated_at
        self.db.flush()
        return completion

    def get_campaign_for_business(
        self, *, campaign_id: uuid.UUID, business_id: uuid.UUID
    ) -> Campaign | None:
        return self.db.scalar(
            select(Campaign).where(
                Campaign.id == campaign_id,
                Campaign.creator_business_id == business_id,
            )
        )

    def add_reward_template(self, template: RewardTemplate) -> RewardTemplate:
        self.db.add(template)
        self.db.flush()
        return template

    def list_reward_templates(self, business_id: uuid.UUID) -> list[RewardTemplate]:
        return list(
            self.db.scalars(
                select(RewardTemplate)
                .where(RewardTemplate.business_id == business_id)
                .order_by(RewardTemplate.created_at.desc())
            )
        )

    def get_active_reward_template_for_campaign(
        self, campaign_id: uuid.UUID
    ) -> RewardTemplate | None:
        return self.db.scalar(
            select(RewardTemplate).where(
                RewardTemplate.campaign_id == campaign_id,
                RewardTemplate.is_active.is_(True),
            )
        )

    def get_generated_reward_for_source(
        self,
        *,
        source_type: RewardGenerationSourceType,
        source_id: uuid.UUID,
        customer_id: uuid.UUID,
    ) -> GeneratedReward | None:
        return self.db.scalar(
            select(GeneratedReward).where(
                GeneratedReward.source_type == source_type,
                GeneratedReward.source_id == source_id,
                GeneratedReward.customer_id == customer_id,
            )
        )

    def add_generated_reward(self, reward: GeneratedReward) -> GeneratedReward:
        self.db.add(reward)
        self.db.flush()
        return reward

    def list_customer_rewards(
        self, *, business_id: uuid.UUID, customer_id: uuid.UUID
    ) -> list[GeneratedReward]:
        return list(
            self.db.scalars(
                select(GeneratedReward)
                .where(
                    GeneratedReward.business_id == business_id,
                    GeneratedReward.customer_id == customer_id,
                )
                .order_by(GeneratedReward.issued_at.desc())
            )
        )

    def get_generated_reward(self, reward_id: uuid.UUID) -> GeneratedReward | None:
        return self.db.get(GeneratedReward, reward_id)

    def get_reward_usage_for_reward(self, reward_id: uuid.UUID) -> RewardUsage | None:
        return self.db.scalar(
            select(RewardUsage).where(RewardUsage.generated_reward_id == reward_id)
        )

    def add_reward_usage(self, usage: RewardUsage) -> RewardUsage:
        self.db.add(usage)
        self.db.flush()
        return usage

    def expire_reward(self, reward: GeneratedReward, expired_at) -> GeneratedReward:
        reward.status = RewardStatus.EXPIRED
        reward.used_at = None
        reward.updated_at = expired_at
        self.db.flush()
        return reward

    def get_action_by_idempotency_key(
        self, *, business_id: uuid.UUID, idempotency_key: str
    ) -> LoyaltyAction | None:
        return self.db.scalar(
            select(LoyaltyAction)
            .where(
                LoyaltyAction.business_id == business_id,
                LoyaltyAction.idempotency_key == idempotency_key,
            )
            .options(selectinload(LoyaltyAction.items))
        )

    def add_action(self, action: LoyaltyAction) -> LoyaltyAction:
        self.db.add(action)
        self.db.flush()
        return action

    def add_action_item(self, item: LoyaltyActionItem) -> LoyaltyActionItem:
        self.db.add(item)
        self.db.flush()
        return item

    def add_points_entry(self, entry: PointsLedgerEntry) -> PointsLedgerEntry:
        self.db.add(entry)
        self.db.flush()
        return entry

    def add_audit_event(self, event: AuditEvent) -> AuditEvent:
        self.db.add(event)
        self.db.flush()
        return event

    def sum_customer_points(self, *, business_id: uuid.UUID, customer_id: uuid.UUID) -> int:
        total = self.db.scalar(
            select(func.coalesce(func.sum(PointsLedgerEntry.points), 0)).where(
                PointsLedgerEntry.business_id == business_id,
                PointsLedgerEntry.customer_id == customer_id,
            )
        )
        return int(total or 0)

    def count_actions_for_business(self, business_id: uuid.UUID) -> int:
        return int(
            self.db.scalar(
                select(func.count()).select_from(LoyaltyAction).where(
                    LoyaltyAction.business_id == business_id
                )
            )
            or 0
        )

    def count_points_entries_for_business(self, business_id: uuid.UUID) -> int:
        return int(
            self.db.scalar(
                select(func.count()).select_from(PointsLedgerEntry).where(
                    PointsLedgerEntry.business_id == business_id
                )
            )
            or 0
        )

    @staticmethod
    def is_customer(user: User | None) -> bool:
        return user is not None and user.is_active and user.role == UserRole.CUSTOMER
