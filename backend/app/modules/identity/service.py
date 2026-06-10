import re
from datetime import timedelta

from fastapi import HTTPException, status

from app.core.config import Settings
from app.core.security import create_access_token, hash_password, verify_password
from app.modules.identity.models import Business, StaffMember, User, UserRole
from app.modules.identity.repository import IdentityRepository
from app.modules.identity.schemas import (
    BusinessCreate,
    OwnerRegister,
    StaffContextBusinessRead,
    StaffContextRead,
    StaffCreate,
    UserCreate,
    UserRead,
)


class IdentityService:
    def __init__(self, repository: IdentityRepository, settings: Settings) -> None:
        self.repository = repository
        self.settings = settings

    def register_customer(self, payload: UserCreate) -> User:
        return self._create_user(payload, UserRole.CUSTOMER)

    def register_owner(self, payload: OwnerRegister) -> tuple[User, Business]:
        owner = self._create_user(payload, UserRole.OWNER)
        business = self._build_business(
            owner_id=owner.id,
            payload=BusinessCreate(
                name=payload.business_name,
                category=payload.business_category,
                public_phone=payload.public_phone,
            ),
        )
        self.repository.add_business(business)
        return owner, business

    def create_business(self, owner: User, payload: BusinessCreate) -> Business:
        self._require_role(owner, UserRole.OWNER)
        return self.repository.add_business(self._build_business(owner_id=owner.id, payload=payload))

    def create_staff(self, owner: User, payload: StaffCreate) -> StaffMember:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=payload.business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

        staff_user = self._create_user(payload, UserRole.STAFF)
        return self.repository.add_staff_member(
            StaffMember(business_id=business.id, user_id=staff_user.id)
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

    def authenticate(self, *, email: str, password: str) -> str:
        user = self.repository.get_user_by_email(email)
        if user is None or not user.is_active or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return create_access_token(
            subject=str(user.id),
            role=user.role.value,
            secret_key=self.settings.jwt_secret_key,
            issuer=self.settings.jwt_issuer,
            expires_delta=timedelta(minutes=self.settings.access_token_minutes),
        )

    def _create_user(self, payload: UserCreate, role: UserRole) -> User:
        if self.repository.get_user_by_email(payload.email) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
        return self.repository.add_user(
            User(
                email=payload.email.lower(),
                phone=payload.phone,
                password_hash=hash_password(payload.password),
                full_name=payload.full_name,
                role=role,
            )
        )

    def _build_business(self, *, owner_id, payload: BusinessCreate) -> Business:
        slug = self._make_slug(payload.name)
        if self.repository.get_business_by_slug(slug) is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Business slug already exists")
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
