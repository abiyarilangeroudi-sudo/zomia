import hashlib
from datetime import UTC, datetime, timedelta
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.modules.identity.models import EmailVerificationOtp, RefreshToken, StaffMember, User
from app.modules.identity.repository import IdentityRepository
from app.modules.identity.schemas import UserCreate
from app.modules.identity.service import IdentityService
from app.modules.qr.models import CustomerQrToken, CustomerQrTokenStatus


class FakeEmailSender:
    def __init__(self) -> None:
        self.sent: list[dict[str, str]] = []

    def send_email(self, *, to_email: str, subject: str, body: str) -> None:
        self.sent.append({"to_email": to_email, "subject": subject, "body": body})


def register_customer(
    client: TestClient,
    *,
    email: str,
    password: str = "strong-password",
    full_name: str = "Customer One",
    phone: str | None = None,
) -> dict:
    payload = {"email": email, "password": password, "full_name": full_name}
    if phone is not None:
        payload["phone"] = phone
    start_response = client.post("/api/v1/auth/register/customer/start", json=payload)
    assert start_response.status_code == 202
    verify_response = client.post(
        "/api/v1/auth/register/customer/verify",
        json={"email": email, "code": "123456"},
    )
    assert verify_response.status_code == 200
    token = verify_response.json()["access_token"]
    me_response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_response.status_code == 200
    return me_response.json()


def register_owner(
    client: TestClient,
    *,
    email: str,
    password: str = "strong-password",
    full_name: str = "Owner One",
    business_name: str = "Zomia Cafe",
    business_category: str | None = None,
    public_phone: str | None = None,
) -> dict:
    payload = {
        "email": email,
        "password": password,
        "full_name": full_name,
        "business_name": business_name,
    }
    if business_category is not None:
        payload["business_category"] = business_category
    if public_phone is not None:
        payload["public_phone"] = public_phone
    start_response = client.post("/api/v1/auth/register/owner/start", json=payload)
    assert start_response.status_code == 202
    verify_response = client.post(
        "/api/v1/auth/register/owner/verify",
        json={"email": email, "code": "123456"},
    )
    assert verify_response.status_code == 200
    token = verify_response.json()["access_token"]
    business_response = client.get(
        "/api/v1/owner/businesses",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert business_response.status_code == 200
    return business_response.json()[0]


def test_customer_registration_login_and_me(client: TestClient) -> None:
    customer = register_customer(
        client,
        email="customer@example.com",
        phone="+491111111",
    )
    assert customer["role"] == "customer"
    assert customer["email_verified_at"] is not None

    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "customer@example.com", "password": "strong-password"},
    )
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]
    assert login_response.json()["refresh_token"]

    me_response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "customer@example.com"


def test_email_verification_message_is_branded(db_session: Session) -> None:
    email_sender = FakeEmailSender()
    service = IdentityService(
        IdentityRepository(db_session),
        Settings(
            DATABASE_URL="sqlite+pysqlite:///:memory:",
            JWT_SECRET_KEY="test-secret",
            JWT_ISSUER="zomia-test",
            EMAIL_DELIVERY_MODE="test",
            OTP_TEST_CODE="123456",
        ),
        email_sender,
    )

    service.start_customer_registration(
        UserCreate(
            email="email-body@example.com",
            password="strong-password",
            full_name="Email Body",
        )
    )

    assert email_sender.sent == [
        {
            "to_email": "email-body@example.com",
            "subject": "Email Verification",
            "body": (
                "Email Verification\n\n"
                "Hello,\n\n"
                "Thank you for registering with Zomia! To complete your registration, "
                "please use the following verification code:\n\n"
                "123456\n"
                "This code will expire in 10 minutes.\n\n"
                "If you didn't request this code, please ignore this email.\n\n"
                "Best regards,\n"
                "The Zomia Team\n\n"
                "© 2026 Zomia. All rights reserved."
            ),
        }
    ]


def test_direct_customer_registration_is_disabled(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": "direct-customer@example.com",
            "password": "strong-password",
            "full_name": "Direct Customer",
        },
    )

    assert response.status_code == 410


def test_customer_cannot_login_before_email_verification(client: TestClient) -> None:
    start_response = client.post(
        "/api/v1/auth/register/customer/start",
        json={
            "email": "pending-customer@example.com",
            "password": "strong-password",
            "full_name": "Pending Customer",
        },
    )
    assert start_response.status_code == 202

    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "pending-customer@example.com", "password": "strong-password"},
    )

    assert login_response.status_code == 401


