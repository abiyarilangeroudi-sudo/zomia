import uuid

from sqlalchemy import and_, case, func, or_, select
from sqlalchemy.orm import Session

from app.modules.loyalty.models import (
    Campaign,
    CampaignMission,
    GeneratedReward,
    LoyaltyAction,
    LoyaltyActionItem,
    PointsLedgerEntry,
    RewardStatus,
)


class LoyaltyReportingRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    @staticmethod
    def _reward_count_columns(now):
        return (
            func.count(GeneratedReward.id),
            func.coalesce(
                func.sum(
                    case(
                        (
                            and_(
                                GeneratedReward.status == RewardStatus.ACTIVE,
                                GeneratedReward.expires_at > now,
                            ),
                            1,
                        ),
                        else_=0,
                    )
                ),
                0,
            ),
            func.coalesce(
                func.sum(case((GeneratedReward.status == RewardStatus.USED, 1), else_=0)),
                0,
            ),
            func.coalesce(
                func.sum(
                    case(
                        (
                            or_(
                                GeneratedReward.status == RewardStatus.EXPIRED,
                                and_(
                                    GeneratedReward.status == RewardStatus.ACTIVE,
                                    GeneratedReward.expires_at <= now,
                                ),
                            ),
                            1,
                        ),
                        else_=0,
                    )
                ),
                0,
            ),
        )

    def list_campaign_activity_summaries(
        self, *, campaign_ids: list[uuid.UUID], now
    ) -> dict[uuid.UUID, dict[str, int]]:
        if not campaign_ids:
            return {}

        summaries = {
            campaign_id: {
                "participating_customer_count": 0,
                "rewards_issued_count": 0,
                "rewards_ready_to_use_count": 0,
                "rewards_used_count": 0,
                "rewards_expired_count": 0,
            }
            for campaign_id in campaign_ids
        }
        effective_starts_at = case(
            (Campaign.starts_at > Campaign.created_at, Campaign.starts_at),
            else_=Campaign.created_at,
        )
        participation_rows = self.db.execute(
            select(
                CampaignMission.campaign_id,
                func.count(func.distinct(PointsLedgerEntry.customer_id)),
            )
            .join(Campaign, Campaign.id == CampaignMission.campaign_id)
            .join(LoyaltyActionItem, LoyaltyActionItem.mission_id == CampaignMission.mission_id)
            .join(PointsLedgerEntry, PointsLedgerEntry.action_item_id == LoyaltyActionItem.id)
            .join(LoyaltyAction, LoyaltyAction.id == PointsLedgerEntry.action_id)
            .where(
                CampaignMission.campaign_id.in_(campaign_ids),
                PointsLedgerEntry.business_id == Campaign.creator_business_id,
                LoyaltyAction.occurred_at >= effective_starts_at,
                LoyaltyAction.occurred_at <= Campaign.ends_at,
            )
            .group_by(CampaignMission.campaign_id)
        ).all()
        for campaign_id, customer_count in participation_rows:
            summaries[campaign_id]["participating_customer_count"] = int(customer_count)

        reward_rows = self.db.execute(
            select(GeneratedReward.campaign_id, *self._reward_count_columns(now))
            .where(GeneratedReward.campaign_id.in_(campaign_ids))
            .group_by(GeneratedReward.campaign_id)
        ).all()
        for campaign_id, issued, ready_to_use, used, expired in reward_rows:
            summaries[campaign_id].update(
                rewards_issued_count=int(issued),
                rewards_ready_to_use_count=int(ready_to_use),
                rewards_used_count=int(used),
                rewards_expired_count=int(expired),
            )
        return summaries

    def get_business_loyalty_summary(self, *, business_id: uuid.UUID, now) -> dict[str, int]:
        participating_customer_count = int(
            self.db.scalar(
                select(func.count(func.distinct(PointsLedgerEntry.customer_id))).where(
                    PointsLedgerEntry.business_id == business_id
                )
            )
            or 0
        )
        issued, ready_to_use, used, expired = self.db.execute(
            select(*self._reward_count_columns(now)).where(
                GeneratedReward.business_id == business_id
            )
        ).one()
        return {
            "participating_customer_count": participating_customer_count,
            "rewards_issued_count": int(issued),
            "rewards_ready_to_use_count": int(ready_to_use),
            "rewards_used_count": int(used),
            "rewards_expired_count": int(expired),
        }
