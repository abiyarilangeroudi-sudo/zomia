from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status

from app.modules.identity.models import User, UserRole
from app.modules.loyalty.models import (
    AuditEvent,
    AuditEventType,
    Campaign,
    CampaignCompletion,
    CampaignMission,
    CampaignParticipationMode,
    CampaignProgressMetric,
    CampaignScopeType,
    CampaignStatus,
    CampaignType,
    GeneratedReward,
    LoyaltyAction,
    LoyaltyActionItem,
    LoyaltyActionType,
    Mission,
    PointsLedgerEntry,
    RewardRedeemScope,
    RewardGenerationSourceType,
    RewardSettlementPolicy,
    RewardSettlementStatus,
    RewardStatus,
    RewardTemplate,
    RewardUsage,
)
from app.modules.loyalty.repository import LoyaltyRepository
from app.modules.loyalty.schemas import (
    CampaignCreate,
    CampaignProgressRead,
    CustomerPointsRead,
    CustomerBusinessStatusRead,
    CustomerStatusRead,
    GeneratedRewardRead,
    MissionCreate,
    RegisterActionRequest,
    RegisterActionResponse,
    RewardTemplateCreate,
    UseRewardRequest,
    UseRewardResponse,
)


class LoyaltyService:
    def __init__(self, repository: LoyaltyRepository) -> None:
        self.repository = repository

    def create_mission(self, owner: User, payload: MissionCreate) -> Mission:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=payload.business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

        mission = Mission(
            business_id=payload.business_id,
            name=payload.name,
            description=payload.description,
            mission_type=payload.mission_type,
            point_value=payload.point_value,
        )
        self.repository.add_mission(mission)
        self._audit(
            event_type=AuditEventType.MISSION_CREATED,
            actor_user_id=owner.id,
            business_id=payload.business_id,
            entity_type="mission",
            entity_id=mission.id,
            metadata={"mission_type": payload.mission_type.value, "point_value": payload.point_value},
        )
        return mission

    def list_missions(self, owner: User, business_id) -> list[Mission]:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(business_id=business_id, owner_id=owner.id)
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        return self.repository.list_business_missions(business_id)

    def list_staff_missions(self, staff: User, business_id) -> list[Mission]:
        self._require_role(staff, UserRole.STAFF)
        if self.repository.get_staff_membership(
            business_id=business_id, staff_user_id=staff.id
        ) is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Staff does not belong to this business",
            )
        return self.repository.list_business_missions(business_id)

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
                is_repeatable=False,
                max_completions_per_customer=1,
                status=CampaignStatus.ACTIVE,
                starts_at=payload.starts_at,
                ends_at=payload.ends_at,
            )
        )
        for mission_id in mission_ids:
            self.repository.add_campaign_mission(
                CampaignMission(campaign_id=campaign.id, mission_id=mission_id)
            )

        self._audit(
            event_type=AuditEventType.CAMPAIGN_CREATED,
            actor_user_id=owner.id,
            business_id=payload.creator_business_id,
            entity_type="campaign",
            entity_id=campaign.id,
            metadata={
                "threshold_points": payload.threshold_points,
                "mission_ids": [str(mission_id) for mission_id in mission_ids],
            },
        )
        return campaign

    def list_campaigns(self, owner: User, business_id) -> list[Campaign]:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(business_id=business_id, owner_id=owner.id)
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        return self.repository.list_business_campaigns(business_id)

    def create_reward_template(self, owner: User, payload: RewardTemplateCreate) -> RewardTemplate:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(
            business_id=payload.business_id, owner_id=owner.id
        )
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

        campaign = self.repository.get_campaign_for_business(
            campaign_id=payload.campaign_id, business_id=payload.business_id
        )
        if campaign is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Campaign not found")

        template = self.repository.add_reward_template(
            RewardTemplate(
                business_id=payload.business_id,
                issuer_business_id=payload.business_id,
                campaign_id=payload.campaign_id,
                name=payload.name,
                description=payload.description,
                reward_type=payload.reward_type,
                redeem_scope=RewardRedeemScope.ISSUER_BUSINESS_ONLY,
                settlement_policy=RewardSettlementPolicy.ISSUER_PAYS,
                gift_name=payload.gift_name,
                discount_percent=payload.discount_percent,
                discount_amount_minor=payload.discount_amount_minor,
                currency_code=payload.currency_code,
                valid_days=payload.valid_days,
                is_active=True,
            )
        )
        self._audit(
            event_type=AuditEventType.REWARD_TEMPLATE_CREATED,
            actor_user_id=owner.id,
            business_id=payload.business_id,
            entity_type="reward_template",
            entity_id=template.id,
            metadata={
                "campaign_id": str(payload.campaign_id),
                "reward_type": payload.reward_type.value,
                "redeem_scope": RewardRedeemScope.ISSUER_BUSINESS_ONLY.value,
                "settlement_policy": RewardSettlementPolicy.ISSUER_PAYS.value,
            },
        )
        return template

    def list_reward_templates(self, owner: User, business_id) -> list[RewardTemplate]:
        self._require_role(owner, UserRole.OWNER)
        business = self.repository.get_owner_business(business_id=business_id, owner_id=owner.id)
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        return self.repository.list_reward_templates(business_id)

    def register_action(
        self, staff: User, payload: RegisterActionRequest
    ) -> RegisterActionResponse:
        self._require_role(staff, UserRole.STAFF)
        if self.repository.get_staff_membership(
            business_id=payload.business_id, staff_user_id=staff.id
        ) is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Staff does not belong to this business",
            )

        existing_action = self.repository.get_action_by_idempotency_key(
            business_id=payload.business_id, idempotency_key=payload.idempotency_key
        )
        if existing_action is not None:
            self._audit(
                event_type=AuditEventType.IDEMPOTENCY_REPLAYED,
                actor_user_id=staff.id,
                business_id=payload.business_id,
                entity_type="loyalty_action",
                entity_id=existing_action.id,
                metadata={"idempotency_key": payload.idempotency_key},
            )
            return self._action_response(existing_action, idempotency_replayed=True)

        customer = self.repository.get_user(payload.customer_id)
        if not self.repository.is_customer(customer):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

        mission_ids = {item.mission_id for item in payload.items}
        missions = self.repository.get_active_missions_by_ids(
            business_id=payload.business_id, mission_ids=mission_ids
        )
        missing_missions = mission_ids - set(missions)
        if missing_missions:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="One or more missions were not found",
            )

        action = self.repository.add_action(
            LoyaltyAction(
                business_id=payload.business_id,
                customer_id=payload.customer_id,
                staff_id=staff.id,
                action_type=LoyaltyActionType.MISSION_PROGRESS,
                idempotency_key=payload.idempotency_key,
                occurred_at=payload.occurred_at or datetime.now(UTC),
                note=payload.note,
            )
        )

        created_items: list[LoyaltyActionItem] = []
        for item_payload in payload.items:
            mission = missions[item_payload.mission_id]
            total_points = item_payload.quantity * mission.point_value
            action_item = self.repository.add_action_item(
                LoyaltyActionItem(
                    action_id=action.id,
                    mission_id=mission.id,
                    quantity=item_payload.quantity,
                    unit_points=mission.point_value,
                    total_points=total_points,
                )
            )
            created_items.append(action_item)
            self.repository.add_points_entry(
                PointsLedgerEntry(
                    business_id=payload.business_id,
                    customer_id=payload.customer_id,
                    action_id=action.id,
                    action_item_id=action_item.id,
                    points=total_points,
                    reason="mission_action",
                )
            )

        points_granted = sum(item.total_points for item in created_items)
        self._audit(
            event_type=AuditEventType.ACTION_RECORDED,
            actor_user_id=staff.id,
            business_id=payload.business_id,
            entity_type="loyalty_action",
            entity_id=action.id,
            metadata={
                "customer_id": str(payload.customer_id),
                "items_count": len(created_items),
                "points_granted": points_granted,
            },
        )
        self._audit(
            event_type=AuditEventType.POINTS_GRANTED,
            actor_user_id=staff.id,
            business_id=payload.business_id,
            entity_type="loyalty_action",
            entity_id=action.id,
            metadata={"customer_id": str(payload.customer_id), "points_granted": points_granted},
        )
        self._evaluate_campaigns_for_action(
            action=action,
            action_items=created_items,
            actor_user_id=staff.id,
        )
        return self._action_response(
            action, idempotency_replayed=False, items=created_items
        )

    def get_customer_points(self, customer: User, business_id) -> CustomerPointsRead:
        self._require_role(customer, UserRole.CUSTOMER)
        points = self.repository.sum_customer_points(
            business_id=business_id, customer_id=customer.id
        )
        return CustomerPointsRead(business_id=business_id, customer_id=customer.id, points=points)

    def get_customer_status(self, customer: User) -> CustomerStatusRead:
        self._require_role(customer, UserRole.CUSTOMER)
        business_ids = self.repository.list_customer_reward_business_ids(customer.id)
        businesses = self.repository.list_businesses_by_ids(business_ids)
        now = datetime.now(UTC)

        business_statuses: list[CustomerBusinessStatusRead] = []
        active_rewards_count = 0
        for business in businesses:
            rewards = [
                self._reward_read(self._expire_if_needed(reward, now))
                for reward in self.repository.list_customer_rewards(
                    business_id=business.id, customer_id=customer.id
                )
            ]
            active_rewards = [
                reward for reward in rewards if reward.status == RewardStatus.ACTIVE
            ]
            if not active_rewards:
                continue

            active_rewards_count += len(active_rewards)
            business_statuses.append(
                CustomerBusinessStatusRead(
                    business_id=business.id,
                    business_name=business.name,
                    rewards=active_rewards,
                )
            )

        return CustomerStatusRead(
            customer_id=customer.id,
            active_rewards_count=active_rewards_count,
            businesses=business_statuses,
        )

    def get_campaign_progress(self, customer: User, campaign_id) -> CampaignProgressRead:
        self._require_role(customer, UserRole.CUSTOMER)
        campaign = self.repository.get_campaign(campaign_id)
        if campaign is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Campaign not found")
        progress_points = self.repository.sum_campaign_points(
            campaign=campaign, customer_id=customer.id
        )
        completion = self.repository.get_campaign_completion(
            campaign_id=campaign.id, customer_id=customer.id
        )
        return CampaignProgressRead(
            campaign_id=campaign.id,
            customer_id=customer.id,
            progress_points=progress_points,
            threshold_points=campaign.threshold_points,
            is_completed=completion is not None,
        )

    def list_customer_rewards(self, customer: User, business_id) -> list[GeneratedRewardRead]:
        self._require_role(customer, UserRole.CUSTOMER)
        rewards = self.repository.list_customer_rewards(
            business_id=business_id, customer_id=customer.id
        )
        now = datetime.now(UTC)
        return [self._reward_read(self._expire_if_needed(reward, now)) for reward in rewards]

    def use_reward(
        self, staff: User, reward_id, payload: UseRewardRequest
    ) -> UseRewardResponse:
        self._require_role(staff, UserRole.STAFF)
        if self.repository.get_staff_membership(
            business_id=payload.business_id, staff_user_id=staff.id
        ) is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Staff does not belong to this business",
            )

        existing_action = self.repository.get_action_by_idempotency_key(
            business_id=payload.business_id, idempotency_key=payload.idempotency_key
        )
        if existing_action is not None:
            usage = self.repository.get_reward_usage_for_reward(reward_id)
            reward = self.repository.get_generated_reward(reward_id)
            if usage is None or reward is None or usage.action_id != existing_action.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Idempotency key is already used for another operation",
                )
            self._audit(
                event_type=AuditEventType.IDEMPOTENCY_REPLAYED,
                actor_user_id=staff.id,
                business_id=payload.business_id,
                entity_type="reward_usage",
                entity_id=usage.id,
                metadata={"idempotency_key": payload.idempotency_key},
            )
            return UseRewardResponse(
                reward=self._reward_read(reward),
                usage=usage,
                idempotency_replayed=True,
            )

        reward = self.repository.get_generated_reward(reward_id)
        if reward is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reward not found")
        if reward.redeem_scope != RewardRedeemScope.ISSUER_BUSINESS_ONLY:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported redeem scope for MVP",
            )
        if reward.issuer_business_id != payload.business_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Reward cannot be redeemed at this business",
            )

        now = datetime.now(UTC)
        reward = self._expire_if_needed(reward, now)
        if reward.status == RewardStatus.EXPIRED:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reward is expired")
        if reward.status == RewardStatus.USED:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reward is already used")
        if reward.status != RewardStatus.ACTIVE:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reward is not active")

        action = self.repository.add_action(
            LoyaltyAction(
                business_id=payload.business_id,
                customer_id=reward.customer_id,
                staff_id=staff.id,
                action_type=LoyaltyActionType.REWARD_USE,
                idempotency_key=payload.idempotency_key,
                occurred_at=now,
                note=payload.note,
            )
        )
        usage = self.repository.add_reward_usage(
            RewardUsage(
                generated_reward_id=reward.id,
                redeemed_business_id=payload.business_id,
                issuer_business_id=reward.issuer_business_id,
                customer_id=reward.customer_id,
                staff_id=staff.id,
                action_id=action.id,
                used_at=now,
                note=payload.note,
                settlement_status=RewardSettlementStatus.NOT_REQUIRED,
            )
        )
        reward.status = RewardStatus.USED
        reward.used_at = now
        reward.updated_at = now

        self._audit(
            event_type=AuditEventType.REWARD_USED,
            actor_user_id=staff.id,
            business_id=payload.business_id,
            entity_type="reward_usage",
            entity_id=usage.id,
            metadata={
                "reward_id": str(reward.id),
                "customer_id": str(reward.customer_id),
                "issuer_business_id": str(reward.issuer_business_id),
                "redeemed_business_id": str(payload.business_id),
                "settlement_status": RewardSettlementStatus.NOT_REQUIRED.value,
            },
        )
        return UseRewardResponse(
            reward=self._reward_read(reward),
            usage=usage,
            idempotency_replayed=False,
        )

    def _evaluate_campaigns_for_action(
        self,
        *,
        action: LoyaltyAction,
        action_items: list[LoyaltyActionItem],
        actor_user_id,
    ) -> None:
        mission_ids = {item.mission_id for item in action_items}
        campaigns = self.repository.get_active_individual_campaigns_for_action(
            business_id=action.business_id,
            mission_ids=mission_ids,
            occurred_at=action.occurred_at,
        )
        for campaign in campaigns:
            existing_completion = self.repository.get_campaign_completion(
                campaign_id=campaign.id, customer_id=action.customer_id
            )
            if existing_completion is not None:
                continue

            progress_points = self.repository.sum_campaign_points(
                campaign=campaign, customer_id=action.customer_id
            )
            if progress_points < campaign.threshold_points:
                continue

            completion = self.repository.add_campaign_completion(
                CampaignCompletion(
                    campaign_id=campaign.id,
                    customer_id=action.customer_id,
                    progress_points=progress_points,
                    threshold_points=campaign.threshold_points,
                    completion_number=1,
                    completed_at=datetime.now(UTC),
                )
            )
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
                },
            )
            self._generate_reward_for_completion(completion, actor_user_id=actor_user_id)

    def _generate_reward_for_completion(
        self, completion: CampaignCompletion, *, actor_user_id
    ) -> GeneratedReward | None:
        source_type = RewardGenerationSourceType.INDIVIDUAL_CAMPAIGN_COMPLETION
        if completion.reward_generated_at is not None:
            return self.repository.get_generated_reward_for_source(
                source_type=source_type,
                source_id=completion.id,
                customer_id=completion.customer_id,
            )

        template = self.repository.get_active_reward_template_for_campaign(completion.campaign_id)
        if template is None:
            return None

        existing_reward = self.repository.get_generated_reward_for_source(
            source_type=source_type,
            source_id=completion.id,
            customer_id=completion.customer_id,
        )
        if existing_reward is not None:
            return existing_reward

        now = datetime.now(UTC)
        reward = self.repository.add_generated_reward(
            GeneratedReward(
                reward_template_id=template.id,
                campaign_id=completion.campaign_id,
                campaign_completion_id=completion.id,
                source_type=source_type,
                source_id=completion.id,
                business_id=template.business_id,
                issuer_business_id=template.issuer_business_id,
                customer_id=completion.customer_id,
                reward_type=template.reward_type,
                redeem_scope=template.redeem_scope,
                settlement_policy=template.settlement_policy,
                title=template.name,
                description=template.description,
                status=RewardStatus.ACTIVE,
                gift_name=template.gift_name,
                discount_percent=template.discount_percent,
                discount_amount_minor=template.discount_amount_minor,
                currency_code=template.currency_code,
                issued_at=now,
                expires_at=now + timedelta(days=template.valid_days),
            )
        )
        self.repository.mark_campaign_completion_reward_generated(completion, now)
        self._audit(
            event_type=AuditEventType.REWARD_GENERATED,
            actor_user_id=actor_user_id,
            business_id=template.business_id,
            entity_type="generated_reward",
            entity_id=reward.id,
            metadata={
                "campaign_id": str(completion.campaign_id),
                "campaign_completion_id": str(completion.id),
                "customer_id": str(completion.customer_id),
                "reward_template_id": str(template.id),
                "reward_type": template.reward_type.value,
            },
        )
        return reward

    def _expire_if_needed(self, reward: GeneratedReward, now: datetime) -> GeneratedReward:
        expires_at = self._as_utc(reward.expires_at)
        if reward.status == RewardStatus.ACTIVE and expires_at <= now:
            self.repository.expire_reward(reward, now)
            self._audit(
                event_type=AuditEventType.REWARD_EXPIRED,
                actor_user_id=None,
                business_id=reward.business_id,
                entity_type="generated_reward",
                entity_id=reward.id,
                metadata={"customer_id": str(reward.customer_id)},
            )
        return reward

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _reward_read(reward: GeneratedReward) -> GeneratedRewardRead:
        return GeneratedRewardRead.model_validate(reward)

    def _audit(
        self,
        *,
        event_type: AuditEventType,
        actor_user_id,
        business_id,
        entity_type: str,
        entity_id,
        metadata: dict[str, Any],
    ) -> None:
        self.repository.add_audit_event(
            AuditEvent(
                event_type=event_type,
                actor_user_id=actor_user_id,
                business_id=business_id,
                entity_type=entity_type,
                entity_id=entity_id,
                event_metadata=metadata,
            )
        )

    @staticmethod
    def _action_response(
        action: LoyaltyAction,
        *,
        idempotency_replayed: bool,
        items: list[LoyaltyActionItem] | None = None,
    ) -> RegisterActionResponse:
        action_items = list(action.items if items is None else items)
        return RegisterActionResponse(
            action_id=action.id,
            action_type=action.action_type,
            points_granted=sum(item.total_points for item in action_items),
            idempotency_replayed=idempotency_replayed,
            items=action_items,
        )

    @staticmethod
    def _require_role(user: User, role: UserRole) -> None:
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