def test_customer_registration_rejects_wrong_otp(client: TestClient) -> None:
    start_response = client.post(
        "/api/v1/auth/register/customer/start",
        json={
            "email": "wrong-otp-customer@example.com",
            "password": "strong-password",
            "full_name": "Wrong OTP Customer",
        },
    )
    assert start_response.status_code == 202

    verify_response = client.post(
        "/api/v1/auth/register/customer/verify",
        json={"email": "wrong-otp-customer@example.com", "code": "000000"},
    )

    assert verify_response.status_code == 400


def test_customer_registration_rejects_expired_otp(client: TestClient, db_session: Session) -> None:
    start_response = client.post(
        "/api/v1/auth/register/customer/start",
        json={
            "email": "expired-otp-customer@example.com",
            "password": "strong-password",
            "full_name": "Expired OTP Customer",
        },
    )
    assert start_response.status_code == 202
    otp = db_session.query(EmailVerificationOtp).one()
    otp.expires_at = datetime.now(UTC) - timedelta(minutes=1)
    db_session.flush()

    verify_response = client.post(
        "/api/v1/auth/register/customer/verify",
        json={"email": "expired-otp-customer@example.com", "code": "123456"},
    )

    assert verify_response.status_code == 400


def test_refresh_token_rotates_and_raw_token_is_not_stored(
    client: TestClient, db_session: Session
) -> None:
    register_customer(client, email="refresh-customer@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "refresh-customer@example.com", "password": "strong-password"},
    )
    old_refresh_token = login_response.json()["refresh_token"]
    stored_token = (
        db_session.query(RefreshToken)
        .filter_by(token_hash=hashlib.sha256(old_refresh_token.encode("utf-8")).hexdigest())
        .one()
    )

    assert stored_token.token_hash != old_refresh_token
    assert stored_token.token_hash == hashlib.sha256(old_refresh_token.encode("utf-8")).hexdigest()

    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh_token},
    )

    assert refresh_response.status_code == 200
    assert refresh_response.json()["access_token"]
    assert refresh_response.json()["refresh_token"] != old_refresh_token
    db_session.refresh(stored_token)
    assert stored_token.revoked_at is not None

    replay_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh_token},
    )
    assert replay_response.status_code == 401


def test_logout_revokes_refresh_token(client: TestClient, db_session: Session) -> None:
    register_customer(client, email="logout-customer@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "logout-customer@example.com", "password": "strong-password"},
    )
    refresh_token = login_response.json()["refresh_token"]
    stored_token = (
        db_session.query(RefreshToken)
        .filter_by(token_hash=hashlib.sha256(refresh_token.encode("utf-8")).hexdigest())
        .one()
    )

    logout_response = client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})

    assert logout_response.status_code == 204
    db_session.refresh(stored_token)
    assert stored_token.revoked_at is not None
    refresh_response = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_response.status_code == 401


def test_password_recovery_start_is_neutral_for_unknown_email(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/password-recovery/start",
        json={"email": "missing@example.com"},
    )

    assert response.status_code == 202


def test_password_recovery_rejects_wrong_otp(client: TestClient) -> None:
    register_customer(client, email="wrong-reset@example.com")
    start_response = client.post(
        "/api/v1/auth/password-recovery/start",
        json={"email": "wrong-reset@example.com"},
    )
    assert start_response.status_code == 202

    verify_response = client.post(
        "/api/v1/auth/password-recovery/verify",
        json={"email": "wrong-reset@example.com", "code": "000000"},
    )

    assert verify_response.status_code == 400


def test_password_recovery_resets_password_and_revokes_refresh_tokens(
    client: TestClient, db_session: Session
) -> None:
    register_customer(client, email="reset-customer@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "reset-customer@example.com", "password": "strong-password"},
    )
    old_refresh_token = login_response.json()["refresh_token"]
    start_response = client.post(
        "/api/v1/auth/password-recovery/start",
        json={"email": "reset-customer@example.com"},
    )
    assert start_response.status_code == 202
    verify_response = client.post(
        "/api/v1/auth/password-recovery/verify",
        json={"email": "reset-customer@example.com", "code": "123456"},
    )
    assert verify_response.status_code == 200
    reset_token = verify_response.json()["reset_token"]

    complete_response = client.post(
        "/api/v1/auth/password-recovery/complete",
        json={"reset_token": reset_token, "new_password": "new-strong-password"},
    )

    assert complete_response.status_code == 204
    old_login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "reset-customer@example.com", "password": "strong-password"},
    )
    assert old_login_response.status_code == 401
    new_login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "reset-customer@example.com", "password": "new-strong-password"},
    )
    assert new_login_response.status_code == 200
    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh_token},
    )
    assert refresh_response.status_code == 401
    revoked_tokens = [
        token for token in db_session.query(RefreshToken).all() if token.revoked_at is not None
    ]
    assert revoked_tokens


