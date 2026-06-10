import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.modules.loyalty.models import LoyaltyActionType, MissionType


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

