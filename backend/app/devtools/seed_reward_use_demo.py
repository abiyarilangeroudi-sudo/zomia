import hashlib
import secrets
from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.modules.identity.models import Business, BusinessStatus, StaffMember, User, UserRole
from app.modules.loyalty.models import (
    Campaign,
    CampaignCompletion,
    CampaignMission,
    CampaignParticipationMode,
    CampaignProgressMetric,
    CampaignScopeType,
    CampaignStatus,
    CampaignType,
    GeneratedReward,
    Mission,
    MissionType,
    RewardGenerationSourceType,
    RewardRedeemScope,
    RewardSettlementPolicy,
    RewardStatus,
    RewardTemplate,
    RewardType,
)
from app.modules.qr.models import CustomerQrToken, CustomerQrTokenStatus

PASSWORD = "strong-password"


def main() -> None:
    with SessionLocal() as db:
        result = seed_reward_use_demo(db)
        db.commit()

    print("Reward-use QA data created.")
    print(f"Staff email: {result['staff_email']}")
    print(f"Customer email: {result['customer_email']}")
    print(f"Password: {PASSWORD}")
    print(f"Business: {result['business_name']}")
    print(f"QR token: {result['qr_token']}")
    print(f"QR payload: {result['qr_payload']}")
    print(f"Reward: {result['reward_title']}")


def seed_reward_use_demo(db: Session) -> dict[str, str]:
    now = datetime.now(UTC)
    suffix = now.strftime("%Y%m%d%H%M%S")

    owner = User(
        email=f"owner-reward-qa-{suffix}@example.com",
        password_hash=hash_password(PASSWORD),
        full_name="Reward QA Owner",
        role=UserRole.OWNER,
        is_active=True,
    )
    staff = User(
        email=f"staff-reward-qa-{suffix}@example.com",
        password_hash=hash_password(PASSWORD),
        full_name="Reward QA Staff",
        role=UserRole.STAFF,
        is_active=True,
    )
    customer = User(
        email=f"customer-reward-qa-{suffix}@example.com",
        password_hash=hash_password(PASSWORD),
        full_name="Reward QA Customer",
        role=UserRole.CUSTOMER,
        is_active=True,
    )
    db.add_all([owner, staff, customer])
    db.flush()

    business = Business(
        owner_id=owner.id,
        name=f"Reward QA Cafe {suffix}",
        slug=f"reward-qa-cafe-{suffix}",
        country_code="DE",
        timezone="Europe/Berlin",
        currency_code="EUR",
        status=BusinessStatus.ACTIVE,
    )
    db.add(business)
    db.flush()

    db.add(StaffMember(business_id=business.id, user_id=staff.id, is_active=True))

    mission = Mission(
        business_id=business.id,
        name="Reward QA Visit",
        description="Mission for manual reward-use QA",
        mission_type=MissionType.VISIT,
        point_value=1,
        is_active=True,
    )
    db.add(mission)
    db.flush()

    campaign = Campaign(
        creator_business_id=business.id,
        name="Reward QA Campaign",
        description="Campaign for manual reward-use QA",
        campaign_type=CampaignType.INDIVIDUAL,
        scope_type=CampaignScopeType.SINGLE_BUSINESS,
        participation_mode=CampaignParticipationMode.AUTOMATIC,
        progress_metric=CampaignProgressMetric.POINTS,
        threshold_points=1,
        is_repeatable=False,
        max_completions_per_customer=1,
        status=CampaignStatus.ACTIVE,
        starts_at=now - timedelta(days=1),
        ends_at=now + timedelta(days=30),
    )
    db.add(campaign)
    db.flush()

    db.add(CampaignMission(campaign_id=campaign.id, mission_id=mission.id))

    completion = CampaignCompletion(
        campaign_id=campaign.id,
        customer_id=customer.id,
        progress_points=1,
        threshold_points=1,
        completion_number=1,
        completed_at=now,
        reward_generated_at=now,
    )
    db.add(completion)
    db.flush()

    template = RewardTemplate(
        business_id=business.id,
        issuer_business_id=business.id,
        campaign_id=campaign.id,
        name="Reward QA Free Coffee",
        description="Free coffee reward for manual QA",
        reward_type=RewardType.GIFT,
        redeem_scope=RewardRedeemScope.ISSUER_BUSINESS_ONLY,
        settlement_policy=RewardSettlementPolicy.ISSUER_PAYS,
        gift_name="Free coffee",
        valid_days=30,
        is_active=True,
    )
    db.add(template)
    db.flush()

    reward = GeneratedReward(
        reward_template_id=template.id,
        campaign_id=campaign.id,
        campaign_completion_id=completion.id,
        source_type=RewardGenerationSourceType.INDIVIDUAL_CAMPAIGN_COMPLETION,
        source_id=completion.id,
        business_id=business.id,
        issuer_business_id=business.id,
        customer_id=customer.id,
        reward_type=RewardType.GIFT,
        redeem_scope=RewardRedeemScope.ISSUER_BUSINESS_ONLY,
        settlement_policy=RewardSettlementPolicy.ISSUER_PAYS,
        title=template.name,
        description=template.description,
        status=RewardStatus.ACTIVE,
        gift_name=template.gift_name,
        issued_at=now,
        expires_at=now + timedelta(days=template.valid_days),
    )
    db.add(reward)

    raw_qr_token = secrets.token_urlsafe(32)
    db.add(
        CustomerQrToken(
            customer_id=customer.id,
            token_hash=_hash_token(raw_qr_token),
            status=CustomerQrTokenStatus.ACTIVE,
            expires_at=now + timedelta(days=90),
        )
    )

    return {
        "staff_email": staff.email,
        "customer_email": customer.email,
        "business_name": business.name,
        "qr_token": raw_qr_token,
        "qr_payload": f"zomia://customer/{raw_qr_token}",
        "reward_title": reward.title,
    }


def _hash_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


if __name__ == "__main__":
    main()