def test_change_password_rejects_wrong_current_password(client: TestClient) -> None:
    register_customer(client, email="wrong-change@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "wrong-change@example.com", "password": "strong-password"},
    )
    access_token = login_response.json()["access_token"]

    response = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "current_password": "wrong-password",
            "new_password": "new-strong-password",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Incorrect current password"


def test_change_password_updates_password_and_revokes_refresh_tokens(
    client: TestClient,
) -> None:
    register_customer(client, email="change-customer@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "change-customer@example.com", "password": "strong-password"},
    )
    access_token = login_response.json()["access_token"]
    old_refresh_token = login_response.json()["refresh_token"]

    response = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "current_password": "strong-password",
            "new_password": "new-strong-password",
        },
    )

    assert response.status_code == 204
    old_login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "change-customer@example.com", "password": "strong-password"},
    )
    assert old_login_response.status_code == 401
    new_login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "change-customer@example.com", "password": "new-strong-password"},
    )
    assert new_login_response.status_code == 200
    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh_token},
    )
    assert refresh_response.status_code == 401


def test_change_email_requires_current_password(client: TestClient) -> None:
    register_customer(client, email="email-password@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "email-password@example.com", "password": "strong-password"},
    )
    access_token = login_response.json()["access_token"]

    response = client.post(
        "/api/v1/auth/change-email/start",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "new_email": "email-password-new@example.com",
            "current_password": "wrong-password",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Incorrect current password"


def test_change_email_reserves_pending_email_for_limited_time(client: TestClient) -> None:
    register_customer(client, email="email-owner-a@example.com")
    token_a = client.post(
        "/api/v1/auth/login",
        json={"email": "email-owner-a@example.com", "password": "strong-password"},
    ).json()["access_token"]
    register_customer(client, email="email-owner-b@example.com")
    token_b = client.post(
        "/api/v1/auth/login",
        json={"email": "email-owner-b@example.com", "password": "strong-password"},
    ).json()["access_token"]

    start_response = client.post(
        "/api/v1/auth/change-email/start",
        headers={"Authorization": f"Bearer {token_a}"},
        json={
            "new_email": "reserved-email@example.com",
            "current_password": "strong-password",
        },
    )
    blocked_response = client.post(
        "/api/v1/auth/change-email/start",
        headers={"Authorization": f"Bearer {token_b}"},
        json={
            "new_email": "reserved-email@example.com",
            "current_password": "strong-password",
        },
    )

    assert start_response.status_code == 202
    assert blocked_response.status_code == 409
    assert blocked_response.json()["detail"] == "Email change already pending"


def test_change_email_updates_email_without_revoking_refresh_token(client: TestClient) -> None:
    register_customer(client, email="email-change@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "email-change@example.com", "password": "strong-password"},
    )
    access_token = login_response.json()["access_token"]
    refresh_token = login_response.json()["refresh_token"]

    start_response = client.post(
        "/api/v1/auth/change-email/start",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "new_email": "email-change-new@example.com",
            "current_password": "strong-password",
        },
    )
    verify_response = client.post(
        "/api/v1/auth/change-email/verify",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"new_email": "email-change-new@example.com", "code": "123456"},
    )

    assert start_response.status_code == 202
    assert verify_response.status_code == 200
    assert verify_response.json()["email"] == "email-change-new@example.com"
    old_login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "email-change@example.com", "password": "strong-password"},
    )
    assert old_login_response.status_code == 401
    new_login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "email-change-new@example.com", "password": "strong-password"},
    )
    assert new_login_response.status_code == 200
    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_response.status_code == 200


