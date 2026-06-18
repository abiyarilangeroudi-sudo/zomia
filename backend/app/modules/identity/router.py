from fastapi import APIRouter, Depends, Response, status
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
    AccountRemove,
    CustomerProfileUpdate,
    EmailChangeStart,
    EmailChangeVerify,
    EmailVerificationConfirm,
    LoginRequest,
    OwnerRegister,
    PasswordRecoveryComplete,
    PasswordRecoveryStart,
    PasswordRecoveryVerify,
    PasswordRecoveryVerifyRead,
    PasswordChange,
    PendingRegistrationRead,
    RefreshTokenRequest,
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


@router.post("/auth/register/customer", status_code=status.HTTP_410_GONE)
def register_customer_disabled(
    payload: UserCreate,
    service: IdentityService = Depends(get_identity_service),
) -> None:
    service.register_customer(payload)


@router.post(
    "/auth/register/customer/start",
    response_model=PendingRegistrationRead,
    status_code=status.HTTP_202_ACCEPTED,
)
def start_customer_registration(
    payload: UserCreate,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> PendingRegistrationRead:
    otp = service.start_customer_registration(payload)
    db.commit()
    return PendingRegistrationRead(email=otp.email, expires_at=otp.expires_at)


@router.post("/auth/register/customer/verify", response_model=TokenResponse)
def verify_customer_registration(
    payload: EmailVerificationConfirm,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> TokenResponse:
    access_token, refresh_token = service.verify_customer_registration(
        email=str(payload.email), code=payload.code
    )
    db.commit()
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/auth/register/owner", status_code=status.HTTP_410_GONE)
def register_owner_disabled(
    payload: OwnerRegister,
    service: IdentityService = Depends(get_identity_service),
) -> None:
    service.register_owner(payload)


@router.post(
    "/auth/register/owner/start",
    response_model=PendingRegistrationRead,
    status_code=status.HTTP_202_ACCEPTED,
)
def start_owner_registration(
    payload: OwnerRegister,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> PendingRegistrationRead:
    otp = service.start_owner_registration(payload)
    db.commit()
    return PendingRegistrationRead(email=otp.email, expires_at=otp.expires_at)


@router.post("/auth/register/owner/verify", response_model=TokenResponse)
def verify_owner_registration(
    payload: EmailVerificationConfirm,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> TokenResponse:
    access_token, refresh_token = service.verify_owner_registration(
        email=str(payload.email), code=payload.code
    )
    db.commit()
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/auth/login", response_model=TokenResponse)
def login(
    payload: LoginRequest,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> TokenResponse:
    access_token, refresh_token = service.authenticate(
        email=payload.email, password=payload.password
    )
    db.commit()
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/auth/password-recovery/start", status_code=status.HTTP_202_ACCEPTED)
def start_password_recovery(
    payload: PasswordRecoveryStart,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> Response:
    service.start_password_recovery(email=str(payload.email))
    db.commit()
    return Response(status_code=status.HTTP_202_ACCEPTED)


@router.post("/auth/password-recovery/verify", response_model=PasswordRecoveryVerifyRead)
def verify_password_recovery(
    payload: PasswordRecoveryVerify,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> PasswordRecoveryVerifyRead:
    reset_token = service.verify_password_recovery(
        email=str(payload.email),
        code=payload.code,
    )
    db.commit()
    return PasswordRecoveryVerifyRead(reset_token=reset_token)


@router.post("/auth/password-recovery/complete", status_code=status.HTTP_204_NO_CONTENT)
def complete_password_recovery(
    payload: PasswordRecoveryComplete,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> Response:
    service.complete_password_recovery(
        reset_token=payload.reset_token,
        new_password=payload.new_password,
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/auth/change-password", status_code=status.HTTP_204_NO_CONTENT)
def change_password(
    payload: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> Response:
    service.change_password(
        user=current_user,
        current_password=payload.current_password,
        new_password=payload.new_password,
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/auth/change-email/start", status_code=status.HTTP_202_ACCEPTED)
def start_email_change(
    payload: EmailChangeStart,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> Response:
    service.start_email_change(
        user=current_user,
        new_email=str(payload.new_email),
        current_password=payload.current_password,
    )
    db.commit()
    return Response(status_code=status.HTTP_202_ACCEPTED)


@router.post("/auth/change-email/verify", response_model=UserRead)
def verify_email_change(
    payload: EmailChangeVerify,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> User:
    user = service.verify_email_change(
        user=current_user,
        new_email=str(payload.new_email),
        code=payload.code,
    )
    db.commit()
    db.refresh(user)
    return user


@router.post("/auth/remove-account", status_code=status.HTTP_204_NO_CONTENT)
def remove_account(
    payload: AccountRemove,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> Response:
    service.remove_customer_account(
        user=current_user,
        current_password=payload.current_password,
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/auth/refresh", response_model=TokenResponse)
def refresh_session(
    payload: RefreshTokenRequest,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> TokenResponse:
    access_token, refresh_token = service.refresh_session(payload.refresh_token)
    db.commit()
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    payload: RefreshTokenRequest,
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> Response:
    service.logout(payload.refresh_token)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/auth/me", response_model=UserRead)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.patch("/customers/me/profile", response_model=UserRead)
def update_customer_profile(
    payload: CustomerProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: IdentityService = Depends(get_identity_service),
) -> User:
    user = service.update_customer_profile(current_user, payload)
    db.commit()
    db.refresh(user)
    return user


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
