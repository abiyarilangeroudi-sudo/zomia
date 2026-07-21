import enum
import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    JSON,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class MissionType(str, enum.Enum):
    PURCHASE = "purchase"
    VISIT = "visit"
    REFERRAL = "referral"
    CUSTOM = "custom"


class LoyaltyActionType(str, enum.Enum):
    MISSION_PROGRESS = "mission_progress"
    REWARD_USE = "reward_use"
    SERVICE_OPERATION = "service_operation"


class AuditEventType(str, enum.Enum):
    MISSION_CREATED = "mission_created"
    ACTION_RECORDED = "action_recorded"
    POINTS_GRANTED = "points_granted"
    IDEMPOTENCY_REPLAYED = "idempotency_replayed"
    CAMPAIGN_CREATED = "campaign_created"
    CAMPAIGN_COMPLETED = "campaign_completed"
    CAMPAIGN_ENDED = "campaign_ended"
    REWARD_TEMPLATE_CREATED = "reward_template_created"
    REWARD_GENERATED = "reward_generated"
    REWARD_USED = "reward_used"
    REWARD_EXPIRED = "reward_expired"


class CampaignType(str, enum.Enum):
    INDIVIDUAL = "individual"
    GROUP = "group"
    CROSS_NETWORK = "cross_network"


class CampaignScopeType(str, enum.Enum):
    SINGLE_BUSINESS = "single_business"
    FANS_GROUP = "fans_group"
    PARTNER_NETWORK = "partner_network"


class CampaignParticipationMode(str, enum.Enum):
    AUTOMATIC = "automatic"
    EXPLICIT = "explicit"
    GROUP_MEMBERSHIP = "group_membership"


class CampaignProgressMetric(str, enum.Enum):
    POINTS = "points"
    QUANTITY = "quantity"
    ACTION_COUNT = "action_count"