def test_owner_change_email_updates_email_without_revoking_refresh_token(
    client: TestClient,
) -> None:
    register_owner(client, email="owner-email-change@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "owner-email-change@example.com", "password": "strong-password"},
    )
    access_token = login_response.json()["access_token"]
    refresh_token = login_response.json()["refresh_token"]

    start_response = client.post(
        "/api/v1/auth/change-email/start",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "new_email": "owner-email-change-new@example.com",
            "current_password": "strong-password",
        },
    )
    verify_response = client.post(
        "/api/v1/auth/change-email/verify",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"new_email": "owner-email-change-new@example.com", "code": "123456"},
    )

    assert start_response.status_code == 202
    assert verify_response.status_code == 200
    assert verify_response.json()["email"] == "owner-email-change-new@example.com"
    assert verify_response.json()["role"] == "owner"
    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_response.status_code == 200


def test_remove_account_requires_current_password(client: TestClient) -> None:
    register_customer(client, email="remove-password@example.com")
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "remove-password@example.com", "password": "strong-password"},
    )
    access_token = login_response.json()["access_token"]

    response = client.post(
        "/api/v1/auth/remove-account",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"current_password": "wrong-password"},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Incorrect current password"


def test_remove_account_anonymizes_customer_and_revokes_tokens(
    client: TestClient, db_session: Session
) -> None:
    customer = register_customer(
        client,
        email="remove-customer@example.com",
        phone="+4912345678",
    )
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "remove-customer@example.com", "password": "strong-password"},
    )
    access_token = login_response.json()["access_token"]
    refresh_token = login_response.json()["refresh_token"]
    qr_response = client.post(
        "/api/v1/customers/me/qr-token",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert qr_response.status_code == 200

    response = client.post(
        "/api/v1/auth/remove-account",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"current_password": "strong-password"},
    )

    assert response.status_code == 204
    db_session.expire_all()
    stored_user = db_session.get(User, UUID(customer["id"]))
    assert stored_user is not None
    assert stored_user.is_active is False
    assert stored_user.email == f"deleted+{customer['id']}@deleted.zomia.local"
    assert stored_user.phone is None
    assert stored_user.full_name == "Deleted customer"
    assert stored_user.email_verified_at is None
    active_qr_tokens = [
        token
        for token in db_session.query(CustomerQrToken).all()
        if token.customer_id == UUID(customer["id"])
        and token.status == CustomerQrTokenStatus.ACTIVE
    ]
    assert active_qr_tokens == []
    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_response.status_code == 401
    old_login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "remove-customer@example.com", "password": "strong-password"},
    )
    assert old_login_response.status_code == 401
    reregister_response = client.post(
        "/api/v1/auth/register/customer/start",
        json={
            "email": "remove-customer@example.com",
            "password": "strong-password",
            "full_name": "Customer Again",
        },
    )
    assert reregister_response.status_code == 202


