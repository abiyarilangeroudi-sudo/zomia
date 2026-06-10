from fastapi.testclient import TestClient


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
