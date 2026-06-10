from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status

from app.modules.identity.models import User, UserRole
from app.modules.loyalty.models import (
    AuditEvent,
    AuditEventType,
    LoyaltyAction,
    LoyaltyActionItem,
    LoyaltyActionType,
    Mission,
    PointsLedgerEntry,
)
from app.modules.loyalty.repository import LoyaltyRepository
from app.modules.loyalty.schemas import (
    CustomerPointsRead,
    MissionCreate,
    RegisterActionRequest,
    RegisterActionResponse,
)


class LoyaltyService:
    def __init__(self, repository: LoyaltyRepository) -> None:
        self.repository = repository

    def create_mission(self, owner: User, payload: MissionCreate) -> Mission:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=payload.business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

        mission = Mission(
            business_id=payload.business_id,
            name=payload.name,
            description=payload.description,
            mission_type=payload.mission_type,
            point_value=payload.point_value,
        )
        self.repository.add_mission(mission)
        self._audit(
            event_type=AuditEventType.MISSION_CREATED,
            actor_user_id=owner.id,
            business_id=payload.business_id,
            entity_type="mission",
            entity_id=mission.id,
            metadata={"mission_type": payload.mission_type.value, "point_value": payload.point_value},
        )
        return mission

    def list_missions(self, owner: User, business_id) -> list[Mission]:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(business_id=business_id, owner_id=owner.id)
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        return self.repository.list_business_missions(business_id)

    def register_action(
        self, staff: User, payload: RegisterActionRequest
    ) -> RegisterActionResponse:
        self._require_role(staff, UserRole.STAFF)
        if self.repository.get_staff_membership(
            business_id=payload.business_id, staff_user_id=staff.id
        ) is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Staff does not belong to this business",
            )

        existing_action = self.repository.get_action_by_idempotency_key(
            business_id=payload.business_id, idempotency_key=payload.idempotency_key
        )
        if existing_action is not None:
            self._audit(
                event_type=AuditEventType.IDEMPOTENCY_REPLAYED,
                actor_user_id=staff.id,
                business_id=payload.business_id,
                entity_type="loyalty_action",
                entity_id=existing_action.id,
                metadata={"idempotency_key": payload.idempotency_key},
            )
            return self._action_response(existing_action, idempotency_replayed=True)

        customer = self.repository.get_user(payload.customer_id)
        if not self.repository.is_customer(customer):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

        mission_ids = {item.mission_id for item in payload.items}
        missions = self.repository.get_active_missions_by_ids(
            business_id=payload.business_id, mission_ids=mission_ids
        )
        missing_missions = mission_ids - set(missions)
        if missing_missions:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="One or more missions were not found",
            )

        action = self.repository.add_action(
            LoyaltyAction(
                business_id=payload.business_id,
                customer_id=payload.customer_id,
                staff_id=staff.id,
                action_type=LoyaltyActionType.MISSION_PROGRESS,
                idempotency_key=payload.idempotency_key,
                occurred_at=payload.occurred_at or datetime.now(UTC),
                note=payload.note,
            )
        )

        created_items: list[LoyaltyActionItem] = []
        for item_payload in payload.items:
            mission = missions[item_payload.mission_id]
            total_points = item_payload.quantity * mission.point_value
            action_item = self.repository.add_action_item(
                LoyaltyActionItem(
                    action_id=action.id,
                    mission_id=mission.id,
                    quantity=item_payload.quantity,
                    unit_points=mission.point_value,
                    total_points=total_points,
                )
            )
            created_items.append(action_item)
            self.repository.add_points_entry(
                PointsLedgerEntry(
                    business_id=payload.business_id,
                    customer_id=payload.customer_id,
                    action_id=action.id,
                    action_item_id=action_item.id,
                    points=total_points,
                    reason="mission_action",
                )
            )

        points_granted = sum(item.total_points for item in created_items)
        self._audit(
            event_type=AuditEventType.ACTION_RECORDED,
            actor_user_id=staff.id,
            business_id=payload.business_id,
            entity_type="loyalty_action",
            entity_id=action.id,
            metadata={
                "customer_id": str(payload.customer_id),
                "items_count": len(action.items),
                "points_granted": points_granted,
            },
        )
        self._audit(
            event_type=AuditEventType.POINTS_GRANTED,
            actor_user_id=staff.id,
            business_id=payload.business_id,
            entity_type="loyalty_action",
            entity_id=action.id,
            metadata={"customer_id": str(payload.customer_id), "points_granted": points_granted},
        )
        return self._action_response(
            action, idempotency_replayed=False, items=created_items
        )

    def get_customer_points(self, customer: User, business_id) -> CustomerPointsRead:
        self._require_role(customer, UserRole.CUSTOMER)
        points = self.repository.sum_customer_points(
            business_id=business_id, customer_id=customer.id
        )
        return CustomerPointsRead(business_id=business_id, customer_id=customer.id, points=points)

    def _audit(
        self,
        *,
        event_type: AuditEventType,
        actor_user_id,
        business_id,
        entity_type: str,
        entity_id,
        metadata: dict[str, Any],
    ) -> None:
        self.repository.add_audit_event(
            AuditEvent(
                event_type=event_type,
                actor_user_id=actor_user_id,
                business_id=business_id,
                entity_type=entity_type,
                entity_id=entity_id,
                event_metadata=metadata,
            )
        )

    @staticmethod
    def _action_response(
        action: LoyaltyAction,
        *,
        idempotency_replayed: bool,
        items: list[LoyaltyActionItem] | None = None,
    ) -> RegisterActionResponse:
        action_items = list(action.items if items is None else items)
        return RegisterActionResponse(
            action_id=action.id,
            action_type=action.action_type,
            points_granted=sum(item.total_points for item in action_items),
            idempotency_replayed=idempotency_replayed,
            items=action_items,
        )

    @staticmethod
    def _require_role(user: User, role: UserRole) -> None:
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
