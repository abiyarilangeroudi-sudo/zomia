import enum
import uuid
from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class UserRole(str, enum.Enum):
    CUSTOMER = "customer"
    OWNER = "owner"
    STAFF = "staff"
    ADMIN = "admin"


class BusinessStatus(str, enum.Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"


def new_uuid() -> uuid.UUID:
    return uuid.uuid4()


def utc_now() -> datetime:
    return datetime.now(UTC)


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    phone: Mapped[str | None] = mapped_column(String(32), unique=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    full_name: Mapped[str] = mapped_column(String(120))
    role: Mapped[UserRole] = mapped_column(Enum(UserRole, name="user_role"), index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    owned_businesses: Mapped[list["Business"]] = relationship(back_populates="owner")
    staff_memberships: Mapped[list["StaffMember"]] = relationship(back_populates="user")


class Business(Base, TimestampMixin):
    __tablename__ = "businesses"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(160))
    legal_name: Mapped[str | None] = mapped_column(String(180), nullable=True)
    slug: Mapped[str] = mapped_column(String(180), unique=True, index=True)
    category: Mapped[str | None] = mapped_column(String(80), nullable=True)
    public_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    public_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    website_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    address_line1: Mapped[str | None] = mapped_column(String(180), nullable=True)
    address_line2: Mapped[str | None] = mapped_column(String(180), nullable=True)
    city: Mapped[str | None] = mapped_column(String(120), nullable=True)
    region: Mapped[str | None] = mapped_column(String(120), nullable=True)
    postal_code: Mapped[str | None] = mapped_column(String(32), nullable=True)
    country_code: Mapped[str] = mapped_column(String(2), default="DE")
    timezone: Mapped[str] = mapped_column(String(64), default="Europe/Berlin")
    currency_code: Mapped[str] = mapped_column(String(3), default="EUR")
    status: Mapped[BusinessStatus] = mapped_column(
        Enum(BusinessStatus, name="business_status"), default=BusinessStatus.ACTIVE
    )

    owner: Mapped[User] = relationship(back_populates="owned_businesses")
    staff_members: Mapped[list["StaffMember"]] = relationship(back_populates="business")


class StaffMember(Base, TimestampMixin):
    __tablename__ = "staff_members"
    __table_args__ = (UniqueConstraint("business_id", "user_id"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=new_uuid)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    business: Mapped[Business] = relationship(back_populates="staff_members")
    user: Mapped[User] = relationship(back_populates="staff_memberships")
