import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.modules.identity.models import StaffMember, User, UserRole
from app.modules.loyalty.models import GeneratedReward, LoyaltyAction, RewardStatus
from app.modules.qr.models import CustomerQrToken, CustomerQrTokenStatus


class QrRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_active_token_for_customer(self, customer_id: uuid.UUID) -> CustomerQrToken | None:
        return self.db.scalar(
            select(CustomerQrToken).where(
                CustomerQrToken.customer_id == customer_id,
                CustomerQrToken.status == CustomerQrTokenStatus.ACTIVE,
            )
        )

    def revoke_active_tokens_for_customer(
        self, *, customer_id: uuid.UUID, revoked_at: datetime
    ) -> None:
        tokens = self.db.scalars(
            select(CustomerQrToken).where(
                CustomerQrToken.customer_id == customer_id,
                CustomerQrToken.status == CustomerQrTokenStatus.ACTIVE,
            )
        )
        for token in tokens:
            token.status = CustomerQrTokenStatus.REVOKED
            token.revoked_at = revoked_at
        self.db.flush()

    def add_token(self, token: CustomerQrToken) -> CustomerQrToken:
        self.db.add(token)
        self.db.flush()
        return token

    def get_token_by_hash(self, token_hash: str) -> CustomerQrToken | None:
        return self.db.scalar(
            select(CustomerQrToken)
            .where(CustomerQrToken.token_hash == token_hash)
            .options(selectinload(CustomerQrToken.customer))
        )

    def mark_token_used(self, token: CustomerQrToken, used_at: datetime) -> CustomerQrToken:
        token.last_used_at = used_at
        self.db.flush()
        return token

    def expire_token(self, token: CustomerQrToken, expired_at: datetime) -> CustomerQrToken:
        token.status = CustomerQrTokenStatus.EXPIRED
        token.revoked_at = expired_at
        self.db.flush()
        return token

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

    def list_active_rewards_for_customer(
        self, *, business_id: uuid.UUID, customer_id: uuid.UUID
    ) -> list[GeneratedReward]:
        return list(
            self.db.scalars(
                select(GeneratedReward)
                .where(
                    GeneratedReward.business_id == business_id,
                    GeneratedReward.customer_id == customer_id,
                    GeneratedReward.status == RewardStatus.ACTIVE,
                )
                .order_by(GeneratedReward.issued_at.desc())
            )
        )

    def list_recent_actions(
        self, *, business_id: uuid.UUID, customer_id: uuid.UUID, limit: int = 5
    ) -> list[LoyaltyAction]:
        return list(
            self.db.scalars(
                select(LoyaltyAction)
                .where(
                    LoyaltyAction.business_id == business_id,
                    LoyaltyAction.customer_id == customer_id,
                )
                .order_by(LoyaltyAction.created_at.desc())
                .limit(limit)
            )
        )

    @staticmethod
    def is_customer(user: User) -> bool:
        return user.is_active and user.role == UserRole.CUSTOMER
