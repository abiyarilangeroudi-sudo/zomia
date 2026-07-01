import hashlib
import hmac
import re
import secrets
import uuid
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.email import EmailSender
from app.core.security import create_access_token, hash_password, verify_password
from app.modules.identity.models import (
    Business,
    EmailVerificationOtp,
    RefreshToken,
    StaffInvitation,
    StaffInvitationStatus,
    StaffMember,
    User,
    UserRole,
)
from app.modules.identity.repository import IdentityRepository
from app.modules.identity.schemas import (
    BusinessCreate,
    BusinessUpdate,
    CustomerProfileUpdate,
    OwnerRegister,
    StaffContextBusinessRead,
    StaffContextRead,
    StaffCreate,
    StaffInvitationAccept,
    StaffInvitationPreviewRead,
    StaffInviteCreate,
    StaffProfileUpdate,
    OwnerStaffRead,
    UserCreate,
    UserRead,
)

CUSTOMER_REGISTRATION_PURPOSE = "customer_registration"
OWNER_REGISTRATION_PURPOSE = "owner_registration"
PASSWORD_RESET_PURPOSE = "password_reset"
PASSWORD_RESET_VERIFIED_PURPOSE = "password_reset_verified"
EMAIL_CHANGE_PURPOSE = "email_change"


