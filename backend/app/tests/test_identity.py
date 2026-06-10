from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.modules.identity.models import StaffMember


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

    me_response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "customer@example.com"


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