class CampaignStatus(str, enum.Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    ENDED = "ended"


class RewardType(str, enum.Enum):
    GIFT = "gift"
    PERCENTAGE_DISCOUNT = "percentage_discount"
    FIXED_DISCOUNT = "fixed_discount"


class RewardStatus(str, enum.Enum):
    ACTIVE = "active"
    USED = "used"
    EXPIRED = "expired"


class RewardRedeemScope(str, enum.Enum):
    ISSUER_BUSINESS_ONLY = "issuer_business_only"
    CAMPAIGN_PARTICIPANTS = "campaign_participants"
    SELECTED_BUSINESSES = "selected_businesses"


class RewardSettlementPolicy(str, enum.Enum):
    ISSUER_PAYS = "issuer_pays"
    REDEEMER_PAYS = "redeemer_pays"
    SHARED_POOL = "shared_pool"
    PLATFORM_SETTLEMENT = "platform_settlement"


class RewardSettlementStatus(str, enum.Enum):
    NOT_REQUIRED = "not_required"
    PENDING = "pending"
    SETTLED = "settled"


class RewardGenerationSourceType(str, enum.Enum):
    INDIVIDUAL_CAMPAIGN_COMPLETION = "individual_campaign_completion"
    GROUP_CAMPAIGN_COMPLETION = "group_campaign_completion"
    EARLY_END_SETTLEMENT = "early_end_settlement"


def new_uuid() -> uuid.UUID:
    return uuid.uuid4()


def utc_now() -> datetime:
    return datetime.now(UTC)


def enum_values(enum_cls: type[enum.Enum]) -> list[str]:
    return [member.value for member in enum_cls]


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class Mission(Base, TimestampMixin):
    __tablename__ = "missions"
    __table_args__ = (CheckConstraint("point_value > 0", name="mission_point_value_positive"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    name: Mapped[str] = mapped_column(String(160))
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    mission_type: Mapped[MissionType] = mapped_column(
        Enum(MissionType, name="mission_type", values_callable=enum_values), index=True
    )
    point_value: Mapped[int] = mapped_column(Integer)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    action_items: Mapped[list["LoyaltyActionItem"]] = relationship(back_populates="mission")
    campaign_links: Mapped[list["CampaignMission"]] = relationship(back_populates="mission")


class Campaign(Base, TimestampMixin):
    __tablename__ = "campaigns"
    __table_args__ = (
        CheckConstraint("threshold_points > 0", name="campaign_threshold_points_positive"),
        CheckConstraint(
            "max_completions_per_customer IS NULL OR max_completions_per_customer > 0",
            name="campaign_max_completions_per_customer_positive",
        ),
        CheckConstraint("starts_at < ends_at", name="campaign_time_window_valid"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    creator_business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    name: Mapped[str] = mapped_column(String(160))
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    campaign_type: Mapped[CampaignType] = mapped_column(
        Enum(CampaignType, name="campaign_type", values_callable=enum_values),
        default=CampaignType.INDIVIDUAL,
        index=True,
    )
    scope_type: Mapped[CampaignScopeType] = mapped_column(
        Enum(CampaignScopeType, name="campaign_scope_type", values_callable=enum_values),
        default=CampaignScopeType.SINGLE_BUSINESS,
        index=True,
    )
    participation_mode: Mapped[CampaignParticipationMode] = mapped_column(
        Enum(
            CampaignParticipationMode,
            name="campaign_participation_mode",
            values_callable=enum_values,
        ),
        default=CampaignParticipationMode.AUTOMATIC,
    )
    progress_metric: Mapped[CampaignProgressMetric] = mapped_column(
        Enum(CampaignProgressMetric, name="campaign_progress_metric", values_callable=enum_values),
        default=CampaignProgressMetric.POINTS,
    )
    threshold_points: Mapped[int] = mapped_column(Integer)
    is_repeatable: Mapped[bool] = mapped_column(Boolean, default=False)
    max_completions_per_customer: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[CampaignStatus] = mapped_column(
        Enum(CampaignStatus, name="campaign_status", values_callable=enum_values),
        default=CampaignStatus.ACTIVE,
        index=True,
    )
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    ends_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)

    mission_links: Mapped[list["CampaignMission"]] = relationship(
        back_populates="campaign", cascade="all, delete-orphan"
    )
    reward_template_links: Mapped[list["CampaignRewardTemplate"]] = relationship(
        back_populates="campaign", cascade="all, delete-orphan"
    )
    completions: Mapped[list["CampaignCompletion"]] = relationship(back_populates="campaign")

    @property
    def reward_template_id(self) -> uuid.UUID | None:
        if not self.reward_template_links:
            return None
        return self.reward_template_links[0].reward_template_id

class CampaignMission(Base):
    __tablename__ = "campaign_missions"
    __table_args__ = (UniqueConstraint("campaign_id", "mission_id"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    campaign_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("campaigns.id"), index=True)
    mission_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("missions.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    campaign: Mapped["Campaign"] = relationship(back_populates="mission_links")
    mission: Mapped[Mission] = relationship(back_populates="campaign_links")


class CampaignRewardTemplate(Base):
    __tablename__ = "campaign_reward_templates"
    __table_args__ = (
        UniqueConstraint("campaign_id"),
        UniqueConstraint("campaign_id", "reward_template_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    campaign_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("campaigns.id"), index=True)
    reward_template_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("reward_templates.id"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    campaign: Mapped["Campaign"] = relationship(back_populates="reward_template_links")
    reward_template: Mapped["RewardTemplate"] = relationship(back_populates="campaign_links")


class CampaignCompletion(Base):
    __tablename__ = "campaign_completions"
    __table_args__ = (
        UniqueConstraint(
            "campaign_id",
            "customer_id",
            "completion_number",
            name="campaign_completion_cycle_unique",
        ),
        CheckConstraint("progress_points > 0", name="campaign_completion_progress_points_positive"),
        CheckConstraint(
            "threshold_points > 0", name="campaign_completion_threshold_points_positive"
        ),
        CheckConstraint("completion_number > 0", name="campaign_completion_number_positive"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    campaign_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("campaigns.id"), index=True)
    customer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    progress_points: Mapped[int] = mapped_column(Integer)
    threshold_points: Mapped[int] = mapped_column(Integer)
    completion_number: Mapped[int] = mapped_column(Integer, default=1)
    completed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    reward_generated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    campaign: Mapped[Campaign] = relationship(back_populates="completions")
    generated_rewards: Mapped[list["GeneratedReward"]] = relationship(
        back_populates="campaign_completion"
    )


class RewardTemplate(Base, TimestampMixin):
    __tablename__ = "reward_templates"
    __table_args__ = (
        CheckConstraint("valid_days > 0", name="reward_template_valid_days_positive"),
        CheckConstraint(
            "discount_percent IS NULL OR (discount_percent > 0 AND discount_percent <= 100)",
            name="reward_template_discount_percent_valid",
        ),
        CheckConstraint(
            "discount_amount_minor IS NULL OR discount_amount_minor > 0",
            name="reward_template_discount_amount_minor_positive",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    issuer_business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    name: Mapped[str] = mapped_column(String(160))
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    reward_type: Mapped[RewardType] = mapped_column(
        Enum(RewardType, name="reward_type", values_callable=enum_values), index=True
    )
    redeem_scope: Mapped[RewardRedeemScope] = mapped_column(
        Enum(RewardRedeemScope, name="reward_redeem_scope", values_callable=enum_values),
        default=RewardRedeemScope.ISSUER_BUSINESS_ONLY,
    )
    settlement_policy: Mapped[RewardSettlementPolicy] = mapped_column(
        Enum(
            RewardSettlementPolicy,
            name="reward_settlement_policy",
            values_callable=enum_values,
        ),
        default=RewardSettlementPolicy.ISSUER_PAYS,
    )
    gift_name: Mapped[str | None] = mapped_column(String(160), nullable=True)
    discount_percent: Mapped[int | None] = mapped_column(Integer, nullable=True)
    discount_amount_minor: Mapped[int | None] = mapped_column(Integer, nullable=True)
    currency_code: Mapped[str | None] = mapped_column(String(3), nullable=True)
    valid_days: Mapped[int] = mapped_column(Integer)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    campaign_links: Mapped[list["CampaignRewardTemplate"]] = relationship(
        back_populates="reward_template"
    )
    generated_rewards: Mapped[list["GeneratedReward"]] = relationship(
        back_populates="reward_template"
    )


class GeneratedReward(Base, TimestampMixin):
    __tablename__ = "generated_rewards"
    __table_args__ = (
        UniqueConstraint("source_type", "source_id", "customer_id"),
        CheckConstraint(
            "discount_percent IS NULL OR (discount_percent > 0 AND discount_percent <= 100)",
            name="generated_reward_discount_percent_valid",
        ),
        CheckConstraint(
            "discount_amount_minor IS NULL OR discount_amount_minor > 0",
            name="generated_reward_discount_amount_minor_positive",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    reward_template_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("reward_templates.id"), index=True
    )
    campaign_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("campaigns.id"), index=True)
    campaign_completion_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("campaign_completions.id"), nullable=True, index=True
    )
    source_type: Mapped[RewardGenerationSourceType] = mapped_column(
        Enum(
            RewardGenerationSourceType,
            name="reward_generation_source_type",
            values_callable=enum_values,
        ),
        index=True,
    )
    source_id: Mapped[uuid.UUID] = mapped_column(index=True)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    issuer_business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    customer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    reward_type: Mapped[RewardType] = mapped_column(
        Enum(RewardType, name="reward_type", values_callable=enum_values), index=True
    )
    redeem_scope: Mapped[RewardRedeemScope] = mapped_column(
        Enum(RewardRedeemScope, name="reward_redeem_scope", values_callable=enum_values)
    )
    settlement_policy: Mapped[RewardSettlementPolicy] = mapped_column(
        Enum(
            RewardSettlementPolicy,
            name="reward_settlement_policy",
            values_callable=enum_values,
        )
    )
    title: Mapped[str] = mapped_column(String(160))
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[RewardStatus] = mapped_column(
        Enum(RewardStatus, name="reward_status", values_callable=enum_values),
        default=RewardStatus.ACTIVE,
        index=True,
    )
    gift_name: Mapped[str | None] = mapped_column(String(160), nullable=True)
    discount_percent: Mapped[int | None] = mapped_column(Integer, nullable=True)
    discount_amount_minor: Mapped[int | None] = mapped_column(Integer, nullable=True)
    currency_code: Mapped[str | None] = mapped_column(String(3), nullable=True)
    issued_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    reward_template: Mapped[RewardTemplate] = relationship(back_populates="generated_rewards")
    campaign_completion: Mapped[CampaignCompletion | None] = relationship(
        back_populates="generated_rewards"
    )
    usage: Mapped["RewardUsage | None"] = relationship(back_populates="generated_reward")


class RewardUsage(Base):
    __tablename__ = "reward_usages"
    __table_args__ = (UniqueConstraint("generated_reward_id"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    generated_reward_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("generated_rewards.id"), index=True
    )
    redeemed_business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    issuer_business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    customer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    action_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("loyalty_actions.id"), index=True)
    used_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    note: Mapped[str | None] = mapped_column(String(500), nullable=True)
    settlement_status: Mapped[RewardSettlementStatus] = mapped_column(
        Enum(
            RewardSettlementStatus,
            name="reward_settlement_status",
            values_callable=enum_values,
        ),
        default=RewardSettlementStatus.NOT_REQUIRED,
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    generated_reward: Mapped[GeneratedReward] = relationship(back_populates="usage")


class LoyaltyAction(Base):
    __tablename__ = "loyalty_actions"
    __table_args__ = (UniqueConstraint("business_id", "idempotency_key"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    customer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    action_type: Mapped[LoyaltyActionType] = mapped_column(
        Enum(LoyaltyActionType, name="loyalty_action_type", values_callable=enum_values),
        default=LoyaltyActionType.MISSION_PROGRESS,
    )
    idempotency_key: Mapped[str] = mapped_column(String(120))
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    note: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    items: Mapped[list["LoyaltyActionItem"]] = relationship(back_populates="action")
    points_entries: Mapped[list["PointsLedgerEntry"]] = relationship(back_populates="action")


class LoyaltyActionItem(Base):
    __tablename__ = "loyalty_action_items"
    __table_args__ = (
        CheckConstraint("quantity > 0", name="loyalty_action_item_quantity_positive"),
        CheckConstraint("unit_points > 0", name="loyalty_action_item_unit_points_positive"),
        CheckConstraint("total_points > 0", name="loyalty_action_item_total_points_positive"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    action_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("loyalty_actions.id"), index=True)
    mission_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("missions.id"), index=True)
    quantity: Mapped[int] = mapped_column(Integer)
    unit_points: Mapped[int] = mapped_column(Integer)
    total_points: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    action: Mapped[LoyaltyAction] = relationship(back_populates="items")
    mission: Mapped[Mission] = relationship(back_populates="action_items")
    points_entries: Mapped[list["PointsLedgerEntry"]] = relationship(back_populates="action_item")


class PointsLedgerEntry(Base):
    __tablename__ = "points_ledger"
    __table_args__ = (CheckConstraint("points > 0", name="points_ledger_points_positive"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    customer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    action_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("loyalty_actions.id"), index=True)
    action_item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("loyalty_action_items.id"), index=True
    )
    points: Mapped[int] = mapped_column(Integer)
    reason: Mapped[str] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    action: Mapped[LoyaltyAction] = relationship(back_populates="points_entries")
    action_item: Mapped[LoyaltyActionItem] = relationship(back_populates="points_entries")


class AuditEvent(Base):
    __tablename__ = "audit_events"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    event_type: Mapped[AuditEventType] = mapped_column(
        Enum(AuditEventType, name="audit_event_type", values_callable=enum_values), index=True
    )
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    business_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("businesses.id"), nullable=True, index=True
    )
    entity_type: Mapped[str] = mapped_column(String(80))
    entity_id: Mapped[uuid.UUID] = mapped_column(index=True)
    event_metadata: Mapped[dict[str, Any]] = mapped_column("metadata", JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