def test_customer_can_update_own_profile_name(client: TestClient) -> None:
    register_customer(client, email="profile-customer@example.com")
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "profile-customer@example.com", "password": "strong-password"},
    ).json()["access_token"]

    response = client.patch(
        "/api/v1/customers/me/profile",
        json={"full_name": "Customer Updated"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()["full_name"] == "Customer Updated"
    assert response.json()["email"] == "profile-customer@example.com"

    me_response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_response.status_code == 200
    assert me_response.json()["full_name"] == "Customer Updated"


def test_non_customer_cannot_update_customer_profile(client: TestClient) -> None:
    register_owner(
        client,
        email="profile-owner@example.com",
        business_name="Owner Cafe",
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "profile-owner@example.com", "password": "strong-password"},
    ).json()["access_token"]

    response = client.patch(
        "/api/v1/customers/me/profile",
        json={"full_name": "Not Customer"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403


def test_owner_can_create_business_and_staff(client: TestClient) -> None:
    owner_business = register_owner(
        client,
        email="owner@example.com",
        business_name="Zomia Cafe",
        business_category="cafe",
        public_phone="+492222222",
    )
    assert owner_business["slug"] == "zomia-cafe"
    assert owner_business["category"] == "cafe"

    token_response = client.post(
        "/api/v1/auth/login",
        json={"email": "owner@example.com", "password": "strong-password"},
    )
    token = token_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    business_response = client.post(
        "/api/v1/owner/businesses",
        json={
            "name": "Second Shop",
            "legal_name": "Second Shop GmbH",
            "category": "retail",
            "public_email": "hello@second.example",
            "public_phone": "+493333333",
            "website_url": "https://second.example",
            "address_line1": "Main Street 1",
            "city": "Berlin",
            "postal_code": "10115",
            "country_code": "de",
            "timezone": "Europe/Berlin",
            "currency_code": "eur",
        },
        headers=headers,
    )
    assert business_response.status_code == 201
    business = business_response.json()
    business_id = business["id"]
    assert business["slug"] == "second-shop"
    assert business["legal_name"] == "Second Shop GmbH"
    assert business["country_code"] == "DE"
    assert business["currency_code"] == "EUR"

    staff_response = client.post(
        "/api/v1/owner/staff",
        json={
            "business_id": business_id,
            "email": "staff@example.com",
            "password": "strong-password",
            "full_name": "Staff One",
        },
        headers=headers,
    )
    assert staff_response.status_code == 201
    assert staff_response.json()["user"]["role"] == "staff"


def test_owner_can_update_own_business_profile(client: TestClient) -> None:
    business = register_owner(
        client,
        email="profile-owner@example.com",
        business_name="Original Cafe",
        business_category="cafe",
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "profile-owner@example.com", "password": "strong-password"},
    ).json()["access_token"]

    response = client.patch(
        f"/api/v1/owner/businesses/{business['id']}",
        json={
            "name": "Updated Cafe",
            "category": "bakery",
            "public_email": "hello@updated.example",
            "public_phone": "+491234567",
            "website_url": "https://updated.example",
            "address_line1": "Updated Street 1",
            "address_line2": "Back house",
            "city": "Hamburg",
            "region": "Hamburg",
            "postal_code": "20095",
            "country_code": "de",
            "timezone": "Europe/Berlin",
        },
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Updated Cafe"
    assert body["category"] == "bakery"
    assert body["public_email"] == "hello@updated.example"
    assert body["public_phone"] == "+491234567"
    assert body["website_url"] == "https://updated.example"
    assert body["address_line1"] == "Updated Street 1"
    assert body["address_line2"] == "Back house"
    assert body["city"] == "Hamburg"
    assert body["region"] == "Hamburg"
    assert body["postal_code"] == "20095"
    assert body["country_code"] == "DE"
    assert body["slug"] == business["slug"]
    assert body["currency_code"] == "EUR"
    assert body["status"] == "active"


def test_owner_cannot_update_another_owners_business(client: TestClient) -> None:
    business = register_owner(
        client,
        email="profile-owner-a@example.com",
        business_name="Owner A Cafe",
    )
    register_owner(
        client,
        email="profile-owner-b@example.com",
        business_name="Owner B Cafe",
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "profile-owner-b@example.com", "password": "strong-password"},
    ).json()["access_token"]

    response = client.patch(
        f"/api/v1/owner/businesses/{business['id']}",
        json={"name": "Stolen Cafe"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Business not found"


def test_owner_register_accepts_controlled_business_category(
    client: TestClient,
) -> None:
    business = register_owner(
        client,
        email="barber-owner@example.com",
        full_name="Barber Owner",
        business_name="Sharp Cuts",
        business_category="barbershops",
    )

    assert business["category"] == "barbershops"


def test_owner_register_rejects_unsupported_business_category(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/register/owner/start",
        json={
            "email": "invalid-category-owner@example.com",
            "password": "strong-password",
            "full_name": "Invalid Category Owner",
            "business_name": "Random Shop",
            "business_category": "random free text",
        },
    )

    assert response.status_code == 422


def test_staff_can_read_own_context(client: TestClient) -> None:
    business = register_owner(
        client,
        email="owner-context@example.com",
        full_name="Owner Context",
        business_name="Context Cafe",
    )
    owner_token = client.post(
        "/api/v1/auth/login",
        json={"email": "owner-context@example.com", "password": "strong-password"},
    ).json()["access_token"]

    staff_response = client.post(
        "/api/v1/owner/staff",
        json={
            "business_id": business["id"],
            "email": "staff-context@example.com",
            "password": "strong-password",
            "full_name": "Staff Context",
        },
        headers={"Authorization": f"Bearer {owner_token}"},
    )
    assert staff_response.status_code == 201
    staff_token = client.post(
        "/api/v1/auth/login",
        json={"email": "staff-context@example.com", "password": "strong-password"},
    ).json()["access_token"]

    response = client.get(
        "/api/v1/staff/me/context",
        headers={"Authorization": f"Bearer {staff_token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["staff"]["email"] == "staff-context@example.com"
    assert body["businesses"] == [
        {
            "id": business["id"],
            "name": "Context Cafe",
            "slug": "context-cafe",
            "status": "active",
            "timezone": "Europe/Berlin",
            "currency_code": "EUR",
            "staff_membership_id": staff_response.json()["id"],
        }
    ]


def test_owner_can_toggle_staff_active_status(client: TestClient) -> None:
    business = register_owner(
        client,
        email="owner-toggle@example.com",
        full_name="Owner Toggle",
        business_name="Toggle Cafe",
    )
    owner_token = client.post(
        "/api/v1/auth/login",
        json={"email": "owner-toggle@example.com", "password": "strong-password"},
    ).json()["access_token"]
    owner_headers = {"Authorization": f"Bearer {owner_token}"}
    staff_response = client.post(
        "/api/v1/owner/staff",
        json={
            "business_id": business["id"],
            "email": "staff-toggle@example.com",
            "password": "strong-password",
            "full_name": "Staff Toggle",
        },
        headers=owner_headers,
    )
    assert staff_response.status_code == 201
    staff_id = staff_response.json()["id"]
    staff_token = client.post(
        "/api/v1/auth/login",
        json={"email": "staff-toggle@example.com", "password": "strong-password"},
    ).json()["access_token"]

    inactive_response = client.patch(
        f"/api/v1/owner/staff/{staff_id}",
        json={"is_active": False},
        headers=owner_headers,
    )

    assert inactive_response.status_code == 200
    assert inactive_response.json()["is_active"] is False
    context_response = client.get(
        "/api/v1/staff/me/context",
        headers={"Authorization": f"Bearer {staff_token}"},
    )
    assert context_response.status_code == 200
    assert context_response.json()["businesses"] == []

    active_response = client.patch(
        f"/api/v1/owner/staff/{staff_id}",
        json={"is_active": True},
        headers=owner_headers,
    )

    assert active_response.status_code == 200
    assert active_response.json()["is_active"] is True
    context_response = client.get(
        "/api/v1/staff/me/context",
        headers={"Authorization": f"Bearer {staff_token}"},
    )
    assert context_response.status_code == 200
    assert [business["id"] for business in context_response.json()["businesses"]] == [
        business["id"]
    ]


def test_staff_context_can_return_multiple_businesses(
    client: TestClient, db_session: Session
) -> None:
    first_business = register_owner(
        client,
        email="owner-multi-context@example.com",
        full_name="Owner Multi Context",
        business_name="First Context Cafe",
    )
    owner_token = client.post(
        "/api/v1/auth/login",
        json={"email": "owner-multi-context@example.com", "password": "strong-password"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {owner_token}"}
    second_business = client.post(
        "/api/v1/owner/businesses",
        json={"name": "Second Context Cafe"},
        headers=headers,
    ).json()
    staff_response = client.post(
        "/api/v1/owner/staff",
        json={
            "business_id": first_business["id"],
            "email": "staff-multi-context@example.com",
            "password": "strong-password",
            "full_name": "Staff Multi Context",
        },
        headers=headers,
    )
    assert staff_response.status_code == 201
    db_session.add(
        StaffMember(
            business_id=UUID(second_business["id"]),
            user_id=UUID(staff_response.json()["user_id"]),
        )
    )
    db_session.flush()
    staff_token = client.post(
        "/api/v1/auth/login",
        json={"email": "staff-multi-context@example.com", "password": "strong-password"},
    ).json()["access_token"]

    response = client.get(
        "/api/v1/staff/me/context",
        headers={"Authorization": f"Bearer {staff_token}"},
    )

    assert response.status_code == 200
    assert {business["id"] for business in response.json()["businesses"]} == {
        first_business["id"],
        second_business["id"],
    }


def test_non_staff_cannot_read_staff_context(client: TestClient) -> None:
    register_customer(
        client,
        email="not-staff-context@example.com",
        full_name="Not Staff",
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "not-staff-context@example.com", "password": "strong-password"},
    ).json()["access_token"]

    response = client.get(
        "/api/v1/staff/me/context",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403


def test_customer_cannot_create_owner_business(client: TestClient) -> None:
    register_customer(
        client,
        email="customer2@example.com",
        full_name="Customer Two",
    )
    token_response = client.post(
        "/api/v1/auth/login",
        json={"email": "customer2@example.com", "password": "strong-password"},
    )
    token = token_response.json()["access_token"]

    response = client.post(
        "/api/v1/owner/businesses",
        json={"name": "Forbidden Shop"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 403
