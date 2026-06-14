import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.modules.identity.models import BusinessStatus, UserRole


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=120)
    phone: str | None = Field(default=None, max_length=32)


class OwnerRegister(UserCreate):
    business_name: str = Field(min_length=2, max_length=160)
    business_category: str | None = Field(default=None, max_length=80)
    public_phone: str | None = Field(default=None, max_length=32)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    phone: str | None
    full_name: str
    role: UserRole
    is_active: bool
    created_at: datetime


class CustomerProfileUpdate(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)


class BusinessCreate(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    legal_name: str | None = Field(default=None, max_length=180)
    category: str | None = Field(default=None, max_length=80)
    public_email: EmailStr | None = None
    public_phone: str | None = Field(default=None, max_length=32)
    website_url: str | None = Field(default=None, max_length=500)
    address_line1: str | None = Field(default=None, max_length=180)
    address_line2: str | None = Field(default=None, max_length=180)
    city: str | None = Field(default=None, max_length=120)
    region: str | None = Field(default=None, max_length=120)
    postal_code: str | None = Field(default=None, max_length=32)
    country_code: str = Field(default="DE", min_length=2, max_length=2)
    timezone: str = Field(default="Europe/Berlin", max_length=64)
    currency_code: str = Field(default="EUR", min_length=3, max_length=3)


class BusinessRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_id: uuid.UUID
    name: str
    legal_name: str | None
    slug: str
    category: str | None
    public_email: EmailStr | None
    public_phone: str | None
    website_url: str | None
    address_line1: str | None
    address_line2: str | None
    city: str | None
    region: str | None
    postal_code: str | None
    country_code: str
    timezone: str
    currency_code: str
    status: BusinessStatus
    created_at: datetime


class StaffCreate(UserCreate):
    business_id: uuid.UUID


class StaffUpdate(BaseModel):
    is_active: bool


class StaffRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    business_id: uuid.UUID
    user_id: uuid.UUID
    is_active: bool
    created_at: datetime
    user: UserRead


class StaffContextBusinessRead(BaseModel):
    id: uuid.UUID
    name: str
    slug: str
    status: BusinessStatus
    timezone: str
    currency_code: str
    staff_membership_id: uuid.UUID


class StaffContextRead(BaseModel):
    staff: UserRead
    businesses: list[StaffContextBusinessRead]
