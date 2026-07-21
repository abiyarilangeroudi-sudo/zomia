from collections.abc import Callable
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status

from app.modules.identity.models import User, UserRole
from app.modules.loyalty.models import (
    AuditEventType,
    Campaign,
    CampaignCompletion,
    GeneratedReward,
    LoyaltyAction,
    LoyaltyActionType,
    RewardGenerationSourceType,
    RewardRedeemScope,
    RewardSettlementStatus,
    RewardStatus,
    RewardTemplate,
    RewardUsage,
)
from app.modules.loyalty.repository import LoyaltyRepository
from app.modules.loyalty.schemas import (
    CustomerBusinessStatusRead,
    CustomerStatusRead,
    GeneratedRewardRead,
    UseRewardRequest,
    UseRewardResponse,
)

AuditRecorder = Callable[..., None]


class RewardService:
    def __init__(self, repository: LoyaltyRepository, audit: AuditRecorder) -> None:
        self.repository = repository
        self._audit = audit

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
            active_rewards = [reward for reward in rewards if reward.status == RewardStatus.ACTIVE]
            if not rewards:
                continue

            active_rewards_count += len(active_rewards)
            business_statuses.append(
                CustomerBusinessStatusRead(
                    business_id=business.id,
                    business_name=business.name,
                    rewards=rewards,
                )
            )

        return CustomerStatusRead(
            customer_id=customer.id,
            active_rewards_count=active_rewards_count,
            has_earned_first_point=self.repository.customer_has_points(customer.id),
            has_earned_first_reward=self.repository.customer_has_reward(customer.id),
            has_used_first_reward=self.repository.customer_has_used_reward(customer.id),
            businesses=business_statuses,
        )

    def list_customer_rewards(self, customer: User, business_id) -> list[GeneratedRewardRead]:
        self._require_role(customer, UserRole.CUSTOMER)
        rewards = self.repository.list_customer_rewards(
            business_id=business_id, customer_id=customer.id
        )
        now = datetime.now(UTC)
        return [self._reward_read(self._expire_if_needed(reward, now)) for reward in rewards]

    def validate_reward_customer(self, reward_id, customer_id) -> None:
        reward = self.repository.get_generated_reward(reward_id)
        if reward is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reward not found")
        if reward.customer_id != customer_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Reward does not belong to resolved customer",
            )
    def use_reward(self, staff: User, reward_id, payload: UseRewardRequest) -> UseRewardResponse:
        self._require_role(staff, UserRole.STAFF)
        if (
            self.repository.get_staff_membership(
                business_id=payload.business_id, staff_user_id=staff.id
            )
            is None
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Staff does not belong to this business",
            )

        existing_action = self.repository.get_action_by_idempotency_key(
            business_id=payload.business_id, idempotency_key=payload.idempotency_key
        )
        if existing_action is not None:
            return self._replay_reward_use(
                staff=staff,
                reward_id=reward_id,
                payload=payload,
                action=existing_action,
            )

        reward = self.repository.get_generated_reward_for_update(reward_id)
        if reward is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reward not found")
        existing_action = self.repository.get_action_by_idempotency_key(
            business_id=payload.business_id, idempotency_key=payload.idempotency_key
        )
        if existing_action is not None:
            return self._replay_reward_use(
                staff=staff,
                reward_id=reward_id,
                payload=payload,
                action=existing_action,
            )
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
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Reward is already used"
            )
        if reward.status != RewardStatus.ACTIVE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Reward is not active"
            )

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

    def generate_for_completion(
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

    def generate_early_end_settlement(
        self,
        *,
        campaign: Campaign,
        template: RewardTemplate,
        customer_id,
        actor_user_id,
        issued_at: datetime,
    ) -> GeneratedReward:
        source_type = RewardGenerationSourceType.EARLY_END_SETTLEMENT
        existing_reward = self.repository.get_generated_reward_for_source(
            source_type=source_type,
            source_id=campaign.id,
            customer_id=customer_id,
        )
        if existing_reward is not None:
            return existing_reward

        reward = self.repository.add_generated_reward(
            GeneratedReward(
                reward_template_id=template.id,
                campaign_id=campaign.id,
                campaign_completion_id=None,
                source_type=source_type,
                source_id=campaign.id,
                business_id=template.business_id,
                issuer_business_id=template.issuer_business_id,
                customer_id=customer_id,
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
                issued_at=issued_at,
                expires_at=issued_at + timedelta(days=template.valid_days),
            )
        )
        self._audit(
            event_type=AuditEventType.REWARD_GENERATED,
            actor_user_id=actor_user_id,
            business_id=template.business_id,
            entity_type="generated_reward",
            entity_id=reward.id,
            metadata={
                "campaign_id": str(campaign.id),
                "customer_id": str(customer_id),
                "reward_template_id": str(template.id),
                "reward_type": template.reward_type.value,
                "source_type": source_type.value,
            },
        )
        return reward

    def _replay_reward_use(
        self,
        *,
        staff: User,
        reward_id,
        payload: UseRewardRequest,
        action: LoyaltyAction,
    ) -> UseRewardResponse:
        usage = self.repository.get_reward_usage_for_reward(reward_id)
        reward = self.repository.get_generated_reward(reward_id)
        if usage is None or reward is None or usage.action_id != action.id:
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

    @staticmethod
    def _require_role(user: User, role: UserRole) -> None:
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
