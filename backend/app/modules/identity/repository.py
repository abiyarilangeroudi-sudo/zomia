import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.modules.identity.models import (
    Business,
    EmailVerificationOtp,
    RefreshToken,
    StaffInvitation,
    StaffInvitationStatus,
    StaffMember,
    User,
)
from app.modules.qr.models import CustomerQrToken, CustomerQrTokenStatus


class IdentityRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_user_by_id(self, user_id: uuid.UUID) -> User | None:
        return self.db.get(User, user_id)

    def get_user_by_email(self, email: str) -> User | None:
        return self.db.scalar(select(User).where(User.email == email.lower()))

    def add_user(self, user: User) -> User:
        self.db.add(user)
        self.db.flush()
        return user

    def update_user_full_name(self, *, user: User, full_name: str) -> User:
        user.full_name = full_name
        self.db.flush()
        return user

    def update_user_password_hash(self, *, user: User, password_hash: str) -> User:
        user.password_hash = password_hash
        self.db.flush()
        return user

    def increment_user_session_version(self, *, user: User) -> User:
        user.session_version += 1
        self.db.flush()
        return user

    def update_user_email(self, *, user: User, email: str, email_verified_at) -> User:
        user.email = email.lower()
        user.email_verified_at = email_verified_at
        self.db.flush()
        return user

    def anonymize_customer_account(
        self, *, user: User, email: str, full_name: str, password_hash: str
    ) -> User:
        user.email = email.lower()
        user.phone = None
        user.full_name = full_name
        user.password_hash = password_hash
        user.email_verified_at = None
        user.is_active = False
        self.db.flush()
        return user

    def add_refresh_token(self, refresh_token: RefreshToken) -> RefreshToken:
        self.db.add(refresh_token)
        self.db.flush()
        return refresh_token

    def add_email_verification_otp(self, otp: EmailVerificationOtp) -> EmailVerificationOtp:
        self.db.add(otp)
        self.db.flush()
        return otp

    def get_latest_email_verification_otp(
        self, *, email: str, purpose: str
    ) -> EmailVerificationOtp | None:
        return self.db.scalar(
            select(EmailVerificationOtp)
            .where(
                EmailVerificationOtp.email == email.lower(),
                EmailVerificationOtp.purpose == purpose,
                EmailVerificationOtp.consumed_at.is_(None),
            )
            .order_by(EmailVerificationOtp.created_at.desc())
        )

    def get_email_verification_otp_by_hash(
        self, *, code_hash: str, purpose: str
    ) -> EmailVerificationOtp | None:
        return self.db.scalar(
            select(EmailVerificationOtp).where(
                EmailVerificationOtp.code_hash == code_hash,
                EmailVerificationOtp.purpose == purpose,
                EmailVerificationOtp.consumed_at.is_(None),
            )
        )

    def list_active_email_verification_otps(
        self, *, purpose: str, now
    ) -> list[EmailVerificationOtp]:
        return list(
            self.db.scalars(
                select(EmailVerificationOtp).where(
                    EmailVerificationOtp.purpose == purpose,
                    EmailVerificationOtp.consumed_at.is_(None),
                    EmailVerificationOtp.expires_at > now,
                )
            )
        )

    def get_refresh_token_by_hash(self, token_hash: str) -> RefreshToken | None:
        return self.db.scalar(
            select(RefreshToken)
            .where(RefreshToken.token_hash == token_hash)
            .options(selectinload(RefreshToken.user))
        )

    def revoke_refresh_token(self, *, refresh_token: RefreshToken, revoked_at) -> RefreshToken:
        refresh_token.revoked_at = revoked_at
        self.db.flush()
        return refresh_token

    def revoke_user_refresh_tokens(self, *, user_id: uuid.UUID, revoked_at) -> None:
        refresh_tokens = self.db.scalars(
            select(RefreshToken).where(
                RefreshToken.user_id == user_id,
                RefreshToken.revoked_at.is_(None),
            )
        )
        for refresh_token in refresh_tokens:
            refresh_token.revoked_at = revoked_at
        self.db.flush()

    def revoke_customer_qr_tokens(self, *, customer_id: uuid.UUID, revoked_at) -> None:
        qr_tokens = self.db.scalars(
            select(CustomerQrToken).where(
                CustomerQrToken.customer_id == customer_id,
                CustomerQrToken.status == CustomerQrTokenStatus.ACTIVE,
            )
        )
        for token in qr_tokens:
            token.status = CustomerQrTokenStatus.REVOKED
            token.revoked_at = revoked_at
        self.db.flush()

    def add_business(self, business: Business) -> Business:
        self.db.add(business)
        self.db.flush()
        return business

    def get_business_by_slug(self, slug: str) -> Business | None:
        return self.db.scalar(select(Business).where(Business.slug == slug))

    def list_owner_businesses(self, owner_id: uuid.UUID) -> list[Business]:
        return list(self.db.scalars(select(Business).where(Business.owner_id == owner_id)))

    def get_owner_business(self, *, business_id: uuid.UUID, owner_id: uuid.UUID) -> Business | None:
        return self.db.scalar(
            select(Business).where(Business.id == business_id, Business.owner_id == owner_id)
        )

    def update_business(self, *, business: Business, values: dict) -> Business:
        for key, value in values.items():
            setattr(business, key, value)
        self.db.flush()
        return business

    def add_staff_member(self, staff_member: StaffMember) -> StaffMember:
        self.db.add(staff_member)
        self.db.flush()
        self.db.refresh(staff_member, attribute_names=["user"])
        return staff_member

    def add_staff_invitation(self, invitation: StaffInvitation) -> StaffInvitation:
        self.db.add(invitation)
        self.db.flush()
        self.db.refresh(invitation, attribute_names=["business"])
        return invitation

    def get_staff_invitation_by_token_hash(
        self, *, token_hash: str
    ) -> StaffInvitation | None:
        return self.db.scalar(
            select(StaffInvitation)
            .where(StaffInvitation.token_hash == token_hash)
            .options(selectinload(StaffInvitation.business))
        )

    def get_pending_staff_invitation(
        self, *, business_id: uuid.UUID, invited_email: str
    ) -> StaffInvitation | None:
        return self.db.scalar(
            select(StaffInvitation).where(
                StaffInvitation.business_id == business_id,
                StaffInvitation.invited_email == invited_email.lower(),
                StaffInvitation.status == StaffInvitationStatus.PENDING,
            )
        )

    def get_staff_member_by_business_email(
        self, *, business_id: uuid.UUID, email: str
    ) -> StaffMember | None:
        return self.db.scalar(
            select(StaffMember)
            .join(StaffMember.user)
            .where(StaffMember.business_id == business_id, User.email == email.lower())
            .options(selectinload(StaffMember.user))
        )

    def get_owner_staff_member(
        self, *, staff_member_id: uuid.UUID, owner_id: uuid.UUID
    ) -> StaffMember | None:
        return self.db.scalar(
            select(StaffMember)
            .join(StaffMember.business)
            .where(StaffMember.id == staff_member_id, Business.owner_id == owner_id)
            .options(selectinload(StaffMember.user))
        )

    def set_staff_member_active(self, *, staff_member: StaffMember, is_active: bool) -> StaffMember:
        staff_member.is_active = is_active
        self.db.flush()
        self.db.refresh(staff_member, attribute_names=["user"])
        return staff_member

    def list_staff_members(self, owner_id: uuid.UUID) -> list[StaffMember]:
        return list(
            self.db.scalars(
                select(StaffMember)
                .join(StaffMember.business)
                .where(Business.owner_id == owner_id)
                .options(selectinload(StaffMember.user))
            )
        )

    def list_staff_invitations(self, owner_id: uuid.UUID) -> list[StaffInvitation]:
        return list(
            self.db.scalars(
                select(StaffInvitation)
                .join(StaffInvitation.business)
                .where(
                    Business.owner_id == owner_id,
                    StaffInvitation.status == StaffInvitationStatus.PENDING,
                )
                .options(selectinload(StaffInvitation.business))
            )
        )

    def list_active_staff_memberships(self, user_id: uuid.UUID) -> list[StaffMember]:
        return list(
            self.db.scalars(
                select(StaffMember)
                .where(StaffMember.user_id == user_id, StaffMember.is_active.is_(True))
                .options(selectinload(StaffMember.business))
            )
        )
