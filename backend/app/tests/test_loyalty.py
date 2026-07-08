from datetime import UTC, datetime, timedelta
import re
from uuid import UUID, uuid4

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.loyalty.models import (
    AuditEvent,
    Campaign,
    CampaignCompletion,
    GeneratedReward,
    LoyaltyAction,
    PointsLedgerEntry,
    RewardUsage,
)


def register_owner(
    client: TestClient, email: str, business_name: str = "Zomia Cafe"
) -> tuple[str, str]:
    response = client.post(
        "/api/v1/auth/register/owner/start",
        json={
            "email": email,
            "password": "strong-password",
            "full_name": "Owner",
            "business_name": business_name,
        },
    )
    assert response.status_code == 202
    verify_response = client.post(
        "/api/v1/auth/register/owner/verify",
        json={"email": email, "code": "123456"},
    )
    assert verify_response.status_code == 200
    token = login(client, email)
    business_response = client.get("/api/v1/owner/businesses", headers=auth(token))
    assert business_response.status_code == 200
    business_id = business_response.json()[0]["id"]
    return token, business_id


def register_customer(client: TestClient, email: str = "customer@example.com") -> tuple[str, str]:
    response = client.post(
        "/api/v1/auth/register/customer/start",
        json={
            "email": email,
            "password": "strong-password",
            "full_name": "Customer",
        },
    )
    assert response.status_code == 202
    verify_response = client.post(
        "/api/v1/auth/register/customer/verify",
        json={"email": email, "code": "123456"},
    )
    assert verify_response.status_code == 200
    token = login(client, email)
    me_response = client.get("/api/v1/auth/me", headers=auth(token))
    assert me_response.status_code == 200
    return token, me_response.json()["id"]


def create_staff(
    client: TestClient, owner_token: str, business_id: str, email: str
) -> tuple[str, str]:
    response = client.post(
        "/api/v1/owner/staff/invitations",
        json={
            "business_id": business_id,
            "email": email,
        },
        headers=auth(owner_token),
    )
    assert response.status_code == 201
    token = latest_invitation_token(client)
    preview_response = client.get(
        "/api/v1/auth/staff-invitations/preview",
        params={"token": token},
    )
    assert preview_response.status_code == 200
    accept_response = client.post(
        "/api/v1/auth/staff-invitations/accept",
        json={"token": token, "password": "strong-password"},
    )
    assert accept_response.status_code == 204
    staff_token = login(client, email)
    me_response = client.get("/api/v1/auth/me", headers=auth(staff_token))
    assert me_response.status_code == 200
    return staff_token, me_response.json()["id"]


def latest_invitation_token(client: TestClient) -> str:
    body = client.app.state.email_sender.sent[-1]["body"]
    match = re.search(r"accept-staff-invitation\?token=([A-Za-z0-9_-]+)", body)
    assert match is not None
    return match.group(1)


