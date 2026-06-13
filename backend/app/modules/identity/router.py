from fastapi import APIRouter, Depends, status
import uuid
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.modules.identity.dependencies import (
    get_current_user,
    get_identity_repository,
    get_identity_service,
)
from app.modules.identity.models import User, UserRole
from app.modules.identity.repository import IdentityRepository
from app.modules.identity.schemas import (
    BusinessCreate,
    BusinessRead,
    LoginRequest,
    OwnerRegister,
    StaffContextRead,
    StaffCreate,
    StaffRead,
    StaffUpdate,
    TokenResponse,
    UserCreate,
    UserRead,
)
from app.modules.identity.service import IdentityService

router = APIRouter(tags=["identity"])


@router.post("/auth/register/customer", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register_customer(
    payload: UserCreate,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> User:
    user = service.register_customer(payload)
    db.commit()
    db.refresh(user)
    return user


@router.post("/auth/register/owner", response_model=BusinessRead, status_code=status.HTTP_201_CREATED)
def register_owner(
    payload: OwnerRegister,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> BusinessRead:
    _, business = service.register_owner(payload)
    db.commit()
    db.refresh(business)
    return business


@router.post("/auth/login", response_model=TokenResponse)
def login(payload: LoginRequest, service: IdentityService = Depends(get_identity_service)) -> TokenResponse:
    return TokenResponse(access_token=service.authenticate(email=payload.email, password=payload.password))


@router.get("/auth/me", response_model=UserRead)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.get("/staff/me/context", response_model=StaffContextRead)
def staff_context(
    current_user: User = Depends(get_current_user),
    service: IdentityService = Depends(get_identity_service),
) -> StaffContextRead:
    return service.get_staff_context(current_user)


@router.post("/owner/businesses", response_model=BusinessRead, status_code=status.HTTP_201_CREATED)
def create_business(
    payload: BusinessCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
):
    business = service.create_business(current_user, payload)
    db.commit()
    db.refresh(business)
    return business


@router.get("/owner/businesses", response_model=list[BusinessRead])
def list_businesses(
    current_user: User = Depends(get_current_user),
    repository: IdentityRepository = Depends(get_identity_repository),
) -> list:
    IdentityService._require_role(current_user, UserRole.OWNER)
    return repository.list_owner_businesses(current_user.id)


@router.post("/owner/staff", response_model=StaffRead, status_code=status.HTTP_201_CREATED)
def create_staff(
    payload: StaffCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
):
    staff_member = service.create_staff(current_user, payload)
    db.commit()
    return staff_member


@router.patch("/owner/staff/{staff_member_id}", response_model=StaffRead)
def update_staff(
    staff_member_id: uuid.UUID,
    payload: StaffUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
):
    staff_member = service.set_staff_active(
        current_user, staff_member_id, is_active=payload.is_active
    )
    db.commit()
    return staff_member


@router.get("/owner/staff", response_model=list[StaffRead])
def list_staff(
    current_user: User = Depends(get_current_user),
    repository: IdentityRepository = Depends(get_identity_repository),
) -> list:
    IdentityService._require_role(current_user, UserRole.OWNER)
    return repository.list_staff_members(current_user.id)
