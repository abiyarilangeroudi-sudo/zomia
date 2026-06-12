import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.modules.loyalty.models import (
    CampaignParticipationMode,
    CampaignProgressMetric,
    CampaignScopeType,
    CampaignStatus,
    CampaignType,
    LoyaltyActionType,
    MissionType,
    RewardRedeemScope,
    RewardGenerationSourceType,
    RewardSettlementPolicy,
    RewardSettlementStatus,
    RewardStatus,
    RewardType,
)


class MissionCreate(BaseModel):
    business_id: uuid.UUID
    name: str = Field(min_length=2, max_length=160)
    description: str | None = Field(default=None, max_length=500)
    mission_type: MissionType
    point_value: int = Field(gt=0)


class MissionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    business_id: uuid.UUID
    name: str
    description: str | None
    mission_type: MissionType
    point_value: int
    is_active: bool
    created_at: datetime


class ActionItemCreate(BaseModel):
    mission_id: uuid.UUID
    quantity: int = Field(gt=0)


class RegisterActionRequest(BaseModel):
    business_id: uuid.UUID
    customer_id: uuid.UUID
    idempotency_key: str = Field(min_length=8, max_length=120)
    occurred_at: datetime | None = None
    note: str | None = Field(default=None, max_length=500)
    items: list[ActionItemCreate] = Field(min_length=1)


class ActionItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    mission_id: uuid.UUID
    quantity: int
    unit_points: int
    total_points: int


class RegisterActionResponse(BaseModel):
    action_id: uuid.UUID
    action_type: LoyaltyActionType
    points_granted: int
    idempotency_replayed: bool
    items: list[ActionItemRead]


class CustomerPointsRead(BaseModel):
    business_id: uuid.UUID
    customer_id: uuid.UUID
    points: int


class CustomerBusinessStatusRead(BaseModel):
    business_id: uuid.UUID
    business_name: str
    rewards: list["GeneratedRewardRead"]


class CustomerStatusRead(BaseModel):
    customer_id: uuid.UUID
    active_rewards_count: int
    businesses: list[CustomerBusinessStatusRead]


class CampaignCreate(BaseModel):
    creator_business_id: uuid.UUID
    name: str = Field(min_length=2, max_length=160)
    description: str | None = Field(default=None, max_length=500)
    threshold_points: int = Field(gt=0)
    starts_at: datetime
    ends_at: datetime
    mission_ids: list[uuid.UUID] = Field(min_length=1)

    @model_validator(mode="after")
    def validate_time_window(self) -> "CampaignCreate":
        if self.starts_at >= self.ends_at:
            raise ValueError("starts_at must be before ends_at")
        return self


class CampaignRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    creator_business_id: uuid.UUID
    name: str
    description: str | None
    campaign_type: CampaignType
    scope_type: CampaignScopeType
    participation_mode: CampaignParticipationMode
    progress_metric: CampaignProgressMetric
    threshold_points: int
    is_repeatable: bool
    max_completions_per_customer: int
    status: CampaignStatus
    starts_at: datetime
    ends_at: datetime
    created_at: datetime


class CampaignProgressRead(BaseModel):
    campaign_id: uuid.UUID
    customer_id: uuid.UUID
    progress_points: int
    threshold_points: int
    is_completed: bool


class CustomerCampaignProgressRead(BaseModel):
    business_id: uuid.UUID
    business_name: str
    campaign_id: uuid.UUID
    campaign_name: str
    progress_points: int
    threshold_points: int
    remaining_points: int
    is_completed: bool


class RewardTemplateCreate(BaseModel):
    business_id: uuid.UUID
    campaign_id: uuid.UUID
    name: str = Field(min_length=2, max_length=160)
    description: str | None = Field(default=None, max_length=500)
    reward_type: RewardType
    gift_name: str | None = Field(default=None, max_length=160)
    discount_percent: int | None = Field(default=None, gt=0, le=100)
    discount_amount_minor: int | None = Field(default=None, gt=0)
    currency_code: str | None = Field(default=None, min_length=3, max_length=3)
    valid_days: int = Field(gt=0)

    @model_validator(mode="after")
    def validate_reward_fields(self) -> "RewardTemplateCreate":
        if self.reward_type == RewardType.GIFT:
            if not self.gift_name:
                raise ValueError("gift_name is required for gift rewards")
            if self.discount_percent is not None or self.discount_amount_minor is not None:
                raise ValueError("discount fields are not allowed for gift rewards")
        if self.reward_type == RewardType.PERCENTAGE_DISCOUNT:
            if self.discount_percent is None:
                raise ValueError("discount_percent is required for percentage discounts")
            if self.gift_name is not None or self.discount_amount_minor is not None:
                raise ValueError("gift_name and discount_amount_minor are not allowed")
        if self.reward_type == RewardType.FIXED_DISCOUNT:
            if self.discount_amount_minor is None or self.currency_code is None:
                raise ValueError("discount_amount_minor and currency_code are required")
            if self.gift_name is not None or self.discount_percent is not None:
                raise ValueError("gift_name and discount_percent are not allowed")
        if self.reward_type != RewardType.FIXED_DISCOUNT and self.currency_code is not None:
            raise ValueError("currency_code is only allowed for fixed discounts")
        if self.currency_code is not None:
            self.currency_code = self.currency_code.upper()
        return self


class RewardTemplateRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    business_id: uuid.UUID
    issuer_business_id: uuid.UUID
    campaign_id: uuid.UUID
    name: str
    description: str | None
    reward_type: RewardType
    redeem_scope: RewardRedeemScope
    settlement_policy: RewardSettlementPolicy
    gift_name: str | None
    discount_percent: int | None
    discount_amount_minor: int | None
    currency_code: str | None
    valid_days: int
    is_active: bool
    created_at: datetime


class GeneratedRewardRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    reward_template_id: uuid.UUID
    campaign_id: uuid.UUID
    campaign_completion_id: uuid.UUID | None
    source_type: RewardGenerationSourceType
    source_id: uuid.UUID
    business_id: uuid.UUID
    issuer_business_id: uuid.UUID
    customer_id: uuid.UUID
    reward_type: RewardType
    redeem_scope: RewardRedeemScope
    settlement_policy: RewardSettlementPolicy
    title: str
    description: str | None
    status: RewardStatus
    gift_name: str | None
    discount_percent: int | None
    discount_amount_minor: int | None
    currency_code: str | None
    issued_at: datetime
    expires_at: datetime
    used_at: datetime | None


class UseRewardRequest(BaseModel):
    business_id: uuid.UUID
    idempotency_key: str = Field(min_length=8, max_length=120)
    note: str | None = Field(default=None, max_length=500)


class RewardUsageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    generated_reward_id: uuid.UUID
    redeemed_business_id: uuid.UUID
    issuer_business_id: uuid.UUID
    customer_id: uuid.UUID
    staff_id: uuid.UUID
    action_id: uuid.UUID
    used_at: datetime
    note: str | None
    settlement_status: RewardSettlementStatus


class UseRewardResponse(BaseModel):
    reward: GeneratedRewardRead
    usage: RewardUsageRead
    idempotency_replayed: bool
