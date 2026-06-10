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
