import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.modules.identity.schemas import UserRead
from app.modules.loyalty.schemas import (
    ActionItemCreate,
    GeneratedRewardRead,
    RegisterActionResponse,
    UseRewardResponse,
)


class CustomerQrTokenRead(BaseModel):
    token: str
    qr_payload: str
    expires_at: datetime


class ResolveQrRequest(BaseModel):
    business_id: uuid.UUID
    token: str = Field(min_length=24, max_length=256)


class StaffServiceSummary(BaseModel):
    business_id: uuid.UUID
    customer: UserRead
    points: int
    active_rewards: list[GeneratedRewardRead]
    recent_actions: list[dict] = Field(default_factory=list)


class RegisterActionByQrRequest(BaseModel):
    business_id: uuid.UUID
    qr_token: str = Field(min_length=24, max_length=256)
    idempotency_key: str = Field(min_length=8, max_length=120)
    items: list[ActionItemCreate] = Field(min_length=1)
    note: str | None = Field(default=None, max_length=500)


class RegisterActionByQrResponse(BaseModel):
    action: RegisterActionResponse
    summary: StaffServiceSummary


class UseRewardByQrRequest(BaseModel):
    business_id: uuid.UUID
    qr_token: str = Field(min_length=24, max_length=256)
    idempotency_key: str = Field(min_length=8, max_length=120)
    note: str | None = Field(default=None, max_length=500)


class UseRewardByQrResponse(BaseModel):
    reward_use: UseRewardResponse
    summary: StaffServiceSummary