class IdentityService:
    def __init__(
        self,
        repository: IdentityRepository,
        settings: Settings,
        email_sender: EmailSender,
    ) -> None:
        self.repository = repository
        self.settings = settings
        self.email_sender = email_sender

    def register_customer(self, payload: UserCreate) -> User:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Use email verification registration flow",
        )

    def register_owner(self, payload: OwnerRegister) -> tuple[User, Business]:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Use email verification registration flow",
        )

    def start_customer_registration(self, payload: UserCreate) -> EmailVerificationOtp:
        return self._start_pending_registration(
            email=payload.email,
            purpose=CUSTOMER_REGISTRATION_PURPOSE,
            payload=payload.model_dump(mode="json"),
        )

    def verify_customer_registration(self, *, email: str, code: str) -> tuple[str, str]:
        otp = self._consume_registration_otp(
            email=email,
            code=code,
            purpose=CUSTOMER_REGISTRATION_PURPOSE,
        )
        user_payload = UserCreate.model_validate(otp.payload_json)
        user = self._create_user(
            user_payload,
            UserRole.CUSTOMER,
            email_verified_at=datetime.now(UTC),
        )
        return self._issue_token_pair(user)

    def start_owner_registration(self, payload: OwnerRegister) -> EmailVerificationOtp:
        return self._start_pending_registration(
            email=payload.email,
            purpose=OWNER_REGISTRATION_PURPOSE,
            payload=payload.model_dump(mode="json"),
        )

    def verify_owner_registration(self, *, email: str, code: str) -> tuple[str, str]:
        otp = self._consume_registration_otp(
            email=email,
            code=code,
            purpose=OWNER_REGISTRATION_PURPOSE,
        )
        payload = OwnerRegister.model_validate(otp.payload_json)
        owner = self._create_user(
            payload,
            UserRole.OWNER,
            email_verified_at=datetime.now(UTC),
        )
        business = self._build_business(
            owner_id=owner.id,
            payload=BusinessCreate(
                name=payload.business_name,
                category=payload.business_category,
                public_phone=payload.public_phone,
            ),
        )
        self.repository.add_business(business)
        return self._issue_token_pair(owner)

    def create_business(self, owner: User, payload: BusinessCreate) -> Business:
        self._require_role(owner, UserRole.OWNER)
        return self.repository.add_business(
            self._build_business(owner_id=owner.id, payload=payload)
        )

    def update_business(
        self, owner: User, business_id: uuid.UUID, payload: BusinessUpdate
    ) -> Business:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        values = payload.model_dump(exclude_unset=True)
        if "country_code" in values and values["country_code"] is not None:
            values["country_code"] = values["country_code"].upper()
        return self.repository.update_business(business=business, values=values)

    def create_staff(self, owner: User, payload: StaffCreate) -> StaffMember:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Use staff invitation flow",
        )

    def invite_staff(self, owner: User, payload: StaffInviteCreate) -> StaffInvitation:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=payload.business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        normalized_email = str(payload.email).lower()
        if (
            self.repository.get_staff_member_by_business_email(
                business_id=business.id, email=normalized_email
            )
            is not None
        ):
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Staff already exists")
        if (
            self.repository.get_pending_staff_invitation(
                business_id=business.id, invited_email=normalized_email
            )
            is not None
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Staff invitation already pending",
            )

        raw_token = secrets.token_urlsafe(32)
        invitation = self.repository.add_staff_invitation(
            StaffInvitation(
                business_id=business.id,
                invited_email=normalized_email,
                invited_by_owner_id=owner.id,
                token_hash=self._hash_invitation_token(raw_token),
                expires_at=datetime.now(UTC)
                + timedelta(hours=self.settings.staff_invitation_expires_hours),
            )
        )
        invite_url = (
            f"{self.settings.frontend_base_url.rstrip('/')}"
            f"/#/accept-staff-invitation?token={raw_token}"
        )
        self.email_sender.send_email(
            to_email=normalized_email,
            subject="Zomia Staff Invitation",
            body=(
                "Zomia Staff Invitation\n\n"
                "Hello,\n\n"
                f"You have been invited to join {business.name} as Staff on Zomia.\n\n"
                "Open this secure invitation link to accept the invitation and set your password:\n\n"
                f"{invite_url}\n\n"
                "This invitation link is single-use and will expire soon.\n\n"
                "If you did not expect this invitation, please ignore this email.\n\n"
                "Best regards,\n"
                "The Zomia Team\n\n"
                "© 2026 Zomia. All rights reserved."
            ),
        )
        return invitation

    def preview_staff_invitation(self, *, token: str) -> StaffInvitationPreviewRead:
        invitation = self._get_valid_pending_staff_invitation(token=token)
        return StaffInvitationPreviewRead(
            email=invitation.invited_email,
            business_name=invitation.business.name,
            status=invitation.status,
            expires_at=invitation.expires_at,
        )

    def accept_staff_invitation(self, payload: StaffInvitationAccept) -> None:
        invitation = self._get_valid_pending_staff_invitation(token=payload.token)
        if self.repository.get_user_by_email(invitation.invited_email) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        now = datetime.now(UTC)
        staff_user = self.repository.add_user(
            User(
                email=invitation.invited_email,
                phone=None,
                password_hash=hash_password(payload.password),
                full_name=invitation.invited_email.split("@")[0],
                role=UserRole.STAFF,
                email_verified_at=now,
            )
        )
        self.repository.add_staff_member(
            StaffMember(business_id=invitation.business_id, user_id=staff_user.id)
        )
        invitation.status = StaffInvitationStatus.ACCEPTED
        invitation.accepted_at = now

    def list_owner_staff(self, owner: User) -> list[OwnerStaffRead]:
        self._require_role(owner, UserRole.OWNER)
        accepted = [
            OwnerStaffRead(
                id=staff_member.id,
                business_id=staff_member.business_id,
                user_id=staff_member.user_id,
                staff_member_id=staff_member.id,
                invitation_id=None,
                email=staff_member.user.email,
                full_name=staff_member.user.full_name,
                status="active" if staff_member.is_active else "inactive",
                is_active=staff_member.is_active,
                created_at=staff_member.created_at,
            )
            for staff_member in self.repository.list_staff_members(owner.id)
        ]
        pending = [
            OwnerStaffRead(
                id=invitation.id,
                business_id=invitation.business_id,
                user_id=None,
                staff_member_id=None,
                invitation_id=invitation.id,
                email=invitation.invited_email,
                full_name=None,
                status="pending",
                is_active=False,
                created_at=invitation.created_at,
            )
            for invitation in self.repository.list_staff_invitations(owner.id)
            if self._as_utc(invitation.expires_at) > datetime.now(UTC)
        ]
        return sorted(accepted + pending, key=lambda item: item.created_at, reverse=True)

    def set_staff_active(
        self, owner: User, staff_member_id: uuid.UUID, *, is_active: bool
    ) -> StaffMember:
        self._require_role(owner, UserRole.OWNER)
        staff_member = self.repository.get_owner_staff_member(
            staff_member_id=staff_member_id, owner_id=owner.id
        )
        if staff_member is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Staff member not found"
            )
        return self.repository.set_staff_member_active(
            staff_member=staff_member, is_active=is_active
        )

    def get_staff_context(self, staff: User) -> StaffContextRead:
        self._require_role(staff, UserRole.STAFF)
        memberships = self.repository.list_active_staff_memberships(staff.id)
        return StaffContextRead(
            staff=UserRead.model_validate(staff),
            businesses=[
                StaffContextBusinessRead(
                    id=membership.business.id,
                    name=membership.business.name,
                    slug=membership.business.slug,
                    status=membership.business.status,
                    timezone=membership.business.timezone,
                    currency_code=membership.business.currency_code,
                    staff_membership_id=membership.id,
                )
                for membership in memberships
            ],
        )

    def update_customer_profile(self, customer: User, payload: CustomerProfileUpdate) -> User:
        self._require_role(customer, UserRole.CUSTOMER)
        return self.repository.update_user_full_name(user=customer, full_name=payload.full_name)

    def update_staff_profile(self, staff: User, payload: StaffProfileUpdate) -> User:
        self._require_role(staff, UserRole.STAFF)
        return self.repository.update_user_full_name(user=staff, full_name=payload.full_name)

    def authenticate(self, *, email: str, password: str) -> tuple[str, str]:
        user = self.repository.get_user_by_email(email)
        if user is None or not user.is_active or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        if user.email_verified_at is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Email is not verified",
            )
        return self._issue_token_pair(user)

    def start_password_recovery(self, *, email: str) -> None:
        normalized_email = email.lower()
        user = self.repository.get_user_by_email(normalized_email)
        if user is None or not user.is_active or user.email_verified_at is None:
            return
        code = self._generate_otp_code()
        self.repository.add_email_verification_otp(
            EmailVerificationOtp(
                email=normalized_email,
                purpose=PASSWORD_RESET_PURPOSE,
                code_hash=self._hash_otp_code(code),
                payload_json={"user_id": str(user.id)},
                expires_at=datetime.now(UTC) + timedelta(minutes=self.settings.otp_expires_minutes),
            )
        )
        self.email_sender.send_email(
            to_email=normalized_email,
            subject="Password Reset",
            body=(
                "Password Reset\n\n"
                "Hello,\n\n"
                "We received a request to reset your Zomia password. "
                "Please use the following verification code:\n\n"
                f"{code}\n"
                "This code will expire in 10 minutes.\n\n"
                "If you didn't request this code, please ignore this email.\n\n"
                "Best regards,\n"
                "The Zomia Team\n\n"
                "© 2026 Zomia. All rights reserved."
            ),
        )

    def verify_password_recovery(self, *, email: str, code: str) -> str:
        otp = self._consume_otp(
            email=email,
            code=code,
            purpose=PASSWORD_RESET_PURPOSE,
        )
        user_id = otp.payload_json.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
        user = self.repository.get_user_by_id(uuid.UUID(user_id))
        if user is None or not user.is_active:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
        raw_reset_token = secrets.token_urlsafe(32)
        self.repository.add_email_verification_otp(
            EmailVerificationOtp(
                email=email.lower(),
                purpose=PASSWORD_RESET_VERIFIED_PURPOSE,
                code_hash=self._hash_reset_token(raw_reset_token),
                payload_json={"user_id": str(user.id)},
                expires_at=datetime.now(UTC) + timedelta(minutes=self.settings.otp_expires_minutes),
            )
        )
        return raw_reset_token

    def complete_password_recovery(self, *, reset_token: str, new_password: str) -> None:
        reset_otp = self.repository.get_email_verification_otp_by_hash(
            code_hash=self._hash_reset_token(reset_token),
            purpose=PASSWORD_RESET_VERIFIED_PURPOSE,
        )
        if reset_otp is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
        now = datetime.now(UTC)
        if self._as_utc(reset_otp.expires_at) <= now:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Reset token expired"
            )
        user_id = reset_otp.payload_json.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
        user = self.repository.get_user_by_id(uuid.UUID(user_id))
        if user is None or not user.is_active:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
        self.repository.update_user_password_hash(
            user=user,
            password_hash=hash_password(new_password),
        )
        self.repository.increment_user_session_version(user=user)
        self.repository.revoke_user_refresh_tokens(user_id=user.id, revoked_at=now)
        reset_otp.consumed_at = now

    def change_password(self, *, user: User, current_password: str, new_password: str) -> None:
        if not user.is_active or not verify_password(current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Incorrect current password",
            )
        now = datetime.now(UTC)
        self.repository.update_user_password_hash(
            user=user,
            password_hash=hash_password(new_password),
        )
        self.repository.increment_user_session_version(user=user)
        self.repository.revoke_user_refresh_tokens(user_id=user.id, revoked_at=now)

    def start_email_change(self, *, user: User, new_email: str, current_password: str) -> None:
        self._require_account_settings_role(user)
        normalized_email = new_email.lower()
        if not user.is_active or not verify_password(current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Incorrect current password",
            )
        if normalized_email == user.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Email is unchanged"
            )
        if self.repository.get_user_by_email(normalized_email) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        self._ensure_email_change_not_reserved(new_email=normalized_email, user_id=user.id)
        code = self._generate_otp_code()
        self.repository.add_email_verification_otp(
            EmailVerificationOtp(
                email=normalized_email,
                purpose=EMAIL_CHANGE_PURPOSE,
                code_hash=self._hash_otp_code(code),
                payload_json={"user_id": str(user.id), "new_email": normalized_email},
                expires_at=datetime.now(UTC) + timedelta(minutes=self.settings.otp_expires_minutes),
            )
        )
        self.email_sender.send_email(
            to_email=normalized_email,
            subject="Email Change Verification",
            body=(
                "Email Change Verification\n\n"
                "Hello,\n\n"
                "Please use the following verification code to confirm your new Zomia email:\n\n"
                f"{code}\n"
                "This code will expire in 10 minutes.\n\n"
                "If you didn't request this change, please ignore this email.\n\n"
                "Best regards,\n"
                "The Zomia Team\n\n"
                "© 2026 Zomia. All rights reserved."
            ),
        )

    def verify_email_change(self, *, user: User, new_email: str, code: str) -> User:
        self._require_account_settings_role(user)
        normalized_email = new_email.lower()
        otp = self._consume_otp(
            email=normalized_email,
            code=code,
            purpose=EMAIL_CHANGE_PURPOSE,
        )
        if otp.payload_json.get("user_id") != str(user.id):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")
        if otp.payload_json.get("new_email") != normalized_email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")
        if self.repository.get_user_by_email(normalized_email) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        return self.repository.update_user_email(
            user=user,
            email=normalized_email,
            email_verified_at=datetime.now(UTC),
        )

    def remove_customer_account(self, *, user: User, current_password: str) -> None:
        self._require_role(user, UserRole.CUSTOMER)
        if not user.is_active or not verify_password(current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Incorrect current password",
            )
        now = datetime.now(UTC)
        self.repository.anonymize_customer_account(
            user=user,
            email=f"deleted+{user.id}@deleted.zomia.local",
            full_name="Deleted customer",
            password_hash=hash_password(secrets.token_urlsafe(32)),
        )
        self.repository.increment_user_session_version(user=user)
        self.repository.revoke_user_refresh_tokens(user_id=user.id, revoked_at=now)
        self.repository.revoke_customer_qr_tokens(customer_id=user.id, revoked_at=now)

    def refresh_session(self, raw_refresh_token: str) -> tuple[str, str]:
        now = datetime.now(UTC)
        refresh_token = self.repository.get_refresh_token_by_hash(
            self._hash_refresh_token(raw_refresh_token)
        )
        if (
            refresh_token is None
            or refresh_token.revoked_at is not None
            or self._as_utc(refresh_token.expires_at) <= now
            or not refresh_token.user.is_active
        ):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

        self.repository.revoke_refresh_token(refresh_token=refresh_token, revoked_at=now)
        return self._issue_token_pair(refresh_token.user)

    def logout(self, raw_refresh_token: str) -> None:
        refresh_token = self.repository.get_refresh_token_by_hash(
            self._hash_refresh_token(raw_refresh_token)
        )
        if refresh_token is not None and refresh_token.revoked_at is None:
            self.repository.revoke_refresh_token(
                refresh_token=refresh_token, revoked_at=datetime.now(UTC)
            )

    def _issue_token_pair(self, user: User) -> tuple[str, str]:
        access_token = create_access_token(
            subject=str(user.id),
            role=user.role.value,
            session_version=user.session_version,
            secret_key=self.settings.jwt_secret_key,
            issuer=self.settings.jwt_issuer,
            expires_delta=timedelta(minutes=self.settings.access_token_minutes),
        )
        raw_refresh_token = secrets.token_urlsafe(32)
        self.repository.add_refresh_token(
            RefreshToken(
                user_id=user.id,
                token_hash=self._hash_refresh_token(raw_refresh_token),
                expires_at=datetime.now(UTC) + timedelta(days=self.settings.refresh_token_days),
            )
        )
        return access_token, raw_refresh_token

    @staticmethod
    def _hash_refresh_token(raw_refresh_token: str) -> str:
        return hashlib.sha256(raw_refresh_token.encode("utf-8")).hexdigest()

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    def _start_pending_registration(
        self, *, email: str, purpose: str, payload: dict
    ) -> EmailVerificationOtp:
        normalized_email = email.lower()
        if self.repository.get_user_by_email(normalized_email) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        code = self._generate_otp_code()
        otp = self.repository.add_email_verification_otp(
            EmailVerificationOtp(
                email=normalized_email,
                purpose=purpose,
                code_hash=self._hash_otp_code(code),
                payload_json=payload,
                expires_at=datetime.now(UTC) + timedelta(minutes=self.settings.otp_expires_minutes),
            )
        )
        self.email_sender.send_email(
            to_email=normalized_email,
            subject="Email Verification",
            body=(
                "Email Verification\n\n"
                "Hello,\n\n"
                "Thank you for registering with Zomia! To complete your registration, "
                "please use the following verification code:\n\n"
                f"{code}\n"
                "This code will expire in 10 minutes.\n\n"
                "If you didn't request this code, please ignore this email.\n\n"
                "Best regards,\n"
                "The Zomia Team\n\n"
                "© 2026 Zomia. All rights reserved."
            ),
        )
        return otp

    def _consume_registration_otp(
        self, *, email: str, code: str, purpose: str
    ) -> EmailVerificationOtp:
        otp = self._consume_otp(email=email, code=code, purpose=purpose)
        if self.repository.get_user_by_email(email) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        return otp

    def _consume_otp(self, *, email: str, code: str, purpose: str) -> EmailVerificationOtp:
        otp = self.repository.get_latest_email_verification_otp(
            email=email.lower(),
            purpose=purpose,
        )
        now = datetime.now(UTC)
        if otp is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="OTP not found")
        if self._as_utc(otp.expires_at) <= now:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP expired")
        if otp.attempt_count >= 5:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Too many OTP attempts",
            )
        otp.attempt_count += 1
        if not hmac.compare_digest(otp.code_hash, self._hash_otp_code(code)):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")
        otp.consumed_at = now
        return otp

    def _ensure_email_change_not_reserved(self, *, new_email: str, user_id: uuid.UUID) -> None:
        active_otps = self.repository.list_active_email_verification_otps(
            purpose=EMAIL_CHANGE_PURPOSE,
            now=datetime.now(UTC),
        )
        for otp in active_otps:
            if otp.payload_json.get("new_email") != new_email:
                continue
            if otp.payload_json.get("user_id") == str(user_id):
                continue
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email change already pending",
            )

    def _generate_otp_code(self) -> str:
        if self.settings.otp_test_code is not None:
            return self.settings.otp_test_code
        return str(secrets.randbelow(900000) + 100000)

    def _hash_otp_code(self, code: str) -> str:
        return hmac.new(
            self.settings.jwt_secret_key.encode("utf-8"),
            code.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

    def _hash_reset_token(self, reset_token: str) -> str:
        return hmac.new(
            self.settings.jwt_secret_key.encode("utf-8"),
            reset_token.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

    def _hash_invitation_token(self, invitation_token: str) -> str:
        return hmac.new(
            self.settings.jwt_secret_key.encode("utf-8"),
            invitation_token.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

    def _get_valid_pending_staff_invitation(self, *, token: str) -> StaffInvitation:
        invitation = self.repository.get_staff_invitation_by_token_hash(
            token_hash=self._hash_invitation_token(token)
        )
        if invitation is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid invitation")
        now = datetime.now(UTC)
        if invitation.status != StaffInvitationStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invitation used")
        if self._as_utc(invitation.expires_at) <= now:
            invitation.status = StaffInvitationStatus.EXPIRED
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Invitation expired"
            )
        return invitation

    def _create_user(
        self,
        payload: UserCreate,
        role: UserRole,
        *,
        email_verified_at: datetime | None = None,
    ) -> User:
        if self.repository.get_user_by_email(payload.email) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        return self.repository.add_user(
            User(
                email=payload.email.lower(),
                phone=payload.phone,
                password_hash=hash_password(payload.password),
                full_name=payload.full_name,
                role=role,
                email_verified_at=email_verified_at,
            )
        )

    def _build_business(self, *, owner_id, payload: BusinessCreate) -> Business:
        slug = self._make_slug(payload.name)
        if self.repository.get_business_by_slug(slug) is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail="Business slug already exists"
            )
        return Business(
            owner_id=owner_id,
            name=payload.name,
            legal_name=payload.legal_name,
            slug=slug,
            category=payload.category,
            public_email=str(payload.public_email) if payload.public_email else None,
            public_phone=payload.public_phone,
            website_url=payload.website_url,
            address_line1=payload.address_line1,
            address_line2=payload.address_line2,
            city=payload.city,
            region=payload.region,
            postal_code=payload.postal_code,
            country_code=payload.country_code.upper(),
            timezone=payload.timezone,
            currency_code=payload.currency_code.upper(),
        )

    @staticmethod
    def _make_slug(name: str) -> str:
        slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        return slug or "business"

    @staticmethod
    def _require_role(user: User, role: UserRole) -> None:
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")

    @staticmethod
    def _require_account_settings_role(user: User) -> None:
        if user.role not in {UserRole.CUSTOMER, UserRole.OWNER}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
