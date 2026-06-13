from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.loyalty.models import GeneratedReward, PointsLedgerEntry, RewardUsage
from app.modules.qr.models import CustomerQrToken, CustomerQrTokenStatus
from app.tests.test_loyalty import (
    auth,
    create_campaign,
    create_mission,
    create_reward_template,
    create_staff,
    register_customer,
    register_owner,
)


def issue_qr(client: TestClient, customer_token: str) -> dict:
    response = client.post("/api/v1/customers/me/qr-token", headers=auth(customer_token))
    assert response.status_code == 200
    return response.json()


def test_customer_issues_and_rotates_qr_token(
    client: TestClient, db_session: Session
) -> None:
    customer_token, customer_id = register_customer(client)

    first = issue_qr(client, customer_token)
    second = client.post("/api/v1/customers/me/qr-token/rotate", headers=auth(customer_token))

    assert second.status_code == 200
    assert first["token"] != second.json()["token"]
    tokens = db_session.scalars(select(CustomerQrToken)).all()
    assert len(tokens) == 2
    assert {token.status.value for token in tokens} == {"revoked", "active"}
    assert {str(token.customer_id) for token in tokens} == {customer_id}


def test_old_qr_token_stops_working_after_rotate(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, _ = register_customer(client)
    old_qr = issue_qr(client, customer_token)
    issue_qr(client, customer_token)

    response = client.post(
        "/api/v1/staff/qr/resolve",
        json={"business_id": business_id, "token": old_qr["token"]},
        headers=auth(staff_token),
    )

    assert response.status_code == 400


def test_staff_resolves_qr_for_own_business(client: TestClient, db_session: Session) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    qr = issue_qr(client, customer_token)

    response = client.post(
        "/api/v1/staff/qr/resolve",
        json={"business_id": business_id, "token": qr["token"]},
        headers=auth(staff_token),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["business_id"] == business_id
    assert body["customer"]["id"] == customer_id
    assert body["points"] == 0
    assert body["active_rewards"] == []

    token = db_session.scalar(select(CustomerQrToken).where(CustomerQrToken.status == CustomerQrTokenStatus.ACTIVE))
    assert token is not None
    assert token.last_used_at is not None


def test_inactive_staff_cannot_resolve_qr(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner-inactive@example.com")
    staff_token, staff_user_id = create_staff(
        client, owner_token, business_id, "staff-inactive@example.com"
    )
    customer_token, _ = register_customer(client)
    qr = issue_qr(client, customer_token)
    staff_members = client.get("/api/v1/owner/staff", headers=auth(owner_token)).json()
    staff_member_id = next(
        member["id"] for member in staff_members if member["user_id"] == staff_user_id
    )
    deactivate_response = client.patch(
        f"/api/v1/owner/staff/{staff_member_id}",
        json={"is_active": False},
        headers=auth(owner_token),
    )
    assert deactivate_response.status_code == 200

    response = client.post(
        "/api/v1/staff/qr/resolve",
        json={"business_id": business_id, "token": qr["token"]},
        headers=auth(staff_token),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Staff does not belong to this business"


def test_staff_cannot_resolve_qr_for_another_business(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, _ = register_customer(client)
    qr = issue_qr(client, customer_token)

    response = client.post(
        "/api/v1/staff/qr/resolve",
        json={"business_id": other_business_id, "token": qr["token"]},
        headers=auth(staff_token),
    )

    assert response.status_code == 403
    create_staff(client, other_owner_token, other_business_id, "other-staff@example.com")


def test_staff_lists_service_missions_for_own_business(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    coffee = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=1)
    cake = create_mission(client, owner_token, business_id, name="Buy Cake", point_value=5)
    create_mission(client, other_owner_token, other_business_id, name="Other Visit", point_value=2)

    response = client.get(
        f"/api/v1/staff/service/missions?business_id={business_id}",
        headers=auth(staff_token),
    )

    assert response.status_code == 200
    body = response.json()
    assert {mission["id"] for mission in body} == {coffee["id"], cake["id"]}
    assert {mission["point_value"] for mission in body} == {1, 5}


def test_staff_cannot_list_service_missions_for_another_business(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    _, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")

    response = client.get(
        f"/api/v1/staff/service/missions?business_id={other_business_id}",
        headers=auth(staff_token),
    )

    assert response.status_code == 403


def test_expired_qr_cannot_be_resolved(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, _ = register_customer(client)
    qr = issue_qr(client, customer_token)
    token = db_session.scalar(select(CustomerQrToken))
    assert token is not None
    token.expires_at = datetime.now(UTC) - timedelta(days=1)
    db_session.flush()

    response = client.post(
        "/api/v1/staff/qr/resolve",
        json={"business_id": business_id, "token": qr["token"]},
        headers=auth(staff_token),
    )

    assert response.status_code == 400
    db_session.refresh(token)
    assert token.status == CustomerQrTokenStatus.EXPIRED


def test_staff_registers_action_using_qr_and_gets_updated_summary(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, _ = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    qr = issue_qr(client, customer_token)

    response = client.post(
        "/api/v1/staff/service/actions",
        json={
            "business_id": business_id,
            "qr_token": qr["token"],
            "idempotency_key": "qr-action-1",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["action"]["points_granted"] == 5
    assert body["summary"]["points"] == 5
    assert len(body["summary"]["active_rewards"]) == 1
    assert body["summary"]["recent_actions"][0]["action_type"] == "mission_progress"
    assert db_session.query(PointsLedgerEntry).count() == 1
    assert db_session.query(GeneratedReward).count() == 1


def test_staff_uses_reward_using_qr_service_endpoint(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, _ = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    qr = issue_qr(client, customer_token)
    client.post(
        "/api/v1/staff/service/actions",
        json={
            "business_id": business_id,
            "qr_token": qr["token"],
            "idempotency_key": "qr-reward-source",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    reward = db_session.scalar(select(GeneratedReward))
    assert reward is not None

    response = client.post(
        f"/api/v1/staff/service/rewards/{reward.id}/use",
        json={
            "business_id": business_id,
            "qr_token": qr["token"],
            "idempotency_key": "qr-use-reward-1",
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["reward_use"]["reward"]["status"] == "used"
    assert body["summary"]["active_rewards"] == []
    assert db_session.query(RewardUsage).count() == 1
    assert db_session.query(PointsLedgerEntry).count() == 1


def test_staff_cannot_use_reward_by_qr_for_another_customer(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    first_customer_token, first_customer_id = register_customer(client, "first@example.com")
    second_customer_token, _ = register_customer(client, "second@example.com")
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    first_qr = issue_qr(client, first_customer_token)
    second_qr = issue_qr(client, second_customer_token)
    client.post(
        "/api/v1/staff/service/actions",
        json={
            "business_id": business_id,
            "qr_token": first_qr["token"],
            "idempotency_key": "qr-other-customer-source",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    reward = db_session.scalar(select(GeneratedReward))
    assert reward is not None
    assert str(reward.customer_id) == first_customer_id

    response = client.post(
        f"/api/v1/staff/service/rewards/{reward.id}/use",
        json={
            "business_id": business_id,
            "qr_token": second_qr["token"],
            "idempotency_key": "qr-wrong-customer-use",
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 403
