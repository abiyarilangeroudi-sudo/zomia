import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.modules.identity.business_categories import BUSINESS_CATEGORIES
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

    @field_validator("business_category")
    @classmethod
    def validate_business_category(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip().lower()
        if normalized not in BUSINESS_CATEGORIES:
            raise ValueError("Unsupported business category")
        return normalized


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class EmailVerificationConfirm(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class PendingRegistrationRead(BaseModel):
    email: EmailStr
    expires_at: datetime


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=24, max_length=256)


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    phone: str | None
    full_name: str
    role: UserRole
    is_active: bool
    email_verified_at: datetime | None
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

    @field_validator("category")
    @classmethod
    def validate_category(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip().lower()
        if normalized not in BUSINESS_CATEGORIES:
            raise ValueError("Unsupported business category")
        return normalized


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
