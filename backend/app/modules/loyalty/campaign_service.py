from collections.abc import Callable
from datetime import UTC, datetime

from fastapi import HTTPException, status

from app.modules.identity.models import User, UserRole
from app.modules.loyalty.models import (
    AuditEventType,
    Campaign,
    CampaignCompletion,
    CampaignMission,
    CampaignRewardTemplate,
    CampaignParticipationMode,
    CampaignProgressMetric,
    CampaignScopeType,
    CampaignStatus,
    CampaignType,
    LoyaltyAction,
    LoyaltyActionItem,
)
from app.modules.loyalty.repository import LoyaltyRepository
from app.modules.loyalty.schemas import (
    CampaignCreate,
    CampaignProgressRead,
    CampaignStatusUpdate,
    CustomerCampaignProgressRead,
)

AuditRecorder = Callable[..., None]


class CampaignService:
    def __init__(self, repository: LoyaltyRepository, audit: AuditRecorder) -> None:
        self.repository = repository
        self._audit = audit

    def create_campaign(self, owner: User, payload: CampaignCreate) -> Campaign:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=payload.creator_business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

        mission_ids = set(payload.mission_ids)
        missions = self.repository.get_active_missions_by_ids(
            business_id=payload.creator_business_id, mission_ids=mission_ids
        )
        if mission_ids - set(missions):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="One or more missions were not found",
            )
        reward_template = self.repository.get_active_reward_template_for_business(
            reward_template_id=payload.reward_template_id,
            business_id=payload.creator_business_id,
        )
        if reward_template is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reward template not found",
            )

        campaign = self.repository.add_campaign(
            Campaign(
                creator_business_id=payload.creator_business_id,
                name=payload.name,
                description=payload.description,
                campaign_type=CampaignType.INDIVIDUAL,
                scope_type=CampaignScopeType.SINGLE_BUSINESS,
                participation_mode=CampaignParticipationMode.AUTOMATIC,
                progress_metric=CampaignProgressMetric.POINTS,
                threshold_points=payload.threshold_points,
                is_repeatable=payload.is_repeatable,
                max_completions_per_customer=payload.max_completions_per_customer,
                status=CampaignStatus.ACTIVE,
                starts_at=payload.starts_at,
                ends_at=payload.ends_at,
            )
        )
        for mission_id in mission_ids:
            self.repository.add_campaign_mission(
                CampaignMission(campaign_id=campaign.id, mission_id=mission_id)
            )
        self.repository.add_campaign_reward_template(
            CampaignRewardTemplate(
                campaign_id=campaign.id,
                reward_template_id=payload.reward_template_id,
            )
        )

        self._audit(
            event_type=AuditEventType.CAMPAIGN_CREATED,
            actor_user_id=owner.id,
            business_id=payload.creator_business_id,
            entity_type="campaign",
            entity_id=campaign.id,
            metadata={
                "threshold_points": payload.threshold_points,
                "is_repeatable": payload.is_repeatable,
                "max_completions_per_customer": payload.max_completions_per_customer,
                "mission_ids": [str(mission_id) for mission_id in mission_ids],
                "reward_template_id": str(payload.reward_template_id),
            },
        )
        return campaign

    def list_campaigns(self, owner: User, business_id) -> list[Campaign]:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(business_id=business_id, owner_id=owner.id)
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        return self.repository.list_business_campaigns(business_id)

    def update_campaign_status(
        self, owner: User, *, business_id, campaign_id, payload: CampaignStatusUpdate
    ) -> Campaign:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(business_id=business_id, owner_id=owner.id)
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        campaign = self.repository.get_campaign_for_business(
            campaign_id=campaign_id, business_id=business_id
        )
        if campaign is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Campaign not found")
        if campaign.status == CampaignStatus.ENDED:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Campaign is already ended",
            )
        if payload.status != CampaignStatus.ENDED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported campaign status",
            )
        campaign.status = payload.status
        return campaign

    def get_campaign_progress(self, customer: User, campaign_id) -> CampaignProgressRead:
        self._require_role(customer, UserRole.CUSTOMER)
        campaign = self.repository.get_campaign(campaign_id)
        if campaign is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Campaign not found")
        progress_points = self.repository.sum_campaign_points(
            campaign=campaign, customer_id=customer.id
        )
        progress = self._campaign_cycle_progress(campaign, progress_points, customer.id)
        progress_status = self._campaign_progress_status(campaign, progress, datetime.now(UTC))
        return CampaignProgressRead(
            campaign_id=campaign.id,
            customer_id=customer.id,
            starts_at=campaign.starts_at,
            ends_at=campaign.ends_at,
            progress_points=progress["progress_points"],
            threshold_points=campaign.threshold_points,
            remaining_points=progress["remaining_points"],
            is_completed=progress_status["progress_state"] in {"completed", "limit_reached"},
            is_repeatable=campaign.is_repeatable,
            completed_cycles=progress["completed_cycles"],
            current_cycle_number=progress["current_cycle_number"],
            max_completions_per_customer=campaign.max_completions_per_customer,
            campaign_time_status=progress_status["campaign_time_status"],
            progress_state=progress_status["progress_state"],
            display_label=progress_status["display_label"],
            badge_label=progress_status["badge_label"],
            badge_tone=progress_status["badge_tone"],
        )

    def list_customer_campaign_progresses(
        self, customer: User
    ) -> list[CustomerCampaignProgressRead]:
        self._require_role(customer, UserRole.CUSTOMER)
        business_ids = self.repository.list_customer_point_business_ids(
            customer.id
        ) | self.repository.list_customer_reward_business_ids(customer.id)
        businesses = {
            business.id: business
            for business in self.repository.list_businesses_by_ids(business_ids)
        }
        now = datetime.now(UTC)
        campaigns = self.repository.list_individual_campaigns_for_businesses(
            business_ids=business_ids
        )

        progress_reads: list[CustomerCampaignProgressRead] = []
        for campaign in campaigns:
            business = businesses.get(campaign.creator_business_id)
            if business is None:
                continue
            progress_points = self.repository.sum_campaign_points(
                campaign=campaign,
                customer_id=customer.id,
            )
            progress = self._campaign_cycle_progress(campaign, progress_points, customer.id)
            if progress_points <= 0 and not progress["is_completed"]:
                continue
            progress_status = self._campaign_progress_status(campaign, progress, now)
            progress_reads.append(
                CustomerCampaignProgressRead(
                    business_id=business.id,
                    business_name=business.name,
                    campaign_id=campaign.id,
                    campaign_name=campaign.name,
                    starts_at=campaign.starts_at,
                    ends_at=campaign.ends_at,
                    progress_points=progress["progress_points"],
                    threshold_points=campaign.threshold_points,
                    remaining_points=progress["remaining_points"],
                    is_completed=progress_status["progress_state"]
                    in {"completed", "limit_reached"},
                    is_repeatable=campaign.is_repeatable,
                    completed_cycles=progress["completed_cycles"],
                    current_cycle_number=progress["current_cycle_number"],
                    max_completions_per_customer=campaign.max_completions_per_customer,
                    campaign_time_status=progress_status["campaign_time_status"],
                    progress_state=progress_status["progress_state"],
                    display_label=progress_status["display_label"],
                    badge_label=progress_status["badge_label"],
                    badge_tone=progress_status["badge_tone"],
                )
            )
        return progress_reads

    def evaluate_action(
        self,
        *,
        action: LoyaltyAction,
        action_items: list[LoyaltyActionItem],
        actor_user_id,
    ) -> list[CampaignCompletion]:
        created_completions: list[CampaignCompletion] = []
        mission_ids = {item.mission_id for item in action_items}
        campaigns = self.repository.get_active_individual_campaigns_for_action(
            business_id=action.business_id,
            mission_ids=mission_ids,
            occurred_at=action.occurred_at,
        )
        for campaign in campaigns:
            progress_points = self.repository.sum_campaign_points(
                campaign=campaign, customer_id=action.customer_id
            )
            earned_completions = progress_points // campaign.threshold_points
            if not campaign.is_repeatable:
                earned_completions = min(earned_completions, 1)
            elif campaign.max_completions_per_customer is not None:
                earned_completions = min(earned_completions, campaign.max_completions_per_customer)
            if earned_completions <= 0:
                continue

            completed_count = self.repository.count_campaign_completions(
                campaign_id=campaign.id, customer_id=action.customer_id
            )
            for completion_number in range(completed_count + 1, earned_completions + 1):
                completion = self.repository.add_campaign_completion(
                    CampaignCompletion(
                        campaign_id=campaign.id,
                        customer_id=action.customer_id,
                        progress_points=campaign.threshold_points * completion_number,
                        threshold_points=campaign.threshold_points,
                        completion_number=completion_number,
                        completed_at=datetime.now(UTC),
                    )
                )
                created_completions.append(completion)
                self._audit(
                    event_type=AuditEventType.CAMPAIGN_COMPLETED,
                    actor_user_id=actor_user_id,
                    business_id=campaign.creator_business_id,
                    entity_type="campaign_completion",
                    entity_id=completion.id,
                    metadata={
                        "campaign_id": str(campaign.id),
                        "customer_id": str(action.customer_id),
                        "progress_points": progress_points,
                        "threshold_points": campaign.threshold_points,
                        "completion_number": completion_number,
                    },
                )
        return created_completions

    def _campaign_cycle_progress(
        self, campaign: Campaign, total_points: int, customer_id
    ) -> dict[str, int | bool]:
        completed_cycles = self.repository.count_campaign_completions(
            campaign_id=campaign.id, customer_id=customer_id
        )
        if not campaign.is_repeatable:
            progress_points = min(total_points, campaign.threshold_points)
            return {
                "progress_points": progress_points,
                "remaining_points": max(campaign.threshold_points - progress_points, 0),
                "is_completed": completed_cycles > 0,
                "completed_cycles": completed_cycles,
                "current_cycle_number": 1,
            }

        max_cycles = campaign.max_completions_per_customer
        has_reached_limit = max_cycles is not None and completed_cycles >= max_cycles
        if has_reached_limit:
            return {
                "progress_points": campaign.threshold_points,
                "remaining_points": 0,
                "is_completed": True,
                "completed_cycles": completed_cycles,
                "current_cycle_number": completed_cycles,
            }

        current_cycle_number = completed_cycles + 1
        progress_points = total_points - (completed_cycles * campaign.threshold_points)
        progress_points = max(0, min(progress_points, campaign.threshold_points))
        return {
            "progress_points": progress_points,
            "remaining_points": max(campaign.threshold_points - progress_points, 0),
            "is_completed": completed_cycles > 0,
            "completed_cycles": completed_cycles,
            "current_cycle_number": current_cycle_number,
        }

    def _campaign_progress_status(
        self, campaign: Campaign, progress: dict[str, int | bool], now: datetime
    ) -> dict[str, str]:
        time_status = self._campaign_time_status(campaign, now)
        progress_points = int(progress["progress_points"])
        remaining_points = int(progress["remaining_points"])
        threshold_points = campaign.threshold_points
        completed_cycles = int(progress["completed_cycles"])
        current_cycle_number = int(progress["current_cycle_number"])

        if time_status == "upcoming":
            return {
                "campaign_time_status": "upcoming",
                "progress_state": "in_progress",
                "display_label": self._display_label(
                    campaign=campaign,
                    current_cycle_number=current_cycle_number,
                    progress_points=progress_points,
                    threshold_points=threshold_points,
                    suffix="Upcoming",
                ),
                "badge_label": "Upcoming",
                "badge_tone": "warning",
            }

        if time_status == "ended":
            return {
                "campaign_time_status": "ended",
                "progress_state": "ended",
                "display_label": self._display_label(
                    campaign=campaign,
                    current_cycle_number=current_cycle_number,
                    progress_points=progress_points,
                    threshold_points=threshold_points,
                    suffix="Ended",
                ),
                "badge_label": "Ended",
                "badge_tone": "neutral",
            }

        if not campaign.is_repeatable and completed_cycles > 0:
            return {
                "campaign_time_status": "active",
                "progress_state": "completed",
                "display_label": self._display_label(
                    campaign=campaign,
                    current_cycle_number=current_cycle_number,
                    progress_points=progress_points,
                    threshold_points=threshold_points,
                    suffix="Completed",
                ),
                "badge_label": "Completed",
                "badge_tone": "success",
            }

        has_reached_limit = (
            campaign.is_repeatable
            and campaign.max_completions_per_customer is not None
            and completed_cycles >= campaign.max_completions_per_customer
        )
        if has_reached_limit:
            return {
                "campaign_time_status": "active",
                "progress_state": "limit_reached",
                "display_label": self._display_label(
                    campaign=campaign,
                    current_cycle_number=current_cycle_number,
                    progress_points=progress_points,
                    threshold_points=threshold_points,
                    suffix="Limit reached",
                ),
                "badge_label": "Limit reached",
                "badge_tone": "success",
            }

        suffix = f"{remaining_points} pts to reward"
        return {
            "campaign_time_status": "active",
            "progress_state": "in_progress",
            "display_label": self._display_label(
                campaign=campaign,
                current_cycle_number=current_cycle_number,
                progress_points=progress_points,
                threshold_points=threshold_points,
                suffix=suffix,
            ),
            "badge_label": "Active",
            "badge_tone": "info",
        }

    def _campaign_time_status(self, campaign: Campaign, now: datetime) -> str:
        if campaign.status == CampaignStatus.ENDED:
            return "ended"
        starts_at = self._as_utc(campaign.starts_at)
        ends_at = self._as_utc(campaign.ends_at)
        if now < starts_at:
            return "upcoming"
        if now > ends_at:
            return "ended"
        return "active"

    @staticmethod
    def _display_label(
        *,
        campaign: Campaign,
        current_cycle_number: int,
        progress_points: int,
        threshold_points: int,
        suffix: str,
    ) -> str:
        cycle_prefix = f"Cycle {current_cycle_number} · " if campaign.is_repeatable else ""
        return f"{cycle_prefix}{progress_points}/{threshold_points} pts · {suffix}"

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _require_role(user: User, role: UserRole) -> None:
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
