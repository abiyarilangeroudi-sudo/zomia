import uuid

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.modules.identity.models import Business, StaffMember, User, UserRole
from app.modules.loyalty.models import (
    AuditEvent,
    LoyaltyAction,
    LoyaltyActionItem,
    Mission,
    PointsLedgerEntry,
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

