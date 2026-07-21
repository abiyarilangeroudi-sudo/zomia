import hashlib
import secrets
import uuid
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status

from app.modules.identity.models import User, UserRole
from app.modules.loyalty.models import LoyaltyAction, LoyaltyActionType
from app.modules.loyalty.schemas import RegisterActionRequest, UseRewardRequest
from app.modules.loyalty.service import LoyaltyService
from app.modules.qr.models import CustomerQrToken, CustomerQrTokenStatus
from app.modules.qr.repository import QrRepository
from app.modules.qr.schemas import (
    CustomerQrTokenRead,
    RegisterActionByQrRequest,
    RegisterActionByQrResponse,
    ResolveQrRequest,
    StaffRecentActionRead,
    StaffServiceCustomerRead,
    StaffServiceMissionRead,
    StaffServiceSummary,
    UseRewardByQrRequest,
    UseRewardByQrResponse,
)


class QrService:
    token_ttl_days = 90

    def __init__(self, repository: QrRepository, loyalty_service: LoyaltyService) -> None:
        self.repository = repository
        self.loyalty_service = loyalty_service

    def issue_customer_token(self, customer: User) -> CustomerQrTokenRead:
        self._require_role(customer, UserRole.CUSTOMER)
        now = datetime.now(UTC)
        raw_token = self._new_raw_token()
        self.repository.revoke_active_tokens_for_customer(customer_id=customer.id, revoked_at=now)
        token = self.repository.add_token(
            CustomerQrToken(
                customer_id=customer.id,
                token_hash=self._hash_token(raw_token),
                status=CustomerQrTokenStatus.ACTIVE,
                expires_at=now + timedelta(days=self.token_ttl_days),
            )
        )
        return CustomerQrTokenRead(
            token=raw_token,
            qr_payload=f"zomia://customer/{raw_token}",
            expires_at=token.expires_at,
        )

    def rotate_customer_token(self, customer: User) -> CustomerQrTokenRead:
        return self.issue_customer_token(customer)

    def resolve_qr(self, staff: User, payload: ResolveQrRequest) -> StaffServiceSummary:
        customer = self._resolve_customer_from_token(
            staff=staff,
            business_id=payload.business_id,
            raw_token=payload.token,
        )
        return self._service_summary(business_id=payload.business_id, customer=customer)

    def list_service_missions(
        self, staff: User, business_id: uuid.UUID
    ) -> list[StaffServiceMissionRead]:
        missions = self.loyalty_service.list_staff_missions(staff, business_id)
        return [StaffServiceMissionRead.model_validate(mission) for mission in missions]

    def list_staff_recent_actions(
        self, staff: User, business_id: uuid.UUID, limit: int = 20
    ) -> list[StaffRecentActionRead]:
        self._require_active_staff_membership(staff=staff, business_id=business_id)
        return [
            StaffRecentActionRead(
                id=action.id,
                action_type=action.action_type.value,
                customer_name=customer.full_name,
                points_granted=sum(entry.points for entry in action.points_entries),
                summary=self._activity_summary(action),
                occurred_at=action.occurred_at,
                created_at=action.created_at,
            )
            for action, customer in self.repository.list_recent_actions_for_staff(
                business_id=business_id,
                staff_id=staff.id,
                limit=limit,
            )
        ]

    def register_action_by_qr(
        self, staff: User, payload: RegisterActionByQrRequest
    ) -> RegisterActionByQrResponse:
        customer = self._resolve_customer_from_token(
            staff=staff,
            business_id=payload.business_id,
            raw_token=payload.qr_token,
        )
        action = self.loyalty_service.register_action(
            staff,
            RegisterActionRequest(
                business_id=payload.business_id,
                customer_id=customer.id,
                idempotency_key=payload.idempotency_key,
                note=payload.note,
                items=payload.items,
            ),
        )
        return RegisterActionByQrResponse(
            action=action,
            summary=self._service_summary(business_id=payload.business_id, customer=customer),
        )

    def use_reward_by_qr(
        self, staff: User, reward_id: uuid.UUID, payload: UseRewardByQrRequest
    ) -> UseRewardByQrResponse:
        customer = self._resolve_customer_from_token(
            staff=staff,
            business_id=payload.business_id,
            raw_token=payload.qr_token,
        )
        self.loyalty_service.validate_reward_customer(reward_id, customer.id)

        reward_use = self.loyalty_service.use_reward(
            staff,
            reward_id,
            UseRewardRequest(
                business_id=payload.business_id,
                idempotency_key=payload.idempotency_key,
                note=payload.note,
            ),
        )
        return UseRewardByQrResponse(
            reward_use=reward_use,
            summary=self._service_summary(business_id=payload.business_id, customer=customer),
        )

    def _resolve_customer_from_token(
        self, *, staff: User, business_id: uuid.UUID, raw_token: str
    ) -> User:
        self._require_active_staff_membership(staff=staff, business_id=business_id)

        token = self.repository.get_token_by_hash(self._hash_token(raw_token))
        if token is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="QR token not found")
        if token.status != CustomerQrTokenStatus.ACTIVE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="QR token is not active"
            )

        now = datetime.now(UTC)
        if self._as_utc(token.expires_at) <= now:
            self.repository.expire_token(token, now)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="QR token is expired"
            )

        customer = token.customer
        if not self.repository.is_customer(customer):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

        self.repository.mark_token_used(token, now)
        return customer

    def _require_active_staff_membership(self, *, staff: User, business_id: uuid.UUID) -> None:
        self._require_role(staff, UserRole.STAFF)
        if (
            self.repository.get_staff_membership(business_id=business_id, staff_user_id=staff.id)
            is None
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Staff does not belong to this business",
            )

    def _service_summary(self, *, business_id: uuid.UUID, customer: User) -> StaffServiceSummary:
        points = self.loyalty_service.get_customer_points(customer, business_id).points
        rewards = [
            reward
            for reward in self.loyalty_service.list_customer_rewards(customer, business_id)
            if reward.status.value == "active"
        ]
        recent_actions = [
            StaffRecentActionRead(
                id=action.id,
                action_type=action.action_type.value,
                customer_name=customer.full_name,
                points_granted=sum(entry.points for entry in action.points_entries),
                summary=self._activity_summary(action),
                occurred_at=action.occurred_at,
                created_at=action.created_at,
            )
            for action in self.repository.list_recent_actions(
                business_id=business_id, customer_id=customer.id
            )
        ]
        return StaffServiceSummary(
            business_id=business_id,
            customer=StaffServiceCustomerRead.model_validate(customer),
            points=points,
            active_rewards=rewards,
            recent_actions=recent_actions,
        )

    @staticmethod
    def _hash_token(raw_token: str) -> str:
        return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()

    @staticmethod
    def _new_raw_token() -> str:
        return secrets.token_urlsafe(32)

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _require_role(user: User, role: UserRole) -> None:
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")

    @staticmethod
    def _activity_summary(action: LoyaltyAction) -> str:
        if action.action_type == LoyaltyActionType.REWARD_USE:
            return "Reward used"
        if action.action_type == LoyaltyActionType.MISSION_PROGRESS:
            items = []
            for item in action.items:
                mission_name = item.mission.name if item.mission is not None else "Mission"
                items.append(f"{mission_name} x{item.quantity}")
            return ", ".join(items) if items else "Mission progress"
        return action.action_type.value.replace("_", " ").title()