def test_owner_can_cancel_pending_staff_invitation(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    invite_response = client.post(
        "/api/v1/owner/staff/invitations",
        json={"business_id": business_id, "email": "wrong-staff@example.com"},
        headers=auth(owner_token),
    )
    assert invite_response.status_code == 201
    invitation_id = invite_response.json()["invitation_id"]
    invitation_token = latest_invitation_token(client)

    cancel_response = client.delete(
        f"/api/v1/owner/staff/invitations/{invitation_id}",
        headers=auth(owner_token),
    )
    assert cancel_response.status_code == 204

    staff_response = client.get("/api/v1/owner/staff", headers=auth(owner_token))
    assert staff_response.status_code == 200
    assert staff_response.json() == []

    accept_response = client.post(
        "/api/v1/auth/staff-invitations/accept",
        json={"token": invitation_token, "password": "strong-password"},
    )
    assert accept_response.status_code == 400
    assert accept_response.json()["detail"] == "Invitation used"

    replacement_response = client.post(
        "/api/v1/owner/staff/invitations",
        json={"business_id": business_id, "email": "wrong-staff@example.com"},
        headers=auth(owner_token),
    )
    assert replacement_response.status_code == 201


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


def create_campaign(
    client: TestClient,
    owner_token: str,
    business_id: str,
    *,
    mission_ids: list[str],
    reward_template_id: str | None = None,
    threshold_points: int = 5,
    starts_at: datetime | None = None,
    ends_at: datetime | None = None,
    is_repeatable: bool = False,
    max_completions_per_customer: int | None = None,
) -> dict:
    starts_at = starts_at or datetime.now(UTC) - timedelta(days=1)
    ends_at = ends_at or datetime.now(UTC) + timedelta(days=30)
    if reward_template_id is None:
        reward_template = create_reward_template(client, owner_token, business_id)
        reward_template_id = reward_template["id"]
    response = client.post(
        "/api/v1/owner/campaigns",
        json={
            "creator_business_id": business_id,
            "reward_template_id": reward_template_id,
            "name": "Coffee Lover",
            "description": "Reach the threshold",
            "threshold_points": threshold_points,
            "is_repeatable": is_repeatable,
            "max_completions_per_customer": max_completions_per_customer,
            "starts_at": starts_at.isoformat(),
            "ends_at": ends_at.isoformat(),
            "mission_ids": mission_ids,
        },
        headers=auth(owner_token),
    )
    assert response.status_code == 201
    return response.json()


def create_reward_template(
    client: TestClient,
    owner_token: str,
    business_id: str,
    legacy_campaign_id: str | None = None,
    *,
    reward_type: str = "gift",
    name: str = "Free Coffee",
    gift_name: str | None = "Free coffee",
    discount_percent: int | None = None,
    discount_amount_minor: int | None = None,
    currency_code: str | None = None,
    valid_days: int = 30,
) -> dict:
    if legacy_campaign_id is not None:
        campaigns = client.get(
            "/api/v1/owner/campaigns",
            params={"business_id": business_id},
            headers=auth(owner_token),
        )
        assert campaigns.status_code == 200
        campaign = next(item for item in campaigns.json() if item["id"] == legacy_campaign_id)
        templates = client.get(
            "/api/v1/owner/reward-templates",
            params={"business_id": business_id},
            headers=auth(owner_token),
        )
        assert templates.status_code == 200
        return next(
            item for item in templates.json() if item["id"] == campaign["reward_template_id"]
        )

    payload = {
        "business_id": business_id,
        "name": name,
        "description": f"{name} reward",
        "reward_type": reward_type,
        "valid_days": valid_days,
    }
    if gift_name is not None:
        payload["gift_name"] = gift_name
    if discount_percent is not None:
        payload["discount_percent"] = discount_percent
    if discount_amount_minor is not None:
        payload["discount_amount_minor"] = discount_amount_minor
    if currency_code is not None:
        payload["currency_code"] = currency_code

    response = client.post(
        "/api/v1/owner/reward-templates",
        json=payload,
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


def test_owner_updates_and_deletes_unused_mission(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")

    update_response = client.patch(
        f"/api/v1/owner/missions/{mission['id']}?business_id={business_id}",
        json={"name": "Buy Tea", "point_value": 2},
        headers=auth(owner_token),
    )
    assert update_response.status_code == 200
    assert update_response.json()["name"] == "Buy Tea"
    assert update_response.json()["point_value"] == 2

    delete_response = client.delete(
        f"/api/v1/owner/missions/{mission['id']}?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert delete_response.status_code == 204

    list_response = client.get(
        f"/api/v1/owner/missions?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert list_response.status_code == 200
    assert list_response.json() == []


def test_owner_cannot_update_or_delete_used_mission(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    create_campaign(client, owner_token, business_id, mission_ids=[mission["id"]])

    update_response = client.patch(
        f"/api/v1/owner/missions/{mission['id']}?business_id={business_id}",
        json={"name": "Buy Tea", "point_value": 2},
        headers=auth(owner_token),
    )
    assert update_response.status_code == 409
    assert update_response.json()["detail"] == "Mission is already used"

    delete_response = client.delete(
        f"/api/v1/owner/missions/{mission['id']}?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert delete_response.status_code == 409
    assert delete_response.json()["detail"] == "Mission is already used"


def test_owner_archives_used_mission_and_hides_it_from_active_lists(
    client: TestClient,
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    campaign = create_campaign(client, owner_token, business_id, mission_ids=[mission["id"]])

    list_response = client.get(
        f"/api/v1/owner/missions?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert list_response.status_code == 200
    listed_mission = next(item for item in list_response.json() if item["id"] == mission["id"])
    assert listed_mission["can_edit"] is False
    assert listed_mission["can_delete"] is False
    assert listed_mission["can_archive"] is False

    blocked_response = client.patch(
        f"/api/v1/owner/missions/{mission['id']}/active?business_id={business_id}",
        json={"is_active": False},
        headers=auth(owner_token),
    )
    assert blocked_response.status_code == 409
    assert blocked_response.json()["detail"] == "Mission is used by an active campaign"

    end_response = client.patch(
        f"/api/v1/owner/campaigns/{campaign['id']}/status?business_id={business_id}",
        json={"status": "ended"},
        headers=auth(owner_token),
    )
    assert end_response.status_code == 200

    refreshed_response = client.get(
        f"/api/v1/owner/missions?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert refreshed_response.status_code == 200
    refreshed_mission = next(
        item for item in refreshed_response.json() if item["id"] == mission["id"]
    )
    assert refreshed_mission["can_archive"] is True

    archive_response = client.patch(
        f"/api/v1/owner/missions/{mission['id']}/active?business_id={business_id}",
        json={"is_active": False},
        headers=auth(owner_token),
    )
    assert archive_response.status_code == 200
    assert archive_response.json()["is_active"] is False

    hidden_response = client.get(
        f"/api/v1/owner/missions?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert hidden_response.status_code == 200
    assert all(item["id"] != mission["id"] for item in hidden_response.json())


def test_owner_can_archive_used_mission_after_campaign_expires(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        starts_at=datetime.now(UTC) - timedelta(days=10),
        ends_at=datetime.now(UTC) - timedelta(days=1),
    )

    list_response = client.get(
        f"/api/v1/owner/missions?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert list_response.status_code == 200
    listed_mission = next(item for item in list_response.json() if item["id"] == mission["id"])
    assert listed_mission["can_archive"] is True


def test_owner_cannot_update_or_delete_mission_with_action_history(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")

    action_response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "mission-action-history",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert action_response.status_code == 201

    update_response = client.patch(
        f"/api/v1/owner/missions/{mission['id']}?business_id={business_id}",
        json={"name": "Buy Tea", "point_value": 2},
        headers=auth(owner_token),
    )
    assert update_response.status_code == 409

    delete_response = client.delete(
        f"/api/v1/owner/missions/{mission['id']}?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert delete_response.status_code == 409


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


def test_owner_reads_recent_activity_for_business(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    coffee = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=1)
    cake = create_mission(client, owner_token, business_id, name="Buy Cake", point_value=5)

    action_response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "owner-activity-1",
            "items": [
                {"mission_id": coffee["id"], "quantity": 2},
                {"mission_id": cake["id"], "quantity": 1},
            ],
        },
        headers=auth(staff_token),
    )
    assert action_response.status_code == 201

    response = client.get(
        f"/api/v1/owner/activity/recent?business_id={business_id}",
        headers=auth(owner_token),
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["action_id"] == action_response.json()["action_id"]
    assert body[0]["action_type"] == "mission_progress"
    assert body[0]["staff_name"] == "staff"
    assert body[0]["staff_email"] == "staff@example.com"
    assert body[0]["customer_name"] == "Customer"
    assert body[0]["customer_email"] == "customer@example.com"
    assert body[0]["points_granted"] == 7
    assert body[0]["summary"] == "Buy Coffee x2, Buy Cake x1"
    assert body[0]["created_at"] is not None


def test_owner_recent_activity_handles_deleted_customer(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(
        client, owner_token, business_id, name="Buy Coffee", point_value=1
    )
    action_response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "owner-activity-deleted-customer",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert action_response.status_code == 201
    remove_response = client.post(
        "/api/v1/auth/remove-account",
        json={"current_password": "strong-password"},
        headers=auth(customer_token),
    )
    assert remove_response.status_code == 204

    response = client.get(
        f"/api/v1/owner/activity/recent?business_id={business_id}",
        headers=auth(owner_token),
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["customer_name"] == "Deleted customer"
    assert body[0]["customer_email"] is None
    assert body[0]["summary"] == "Buy Coffee x1"


def test_owner_cannot_read_recent_activity_for_another_owner_business(
    client: TestClient,
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    staff_token, _ = create_staff(client, other_owner_token, other_business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(
        client, other_owner_token, other_business_id, name="Foreign Coffee", point_value=1
    )

    action_response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": other_business_id,
            "customer_id": customer_id,
            "idempotency_key": "owner-activity-forbidden",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert action_response.status_code == 201

    response = client.get(
        f"/api/v1/owner/activity/recent?business_id={other_business_id}",
        headers=auth(owner_token),
    )

    assert response.status_code == 404


def test_customer_reads_reward_status_history(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "customer-status-action",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert response.status_code == 201

    status_response = client.get(
        "/api/v1/customers/me/status",
        headers=auth(customer_token),
    )

    assert status_response.status_code == 200
    body = status_response.json()
    assert body["customer_id"] == customer_id
    assert body["active_rewards_count"] == 1
    assert len(body["businesses"]) == 1
    assert body["businesses"][0]["business_id"] == business_id
    reward = body["businesses"][0]["rewards"][0]
    assert reward["status"] == "active"

    use_response = client.post(
        f"/api/v1/staff/rewards/{reward['id']}/use",
        json={
            "business_id": business_id,
            "idempotency_key": "customer-status-use-reward",
        },
        headers=auth(staff_token),
    )
    assert use_response.status_code == 200

    used_status_response = client.get(
        "/api/v1/customers/me/status",
        headers=auth(customer_token),
    )

    assert used_status_response.status_code == 200
    used_body = used_status_response.json()
    assert used_body["active_rewards_count"] == 0
    assert len(used_body["businesses"]) == 1
    assert used_body["businesses"][0]["business_id"] == business_id
    assert used_body["businesses"][0]["rewards"][0]["id"] == reward["id"]
    assert used_body["businesses"][0]["rewards"][0]["status"] == "used"


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


def test_owner_creates_and_lists_campaigns(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")

    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=10,
    )

    assert campaign["name"] == "Coffee Lover"
    assert campaign["campaign_type"] == "individual"
    assert campaign["scope_type"] == "single_business"
    assert campaign["participation_mode"] == "automatic"
    assert campaign["progress_metric"] == "points"
    assert campaign["threshold_points"] == 10
    assert campaign["is_repeatable"] is False
    assert campaign["max_completions_per_customer"] is None
    assert campaign["time_status"] == "active"
    assert campaign["display_status"] == "Active"
    assert campaign["badge_tone"] == "info"
    assert campaign["date_range_label"]

    response = client.get(
        f"/api/v1/owner/campaigns?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert response.status_code == 200
    assert [item["id"] for item in response.json()] == [campaign["id"]]
    assert response.json()[0]["display_status"] == "Active"


def test_owner_campaigns_expose_display_statuses(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")

    upcoming = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        starts_at=datetime.now(UTC) + timedelta(days=1),
        ends_at=datetime.now(UTC) + timedelta(days=30),
    )
    expired = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        starts_at=datetime.now(UTC) - timedelta(days=30),
        ends_at=datetime.now(UTC) - timedelta(days=1),
    )
    active = create_campaign(client, owner_token, business_id, mission_ids=[mission["id"]])

    ended_response = client.patch(
        f"/api/v1/owner/campaigns/{upcoming['id']}/status?business_id={business_id}",
        json={"status": "ended"},
        headers=auth(owner_token),
    )
    assert ended_response.status_code == 200

    response = client.get(
        f"/api/v1/owner/campaigns?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert response.status_code == 200
    campaigns = {item["id"]: item for item in response.json()}

    assert campaigns[upcoming["id"]]["time_status"] == "upcoming"
    assert campaigns[upcoming["id"]]["display_status"] == "Ended"
    assert campaigns[upcoming["id"]]["badge_tone"] == "neutral"
    assert campaigns[expired["id"]]["time_status"] == "expired"
    assert campaigns[expired["id"]]["display_status"] == "Expired"
    assert campaigns[expired["id"]]["badge_tone"] == "warning"
    assert campaigns[active["id"]]["time_status"] == "active"
    assert campaigns[active["id"]]["display_status"] == "Active"
    assert campaigns[active["id"]]["badge_tone"] == "info"


def test_owner_ends_campaign_and_cannot_change_it_again(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    campaign = create_campaign(client, owner_token, business_id, mission_ids=[mission["id"]])

    active_response = client.patch(
        f"/api/v1/owner/campaigns/{campaign['id']}/status?business_id={business_id}",
        json={"status": "active"},
        headers=auth(owner_token),
    )
    assert active_response.status_code == 400
    assert active_response.json()["detail"] == "Unsupported campaign status"

    end_response = client.patch(
        f"/api/v1/owner/campaigns/{campaign['id']}/status?business_id={business_id}",
        json={"status": "ended"},
        headers=auth(owner_token),
    )
    assert end_response.status_code == 200
    assert end_response.json()["status"] == "ended"

    ended_active_response = client.patch(
        f"/api/v1/owner/campaigns/{campaign['id']}/status?business_id={business_id}",
        json={"status": "active"},
        headers=auth(owner_token),
    )
    assert ended_active_response.status_code == 409
    assert ended_active_response.json()["detail"] == "Campaign is already ended"


def test_unsupported_campaign_status_is_rejected(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    campaign = create_campaign(client, owner_token, business_id, mission_ids=[mission["id"]])

    response = client.patch(
        f"/api/v1/owner/campaigns/{campaign['id']}/status?business_id={business_id}",
        json={"status": "paused"},
        headers=auth(owner_token),
    )
    assert response.status_code == 422


def test_owner_cannot_create_campaign_with_foreign_mission(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    foreign_mission = create_mission(
        client, other_owner_token, other_business_id, name="Foreign Mission"
    )
    reward_template = create_reward_template(client, owner_token, business_id)

    response = client.post(
        "/api/v1/owner/campaigns",
        json={
            "creator_business_id": business_id,
            "reward_template_id": reward_template["id"],
            "name": "Invalid Campaign",
            "threshold_points": 5,
            "starts_at": (datetime.now(UTC) - timedelta(days=1)).isoformat(),
            "ends_at": (datetime.now(UTC) + timedelta(days=10)).isoformat(),
            "mission_ids": [foreign_mission["id"]],
        },
        headers=auth(owner_token),
    )

    assert response.status_code == 404


def test_action_below_threshold_updates_campaign_progress_without_completion(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=1)
    starts_at = datetime.now(UTC) - timedelta(days=1)
    ends_at = datetime.now(UTC) + timedelta(days=30)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
        starts_at=starts_at,
        ends_at=ends_at,
    )

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "campaign-below-threshold",
            "items": [{"mission_id": mission["id"], "quantity": 2}],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 201
    assert db_session.query(CampaignCompletion).count() == 0

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    expected_starts_at = starts_at.replace(tzinfo=None).isoformat()
    expected_ends_at = ends_at.replace(tzinfo=None).isoformat()
    assert progress.json()["starts_at"] == expected_starts_at
    assert progress.json()["ends_at"] == expected_ends_at
    assert progress.json()["progress_points"] == 2
    assert progress.json()["is_completed"] is False
    assert progress.json()["campaign_time_status"] == "active"
    assert progress.json()["progress_state"] == "in_progress"
    assert progress.json()["display_label"] == "2/5 pts · 3 pts to reward"
    assert progress.json()["badge_label"] == "Active"
    assert progress.json()["badge_tone"] == "info"

    progresses = client.get(
        "/api/v1/customers/me/campaigns/progress",
        headers=auth(customer_token),
    )
    assert progresses.status_code == 200
    assert progresses.json() == [
        {
            "business_id": business_id,
            "business_name": "Zomia Cafe",
            "campaign_id": campaign["id"],
            "campaign_name": campaign["name"],
            "starts_at": expected_starts_at,
            "ends_at": expected_ends_at,
            "progress_points": 2,
            "threshold_points": 5,
            "remaining_points": 3,
            "is_completed": False,
            "is_repeatable": False,
            "completed_cycles": 0,
            "current_cycle_number": 1,
            "max_completions_per_customer": None,
            "campaign_time_status": "active",
            "progress_state": "in_progress",
            "display_label": "2/5 pts · 3 pts to reward",
            "badge_label": "Active",
            "badge_tone": "info",
        }
    ]


def test_action_reaching_threshold_creates_campaign_completion(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Cake", point_value=5)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
    )

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "campaign-complete-1",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 201
    completion = db_session.scalar(select(CampaignCompletion))
    assert completion is not None
    assert completion.progress_points == 5
    assert completion.reward_generated_at is not None

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["progress_points"] == 5
    assert progress.json()["is_completed"] is True
    assert progress.json()["campaign_time_status"] == "active"
    assert progress.json()["progress_state"] == "completed"
    assert progress.json()["display_label"] == "5/5 pts · Completed"
    assert progress.json()["badge_label"] == "Completed"
    assert progress.json()["badge_tone"] == "success"

    audit_events = db_session.scalars(select(AuditEvent)).all()
    assert "campaign_completed" in {event.event_type.value for event in audit_events}


def test_idempotency_replay_does_not_duplicate_campaign_completion(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=3)
    create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=3,
    )
    payload = {
        "business_id": business_id,
        "customer_id": customer_id,
        "idempotency_key": "campaign-idempotent-1",
        "items": [{"mission_id": mission["id"], "quantity": 1}],
    }

    first = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))
    second = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))

    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json()["idempotency_replayed"] is True
    assert db_session.query(CampaignCompletion).count() == 1


def test_action_outside_campaign_window_does_not_count_for_progress(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=5)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
        starts_at=datetime.now(UTC) + timedelta(days=1),
        ends_at=datetime.now(UTC) + timedelta(days=30),
    )

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "campaign-window-1",
            "occurred_at": datetime.now(UTC).isoformat(),
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 201
    assert db_session.query(CampaignCompletion).count() == 0

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["progress_points"] == 0
    assert progress.json()["is_completed"] is False
    assert progress.json()["campaign_time_status"] == "upcoming"
    assert progress.json()["progress_state"] == "in_progress"
    assert progress.json()["display_label"] == "0/5 pts · Upcoming"
    assert progress.json()["badge_label"] == "Upcoming"
    assert progress.json()["badge_tone"] == "warning"


def test_action_before_campaign_creation_does_not_count_for_progress(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=5)

    earlier_action = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "pre-campaign-action",
            "occurred_at": datetime.now(UTC).isoformat(),
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert earlier_action.status_code == 201

    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
        starts_at=datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0),
        ends_at=datetime.now(UTC) + timedelta(days=30),
    )

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["progress_points"] == 0
    assert progress.json()["remaining_points"] == 5
    assert progress.json()["progress_state"] == "in_progress"
    assert progress.json()["display_label"] == "0/5 pts · 5 pts to reward"
    assert db_session.query(CampaignCompletion).count() == 0


def test_ended_campaign_returns_backend_owned_progress_status(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=5)
    starts_at = datetime.now(UTC) - timedelta(days=10)
    ends_at = datetime.now(UTC) - timedelta(days=5)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
        starts_at=starts_at,
        ends_at=ends_at,
    )

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "campaign-ended-status",
            "occurred_at": (starts_at + timedelta(days=1)).isoformat(),
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 201
    assert db_session.query(CampaignCompletion).count() == 0

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["campaign_time_status"] == "ended"
    assert progress.json()["progress_state"] == "ended"
    assert progress.json()["display_label"] == "0/5 pts · Ended"
    assert progress.json()["badge_label"] == "Ended"
    assert progress.json()["badge_tone"] == "neutral"


def test_owner_ended_campaign_remains_in_customer_campaign_archive(
    client: TestClient,
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=2)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
    )

    action_response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "manual-end-before-archive",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    assert action_response.status_code == 201

    end_response = client.patch(
        f"/api/v1/owner/campaigns/{campaign['id']}/status?business_id={business_id}",
        json={"status": "ended"},
        headers=auth(owner_token),
    )
    assert end_response.status_code == 200

    progresses = client.get(
        "/api/v1/customers/me/campaigns/progress",
        headers=auth(customer_token),
    )
    assert progresses.status_code == 200
    body = progresses.json()
    assert len(body) == 1
    assert body[0]["campaign_id"] == campaign["id"]
    assert body[0]["campaign_time_status"] == "ended"
    assert body[0]["progress_state"] == "ended"
    assert body[0]["display_label"] == "2/5 pts · Ended"
    assert body[0]["badge_label"] == "Ended"
    assert body[0]["badge_tone"] == "neutral"


def test_repeatable_campaign_does_not_create_new_cycle_after_end(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=1)
    now = datetime.now(UTC)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=2,
        starts_at=now - timedelta(days=10),
        ends_at=now + timedelta(days=10),
        is_repeatable=True,
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    stored_campaign = db_session.get(Campaign, UUID(campaign["id"]))
    assert stored_campaign is not None
    stored_campaign.created_at = now - timedelta(days=2)
    db_session.commit()

    first = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "repeatable-before-end",
            "occurred_at": (now - timedelta(days=1)).isoformat(),
            "items": [{"mission_id": mission["id"], "quantity": 2}],
        },
        headers=auth(staff_token),
    )
    assert first.status_code == 201
    assert db_session.query(CampaignCompletion).count() == 1
    assert db_session.query(GeneratedReward).count() == 1

    stored_campaign.ends_at = now - timedelta(hours=12)
    db_session.commit()

    second = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "repeatable-after-end",
            "occurred_at": now.isoformat(),
            "items": [{"mission_id": mission["id"], "quantity": 2}],
        },
        headers=auth(staff_token),
    )
    assert second.status_code == 201
    assert db_session.query(CampaignCompletion).count() == 1
    assert db_session.query(GeneratedReward).count() == 1

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["campaign_time_status"] == "ended"
    assert progress.json()["progress_state"] == "ended"
    assert progress.json()["completed_cycles"] == 1
    assert progress.json()["current_cycle_number"] == 2
    assert progress.json()["progress_points"] == 0
    assert progress.json()["remaining_points"] == 2
    assert progress.json()["display_label"] == "Cycle 2 · 0/2 pts · Ended"


def test_non_repeatable_campaign_creates_only_one_completion(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
    )

    for index in range(2):
        response = client.post(
            "/api/v1/staff/actions",
            json={
                "business_id": business_id,
                "customer_id": customer_id,
                "idempotency_key": f"non-repeatable-{index}",
                "items": [{"mission_id": mission["id"], "quantity": 1}],
            },
            headers=auth(staff_token),
        )
        assert response.status_code == 201

    assert db_session.query(CampaignCompletion).count() == 1


def test_repeatable_campaign_creates_reward_for_each_completed_cycle(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=1)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
        is_repeatable=True,
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])

    first = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "repeatable-cycle-1",
            "items": [{"mission_id": mission["id"], "quantity": 5}],
        },
        headers=auth(staff_token),
    )
    second = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "repeatable-cycle-2",
            "items": [{"mission_id": mission["id"], "quantity": 7}],
        },
        headers=auth(staff_token),
    )

    assert first.status_code == 201
    assert second.status_code == 201
    completions = db_session.scalars(
        select(CampaignCompletion).order_by(CampaignCompletion.completion_number)
    ).all()
    assert [completion.completion_number for completion in completions] == [1, 2]
    assert db_session.query(GeneratedReward).count() == 2

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["progress_points"] == 2
    assert progress.json()["remaining_points"] == 3
    assert progress.json()["is_completed"] is False
    assert progress.json()["is_repeatable"] is True
    assert progress.json()["completed_cycles"] == 2
    assert progress.json()["current_cycle_number"] == 3
    assert progress.json()["max_completions_per_customer"] is None
    assert progress.json()["campaign_time_status"] == "active"
    assert progress.json()["progress_state"] == "in_progress"
    assert progress.json()["display_label"] == "Cycle 3 · 2/5 pts · 3 pts to reward"
    assert progress.json()["badge_label"] == "Active"
    assert progress.json()["badge_tone"] == "info"


def test_repeatable_campaign_respects_max_completions_per_customer(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Tea", point_value=1)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
        is_repeatable=True,
        max_completions_per_customer=2,
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "repeatable-max-1",
            "items": [{"mission_id": mission["id"], "quantity": 20}],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 201
    assert db_session.query(CampaignCompletion).count() == 2
    assert db_session.query(GeneratedReward).count() == 2

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["progress_points"] == 5
    assert progress.json()["remaining_points"] == 0
    assert progress.json()["is_completed"] is True
    assert progress.json()["completed_cycles"] == 2
    assert progress.json()["current_cycle_number"] == 2
    assert progress.json()["max_completions_per_customer"] == 2
    assert progress.json()["campaign_time_status"] == "active"
    assert progress.json()["progress_state"] == "limit_reached"
    assert progress.json()["display_label"] == "Cycle 2 · 5/5 pts · Limit reached"
    assert progress.json()["badge_label"] == "Limit reached"
    assert progress.json()["badge_tone"] == "success"


def test_repeatable_campaign_idempotency_replay_does_not_duplicate_cycles(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Cake", point_value=1)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
        is_repeatable=True,
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    payload = {
        "business_id": business_id,
        "customer_id": customer_id,
        "idempotency_key": "repeatable-replay-1",
        "items": [{"mission_id": mission["id"], "quantity": 12}],
    }

    first = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))
    second = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))

    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json()["idempotency_replayed"] is True
    assert db_session.query(CampaignCompletion).count() == 2
    assert db_session.query(GeneratedReward).count() == 2


