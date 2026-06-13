import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.modules.identity.models import Business, StaffMember, User


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

    def add_staff_member(self, staff_member: StaffMember) -> StaffMember:
        self.db.add(staff_member)
        self.db.flush()
        self.db.refresh(staff_member, attribute_names=["user"])
        return staff_member

    def get_owner_staff_member(
        self, *, staff_member_id: uuid.UUID, owner_id: uuid.UUID
    ) -> StaffMember | None:
        return self.db.scalar(
            select(StaffMember)
            .join(StaffMember.business)
            .where(StaffMember.id == staff_member_id, Business.owner_id == owner_id)
            .options(selectinload(StaffMember.user))
        )

    def set_staff_member_active(
        self, *, staff_member: StaffMember, is_active: bool
    ) -> StaffMember:
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

    def list_active_staff_memberships(self, user_id: uuid.UUID) -> list[StaffMember]:
        return list(
            self.db.scalars(
                select(StaffMember)
                .where(StaffMember.user_id == user_id, StaffMember.is_active.is_(True))
                .options(selectinload(StaffMember.business))
            )
        )
