import hashlib
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.modules.identity.models import RefreshToken, StaffMember


def test_customer_registration_login_and_me(client: TestClient) -> None:
    register_response = client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": "customer@example.com",
            "password": "strong-password",
            "full_name": "Customer One",
            "phone": "+491111111",
        },
    )
    assert register_response.status_code == 201
    assert register_response.json()["role"] == "customer"

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


def test_refresh_token_rotates_and_raw_token_is_not_stored(
    client: TestClient, db_session: Session
) -> None:
    client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": "refresh-customer@example.com",
            "password": "strong-password",
            "full_name": "Customer One",
        },
    )
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "refresh-customer@example.com", "password": "strong-password"},
    )
    old_refresh_token = login_response.json()["refresh_token"]
    stored_token = db_session.query(RefreshToken).one()

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
    client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": "logout-customer@example.com",
            "password": "strong-password",
            "full_name": "Customer One",
        },
    )
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "logout-customer@example.com", "password": "strong-password"},
    )
    refresh_token = login_response.json()["refresh_token"]
    stored_token = db_session.query(RefreshToken).one()

    logout_response = client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})

    assert logout_response.status_code == 204
    db_session.refresh(stored_token)
    assert stored_token.revoked_at is not None
    refresh_response = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_response.status_code == 401


def test_customer_can_update_own_profile_name(client: TestClient) -> None:
    register_response = client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": "profile-customer@example.com",
            "password": "strong-password",
            "full_name": "Customer One",
        },
    )
    assert register_response.status_code == 201
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
    owner_response = client.post(
        "/api/v1/auth/register/owner",
        json={
            "email": "profile-owner@example.com",
            "password": "strong-password",
            "full_name": "Owner One",
            "business_name": "Owner Cafe",
        },
    )
    assert owner_response.status_code == 201
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
    owner_response = client.post(
        "/api/v1/auth/register/owner",
        json={
            "email": "owner@example.com",
            "password": "strong-password",
            "full_name": "Owner One",
            "business_name": "Zomia Cafe",
            "business_category": "cafe",
            "public_phone": "+492222222",
        },
    )
    assert owner_response.status_code == 201
    assert owner_response.json()["slug"] == "zomia-cafe"
    assert owner_response.json()["category"] == "cafe"

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


def test_owner_register_accepts_controlled_business_category(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/register/owner",
        json={
            "email": "barber-owner@example.com",
            "password": "strong-password",
            "full_name": "Barber Owner",
            "business_name": "Sharp Cuts",
            "business_category": "barbershops",
        },
    )

    assert response.status_code == 201
    assert response.json()["category"] == "barbershops"


def test_owner_register_rejects_unsupported_business_category(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/register/owner",
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
    owner_response = client.post(
        "/api/v1/auth/register/owner",
        json={
            "email": "owner-context@example.com",
            "password": "strong-password",
            "full_name": "Owner Context",
            "business_name": "Context Cafe",
        },
    )
    assert owner_response.status_code == 201
    business = owner_response.json()
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
    owner_response = client.post(
        "/api/v1/auth/register/owner",
        json={
            "email": "owner-toggle@example.com",
            "password": "strong-password",
            "full_name": "Owner Toggle",
            "business_name": "Toggle Cafe",
        },
    )
    assert owner_response.status_code == 201
    business = owner_response.json()
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
    owner_response = client.post(
        "/api/v1/auth/register/owner",
        json={
            "email": "owner-multi-context@example.com",
            "password": "strong-password",
            "full_name": "Owner Multi Context",
            "business_name": "First Context Cafe",
        },
    )
    assert owner_response.status_code == 201
    first_business = owner_response.json()
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
    client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": "not-staff-context@example.com",
            "password": "strong-password",
            "full_name": "Not Staff",
        },
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
    client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": "customer2@example.com",
            "password": "strong-password",
            "full_name": "Customer Two",
        },
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
