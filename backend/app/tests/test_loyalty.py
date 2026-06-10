from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.loyalty.models import AuditEvent, LoyaltyAction, PointsLedgerEntry


def register_owner(client: TestClient, email: str, business_name: str = "Zomia Cafe") -> tuple[str, str]:
    response = client.post(
        "/api/v1/auth/register/owner",
        json={
            "email": email,
            "password": "strong-password",
            "full_name": "Owner",
            "business_name": business_name,
        },
    )
    assert response.status_code == 201
    business_id = response.json()["id"]
    token = login(client, email)
    return token, business_id


def register_customer(client: TestClient, email: str = "customer@example.com") -> tuple[str, str]:
    response = client.post(
        "/api/v1/auth/register/customer",
        json={
            "email": email,
            "password": "strong-password",
            "full_name": "Customer",
        },
    )
    assert response.status_code == 201
    return login(client, email), response.json()["id"]


def create_staff(client: TestClient, owner_token: str, business_id: str, email: str) -> tuple[str, str]:
    response = client.post(
        "/api/v1/owner/staff",
        json={
            "business_id": business_id,
            "email": email,
            "password": "strong-password",
            "full_name": "Staff",
        },
        headers=auth(owner_token),
    )
    assert response.status_code == 201
    return login(client, email), response.json()["user_id"]


def login(client: TestClient, email: str) -> str:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "strong-password"},
    )
    assert response.status_code == 200
    return response.json()["access_token"]


def create_mission(
    client: TestClient,
    owner_token: str,
    business_id: str,
    *,
    name: str,
    mission_type: str = "purchase",
    point_value: int = 1,
) -> dict:
    response = client.post(
        "/api/v1/owner/missions",
        json={
            "business_id": business_id,
            "name": name,
            "description": f"{name} mission",
            "mission_type": mission_type,
            "point_value": point_value,
        },
        headers=auth(owner_token),
    )
    assert response.status_code == 201
    return response.json()


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_owner_creates_and_lists_missions(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")

    mission = create_mission(
        client,
        owner_token,
        business_id,
        name="Buy Coffee",
        mission_type="purchase",
        point_value=1,
    )
    assert mission["name"] == "Buy Coffee"
    assert mission["point_value"] == 1

    list_response = client.get(
        f"/api/v1/owner/missions?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert list_response.status_code == 200
    assert [item["name"] for item in list_response.json()] == ["Buy Coffee"]


def test_owner_cannot_create_mission_for_another_owner_business(client: TestClient) -> None:
    owner_token, _ = register_owner(client, "owner1@example.com", "Owner One Cafe")
    _, other_business_id = register_owner(client, "owner2@example.com", "Owner Two Cafe")

    response = client.post(
        "/api/v1/owner/missions",
        json={
            "business_id": other_business_id,
            "name": "Forbidden Mission",
            "mission_type": "custom",
            "point_value": 1,
        },
        headers=auth(owner_token),
    )
    assert response.status_code == 404


def test_staff_registers_multi_item_action_and_customer_reads_points(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    coffee = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=1)
    cake = create_mission(client, owner_token, business_id, name="Buy Cake", point_value=5)

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "multi-item-action-1",
            "items": [
                {"mission_id": coffee["id"], "quantity": 2},
                {"mission_id": cake["id"], "quantity": 1},
            ],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 201
    body = response.json()
    assert body["points_granted"] == 7
    assert body["idempotency_replayed"] is False
    assert [item["total_points"] for item in body["items"]] == [2, 5]

    points_response = client.get(
        f"/api/v1/customers/me/points?business_id={business_id}",
        headers=auth(customer_token),
    )
    assert points_response.status_code == 200
    assert points_response.json()["points"] == 7

    points_entries = db_session.scalars(select(PointsLedgerEntry)).all()
    assert len(points_entries) == 2
    assert sum(entry.points for entry in points_entries) == 7

    audit_events = db_session.scalars(select(AuditEvent)).all()
    assert {event.event_type.value for event in audit_events} >= {
        "mission_created",
        "action_recorded",
        "points_granted",
    }


def test_duplicate_idempotency_key_returns_previous_action_without_extra_points(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", mission_type="visit")

    payload = {
        "business_id": business_id,
        "customer_id": customer_id,
        "idempotency_key": "same-request-1",
        "items": [{"mission_id": mission["id"], "quantity": 1}],
    }
    first = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))
    second = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))

    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json()["idempotency_replayed"] is True
    assert second.json()["action_id"] == first.json()["action_id"]

    assert db_session.scalar(select(LoyaltyAction)) is not None
    assert db_session.query(LoyaltyAction).count() == 1
    assert db_session.query(PointsLedgerEntry).count() == 1


def test_staff_cannot_register_action_for_another_business(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    _, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", mission_type="visit")

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": other_business_id,
            "customer_id": customer_id,
            "idempotency_key": "wrong-business-1",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert response.status_code == 403


def test_customer_cannot_register_action(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", mission_type="visit")

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "customer-forbidden-1",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(customer_token),
    )
    assert response.status_code == 403


def test_inactive_or_foreign_mission_cannot_be_used_in_action(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    foreign_mission = create_mission(
        client, other_owner_token, other_business_id, name="Foreign Visit", mission_type="visit"
    )

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": str(uuid4()),
            "items": [{"mission_id": foreign_mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert response.status_code == 404