def test_owner_creates_reward_templates_for_all_mvp_types(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    gift = create_reward_template(
        client,
        owner_token,
        business_id,
        reward_type="gift",
        gift_name="Free coffee",
    )
    assert gift["reward_type"] == "gift"
    assert gift["issuer_business_id"] == business_id
    assert gift["redeem_scope"] == "issuer_business_only"
    assert gift["settlement_policy"] == "issuer_pays"

    percentage = create_reward_template(
        client,
        owner_token,
        business_id,
        reward_type="percentage_discount",
        name="Ten Percent Off",
        gift_name=None,
        discount_percent=10,
    )
    assert percentage["reward_type"] == "percentage_discount"
    assert percentage["discount_percent"] == 10

    fixed = create_reward_template(
        client,
        owner_token,
        business_id,
        reward_type="fixed_discount",
        name="Five Euro Off",
        gift_name=None,
        discount_amount_minor=500,
        currency_code="eur",
    )
    assert fixed["reward_type"] == "fixed_discount"
    assert fixed["discount_amount_minor"] == 500
    assert fixed["currency_code"] == "EUR"


def test_owner_updates_and_deletes_unused_reward_template(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    template = create_reward_template(client, owner_token, business_id)

    update_response = client.patch(
        f"/api/v1/owner/reward-templates/{template['id']}?business_id={business_id}",
        json={"name": "Free Tea", "gift_name": "Free Tea", "valid_days": 45},
        headers=auth(owner_token),
    )
    assert update_response.status_code == 200
    assert update_response.json()["name"] == "Free Tea"
    assert update_response.json()["gift_name"] == "Free Tea"
    assert update_response.json()["valid_days"] == 45

    delete_response = client.delete(
        f"/api/v1/owner/reward-templates/{template['id']}?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert delete_response.status_code == 204

    list_response = client.get(
        f"/api/v1/owner/reward-templates?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert list_response.status_code == 200
    assert list_response.json() == []


def test_owner_cannot_update_or_delete_used_reward_template(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    template = create_reward_template(client, owner_token, business_id)
    create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        reward_template_id=template["id"],
    )

    update_response = client.patch(
        f"/api/v1/owner/reward-templates/{template['id']}?business_id={business_id}",
        json={"name": "Free Tea", "gift_name": "Free Tea", "valid_days": 45},
        headers=auth(owner_token),
    )
    assert update_response.status_code == 409
    assert update_response.json()["detail"] == "Reward template is already used"

    delete_response = client.delete(
        f"/api/v1/owner/reward-templates/{template['id']}?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert delete_response.status_code == 409
    assert delete_response.json()["detail"] == "Reward template is already used"


def test_owner_archives_used_reward_template_and_hides_it_from_active_lists(
    client: TestClient,
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    template = create_reward_template(client, owner_token, business_id)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        reward_template_id=template["id"],
    )

    list_response = client.get(
        f"/api/v1/owner/reward-templates?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert list_response.status_code == 200
    listed_template = next(item for item in list_response.json() if item["id"] == template["id"])
    assert listed_template["can_edit"] is False
    assert listed_template["can_delete"] is False
    assert listed_template["can_archive"] is False

    blocked_response = client.patch(
        f"/api/v1/owner/reward-templates/{template['id']}/active?business_id={business_id}",
        json={"is_active": False},
        headers=auth(owner_token),
    )
    assert blocked_response.status_code == 409
    assert blocked_response.json()["detail"] == "Reward template is used by an active campaign"

    end_response = client.patch(
        f"/api/v1/owner/campaigns/{campaign['id']}/status?business_id={business_id}",
        json={"status": "ended"},
        headers=auth(owner_token),
    )
    assert end_response.status_code == 200

    refreshed_response = client.get(
        f"/api/v1/owner/reward-templates?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert refreshed_response.status_code == 200
    refreshed_template = next(
        item for item in refreshed_response.json() if item["id"] == template["id"]
    )
    assert refreshed_template["can_archive"] is True

    archive_response = client.patch(
        f"/api/v1/owner/reward-templates/{template['id']}/active?business_id={business_id}",
        json={"is_active": False},
        headers=auth(owner_token),
    )
    assert archive_response.status_code == 200
    assert archive_response.json()["is_active"] is False

    hidden_response = client.get(
        f"/api/v1/owner/reward-templates?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert hidden_response.status_code == 200
    assert all(item["id"] != template["id"] for item in hidden_response.json())


def test_owner_cannot_create_campaign_with_foreign_reward_template(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    owner_mission = create_mission(client, owner_token, business_id, name="Owner Visit")
    other_template = create_reward_template(
        client,
        other_owner_token,
        other_business_id,
        name="Other Reward",
        gift_name="Other Gift",
    )

    response = client.post(
        "/api/v1/owner/campaigns",
        json={
            "creator_business_id": business_id,
            "reward_template_id": other_template["id"],
            "name": "Invalid Campaign",
            "threshold_points": 5,
            "starts_at": (datetime.now(UTC) - timedelta(days=1)).isoformat(),
            "ends_at": (datetime.now(UTC) + timedelta(days=30)).isoformat(),
            "mission_ids": [owner_mission["id"]],
        },
        headers=auth(owner_token),
    )

    assert response.status_code == 404


def test_campaign_completion_generates_reward_when_template_exists(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    customer_token, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=5)
    campaign = create_campaign(
        client,
        owner_token,
        business_id,
        mission_ids=[mission["id"]],
        threshold_points=5,
    )
    template = create_reward_template(client, owner_token, business_id, campaign["id"])

    action = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "reward-generation-1",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )

    assert action.status_code == 201
    reward = db_session.scalar(select(GeneratedReward))
    assert reward is not None
    assert str(reward.reward_template_id) == template["id"]
    assert reward.status.value == "active"
    assert reward.gift_name == "Free coffee"
    assert reward.issuer_business_id == reward.business_id
    assert reward.source_type.value == "individual_campaign_completion"

    completion = db_session.scalar(select(CampaignCompletion))
    assert completion is not None
    assert reward.source_id == completion.id
    assert completion.reward_generated_at is not None

    rewards_response = client.get(
        f"/api/v1/customers/me/rewards?business_id={business_id}",
        headers=auth(customer_token),
    )
    assert rewards_response.status_code == 200
    assert [item["id"] for item in rewards_response.json()] == [str(reward.id)]


def test_owner_cannot_create_campaign_without_reward_template(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)

    response = client.post(
        "/api/v1/owner/campaigns",
        json={
            "creator_business_id": business_id,
            "name": "Invalid Campaign",
            "threshold_points": 5,
            "starts_at": (datetime.now(UTC) - timedelta(days=1)).isoformat(),
            "ends_at": (datetime.now(UTC) + timedelta(days=30)).isoformat(),
            "mission_ids": [mission["id"]],
        },
        headers=auth(owner_token),
    )

    assert response.status_code == 422


def test_idempotency_replay_does_not_duplicate_generated_reward(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    payload = {
        "business_id": business_id,
        "customer_id": customer_id,
        "idempotency_key": "reward-idempotent-1",
        "items": [{"mission_id": mission["id"], "quantity": 1}],
    }

    first = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))
    second = client.post("/api/v1/staff/actions", json=payload, headers=auth(staff_token))

    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json()["idempotency_replayed"] is True
    assert db_session.query(GeneratedReward).count() == 1


def test_staff_uses_reward_without_creating_points_entry(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Buy Coffee", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "reward-use-source-action",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    reward = db_session.scalar(select(GeneratedReward))
    assert reward is not None
    points_before = db_session.query(PointsLedgerEntry).count()

    response = client.post(
        f"/api/v1/staff/rewards/{reward.id}/use",
        json={
            "business_id": business_id,
            "idempotency_key": "use-reward-1",
            "note": "Used at checkout",
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["idempotency_replayed"] is False
    assert body["reward"]["status"] == "used"
    assert body["usage"]["redeemed_business_id"] == business_id
    assert body["usage"]["issuer_business_id"] == business_id
    assert body["usage"]["settlement_status"] == "not_required"
    assert db_session.query(RewardUsage).count() == 1
    assert db_session.query(PointsLedgerEntry).count() == points_before

    action = db_session.scalar(
        select(LoyaltyAction).where(LoyaltyAction.id == UUID(body["usage"]["action_id"]))
    )
    assert action is not None
    assert action.action_type.value == "reward_use"
    assert action.items == []


def test_reward_use_idempotency_replay_returns_existing_usage(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "reward-use-replay-source",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    rewards = client.get(
        f"/api/v1/customers/me/rewards?business_id={business_id}",
        headers=auth(login(client, "customer@example.com")),
    )
    reward_id = rewards.json()[0]["id"]
    payload = {"business_id": business_id, "idempotency_key": "use-reward-replay"}

    first = client.post(
        f"/api/v1/staff/rewards/{reward_id}/use", json=payload, headers=auth(staff_token)
    )
    second = client.post(
        f"/api/v1/staff/rewards/{reward_id}/use", json=payload, headers=auth(staff_token)
    )

    assert first.status_code == 200
    assert second.status_code == 200
    assert second.json()["idempotency_replayed"] is True
    assert second.json()["usage"]["id"] == first.json()["usage"]["id"]


def test_staff_cannot_use_reward_from_another_business(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    other_staff_token, _ = create_staff(
        client, other_owner_token, other_business_id, "other-staff@example.com"
    )
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "foreign-use-source",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    reward = db_session.scalar(select(GeneratedReward))
    assert reward is not None

    response = client.post(
        f"/api/v1/staff/rewards/{reward.id}/use",
        json={"business_id": other_business_id, "idempotency_key": "foreign-use-1"},
        headers=auth(other_staff_token),
    )

    assert response.status_code == 403


def test_used_reward_cannot_be_used_twice_with_new_idempotency_key(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "used-twice-source",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    reward = db_session.scalar(select(GeneratedReward))
    assert reward is not None

    first = client.post(
        f"/api/v1/staff/rewards/{reward.id}/use",
        json={"business_id": business_id, "idempotency_key": "used-once"},
        headers=auth(staff_token),
    )
    second = client.post(
        f"/api/v1/staff/rewards/{reward.id}/use",
        json={"business_id": business_id, "idempotency_key": "used-twice"},
        headers=auth(staff_token),
    )

    assert first.status_code == 200
    assert second.status_code == 400


def test_staff_cannot_use_expired_reward(client: TestClient, db_session: Session) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )
    create_reward_template(client, owner_token, business_id, campaign["id"])
    client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "expired-source",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )
    reward = db_session.scalar(select(GeneratedReward))
    assert reward is not None
    reward.expires_at = datetime.now(UTC) - timedelta(days=1)
    db_session.flush()

    response = client.post(
        f"/api/v1/staff/rewards/{reward.id}/use",
        json={"business_id": business_id, "idempotency_key": "expired-use"},
        headers=auth(staff_token),
    )

    assert response.status_code == 400
    db_session.refresh(reward)
    assert reward.status.value == "expired"
