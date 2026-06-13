from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.loyalty.models import (
    AuditEvent,
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


def create_staff(
    client: TestClient, owner_token: str, business_id: str, email: str
) -> tuple[str, str]:
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


def create_campaign(
    client: TestClient,
    owner_token: str,
    business_id: str,
    *,
    mission_ids: list[str],
    threshold_points: int = 5,
    starts_at: datetime | None = None,
    ends_at: datetime | None = None,
) -> dict:
    starts_at = starts_at or datetime.now(UTC) - timedelta(days=1)
    ends_at = ends_at or datetime.now(UTC) + timedelta(days=30)
    response = client.post(
        "/api/v1/owner/campaigns",
        json={
            "creator_business_id": business_id,
            "name": "Coffee Lover",
            "description": "Reach the threshold",
            "threshold_points": threshold_points,
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
    campaign_id: str,
    *,
    reward_type: str = "gift",
    name: str = "Free Coffee",
    gift_name: str | None = "Free coffee",
    discount_percent: int | None = None,
    discount_amount_minor: int | None = None,
    currency_code: str | None = None,
    valid_days: int = 30,
) -> dict:
    payload = {
        "business_id": business_id,
        "campaign_id": campaign_id,
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
    assert body[0]["staff_name"] == "Staff"
    assert body[0]["staff_email"] == "staff@example.com"
    assert body[0]["customer_name"] == "Customer"
    assert body[0]["customer_email"] == "customer@example.com"
    assert body[0]["points_granted"] == 7
    assert body[0]["summary"] == "Buy Coffee x2, Buy Cake x1"
    assert body[0]["created_at"] is not None


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


def test_customer_reads_active_reward_status(client: TestClient) -> None:
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
    assert body["businesses"][0]["rewards"][0]["status"] == "active"


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

    response = client.get(
        f"/api/v1/owner/campaigns?business_id={business_id}",
        headers=auth(owner_token),
    )
    assert response.status_code == 200
    assert [item["id"] for item in response.json()] == [campaign["id"]]


def test_owner_cannot_create_campaign_with_foreign_mission(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    foreign_mission = create_mission(
        client, other_owner_token, other_business_id, name="Foreign Mission"
    )

    response = client.post(
        "/api/v1/owner/campaigns",
        json={
            "creator_business_id": business_id,
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
    assert progress.json()["progress_points"] == 2
    assert progress.json()["is_completed"] is False

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
            "progress_points": 2,
            "threshold_points": 5,
            "remaining_points": 3,
            "is_completed": False,
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
    assert completion.reward_generated_at is None

    progress = client.get(
        f"/api/v1/customers/me/campaigns/{campaign['id']}/progress",
        headers=auth(customer_token),
    )
    assert progress.status_code == 200
    assert progress.json()["progress_points"] == 5
    assert progress.json()["is_completed"] is True

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


def test_owner_creates_reward_templates_for_all_mvp_types(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    first_mission = create_mission(client, owner_token, business_id, name="Buy Coffee")
    first_campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[first_mission["id"]]
    )
    gift = create_reward_template(
        client,
        owner_token,
        business_id,
        first_campaign["id"],
        reward_type="gift",
        gift_name="Free coffee",
    )
    assert gift["reward_type"] == "gift"
    assert gift["issuer_business_id"] == business_id
    assert gift["redeem_scope"] == "issuer_business_only"
    assert gift["settlement_policy"] == "issuer_pays"

    second_mission = create_mission(client, owner_token, business_id, name="Buy Cake")
    second_campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[second_mission["id"]]
    )
    percentage = create_reward_template(
        client,
        owner_token,
        business_id,
        second_campaign["id"],
        reward_type="percentage_discount",
        name="Ten Percent Off",
        gift_name=None,
        discount_percent=10,
    )
    assert percentage["reward_type"] == "percentage_discount"
    assert percentage["discount_percent"] == 10

    third_mission = create_mission(client, owner_token, business_id, name="Visit")
    third_campaign = create_campaign(
        client, owner_token, business_id, mission_ids=[third_mission["id"]]
    )
    fixed = create_reward_template(
        client,
        owner_token,
        business_id,
        third_campaign["id"],
        reward_type="fixed_discount",
        name="Five Euro Off",
        gift_name=None,
        discount_amount_minor=500,
        currency_code="eur",
    )
    assert fixed["reward_type"] == "fixed_discount"
    assert fixed["discount_amount_minor"] == 500
    assert fixed["currency_code"] == "EUR"


def test_owner_cannot_create_reward_template_for_foreign_campaign(client: TestClient) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com", "Owner Cafe")
    other_owner_token, other_business_id = register_owner(client, "other@example.com", "Other Cafe")
    other_mission = create_mission(client, other_owner_token, other_business_id, name="Other Visit")
    other_campaign = create_campaign(
        client, other_owner_token, other_business_id, mission_ids=[other_mission["id"]]
    )

    response = client.post(
        "/api/v1/owner/reward-templates",
        json={
            "business_id": business_id,
            "campaign_id": other_campaign["id"],
            "name": "Invalid Reward",
            "reward_type": "gift",
            "gift_name": "Nope",
            "valid_days": 30,
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


def test_campaign_completion_without_template_does_not_generate_reward(
    client: TestClient, db_session: Session
) -> None:
    owner_token, business_id = register_owner(client, "owner@example.com")
    staff_token, _ = create_staff(client, owner_token, business_id, "staff@example.com")
    _, customer_id = register_customer(client)
    mission = create_mission(client, owner_token, business_id, name="Visit", point_value=5)
    create_campaign(
        client, owner_token, business_id, mission_ids=[mission["id"]], threshold_points=5
    )

    response = client.post(
        "/api/v1/staff/actions",
        json={
            "business_id": business_id,
            "customer_id": customer_id,
            "idempotency_key": "completion-no-template",
            "items": [{"mission_id": mission["id"], "quantity": 1}],
        },
        headers=auth(staff_token),
    )

    assert response.status_code == 201
    assert db_session.query(CampaignCompletion).count() == 1
    assert db_session.query(GeneratedReward).count() == 0


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
