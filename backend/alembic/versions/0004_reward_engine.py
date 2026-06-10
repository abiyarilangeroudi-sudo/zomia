"""reward engine

Revision ID: 0004_reward_engine
Revises: 0003_individual_campaign
Create Date: 2026-06-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0004_reward_engine"
down_revision: str | None = "0003_individual_campaign"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("ALTER TYPE audit_event_type ADD VALUE IF NOT EXISTS 'reward_template_created'")
    op.execute("ALTER TYPE audit_event_type ADD VALUE IF NOT EXISTS 'reward_generated'")
    op.execute("ALTER TYPE audit_event_type ADD VALUE IF NOT EXISTS 'reward_used'")
    op.execute("ALTER TYPE audit_event_type ADD VALUE IF NOT EXISTS 'reward_expired'")

    reward_type = postgresql.ENUM(
        "gift", "percentage_discount", "fixed_discount", name="reward_type", create_type=False
    )
    reward_status = postgresql.ENUM(
        "active", "used", "expired", name="reward_status", create_type=False
    )
    reward_redeem_scope = postgresql.ENUM(
        "issuer_business_only",
        "campaign_participants",
        "selected_businesses",
        name="reward_redeem_scope",
        create_type=False,
    )
    reward_settlement_policy = postgresql.ENUM(
        "issuer_pays",
        "redeemer_pays",
        "shared_pool",
        "platform_settlement",
        name="reward_settlement_policy",
        create_type=False,
    )
    reward_settlement_status = postgresql.ENUM(
        "not_required", "pending", "settled", name="reward_settlement_status", create_type=False
    )

    reward_type.create(op.get_bind(), checkfirst=True)
    reward_status.create(op.get_bind(), checkfirst=True)
    reward_redeem_scope.create(op.get_bind(), checkfirst=True)
    reward_settlement_policy.create(op.get_bind(), checkfirst=True)
    reward_settlement_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "reward_templates",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("issuer_business_id", sa.Uuid(), nullable=False),
        sa.Column("campaign_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("description", sa.String(length=500), nullable=True),
        sa.Column("reward_type", reward_type, nullable=False),
        sa.Column("redeem_scope", reward_redeem_scope, nullable=False),
        sa.Column("settlement_policy", reward_settlement_policy, nullable=False),
        sa.Column("gift_name", sa.String(length=160), nullable=True),
        sa.Column("discount_percent", sa.Integer(), nullable=True),
        sa.Column("discount_amount_minor", sa.Integer(), nullable=True),
        sa.Column("currency_code", sa.String(length=3), nullable=True),
        sa.Column("valid_days", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "discount_amount_minor IS NULL OR discount_amount_minor > 0",
            name=op.f("ck_reward_templates_reward_template_discount_amount_minor_positive"),
        ),
        sa.CheckConstraint(
            "discount_percent IS NULL OR (discount_percent > 0 AND discount_percent <= 100)",
            name=op.f("ck_reward_templates_reward_template_discount_percent_valid"),
        ),
        sa.CheckConstraint(
            "valid_days > 0", name=op.f("ck_reward_templates_reward_template_valid_days_positive")
        ),
        sa.ForeignKeyConstraint(
            ["business_id"], ["businesses.id"], name=op.f("fk_reward_templates_business_id_businesses")
        ),
        sa.ForeignKeyConstraint(
            ["campaign_id"], ["campaigns.id"], name=op.f("fk_reward_templates_campaign_id_campaigns")
        ),
        sa.ForeignKeyConstraint(
            ["issuer_business_id"],
            ["businesses.id"],
            name=op.f("fk_reward_templates_issuer_business_id_businesses"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_reward_templates")),
        sa.UniqueConstraint("campaign_id", name=op.f("uq_reward_templates_campaign_id")),
    )
    op.create_index(
        op.f("ix_reward_templates_business_id"), "reward_templates", ["business_id"], unique=False
    )
    op.create_index(
        op.f("ix_reward_templates_campaign_id"), "reward_templates", ["campaign_id"], unique=False
    )
    op.create_index(
        op.f("ix_reward_templates_issuer_business_id"),
        "reward_templates",
        ["issuer_business_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_reward_templates_reward_type"), "reward_templates", ["reward_type"], unique=False
    )

    op.create_table(
        "generated_rewards",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("reward_template_id", sa.Uuid(), nullable=False),
        sa.Column("campaign_id", sa.Uuid(), nullable=False),
        sa.Column("campaign_completion_id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("issuer_business_id", sa.Uuid(), nullable=False),
        sa.Column("customer_id", sa.Uuid(), nullable=False),
        sa.Column("reward_type", reward_type, nullable=False),
        sa.Column("redeem_scope", reward_redeem_scope, nullable=False),
        sa.Column("settlement_policy", reward_settlement_policy, nullable=False),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("description", sa.String(length=500), nullable=True),
        sa.Column("status", reward_status, nullable=False),
        sa.Column("gift_name", sa.String(length=160), nullable=True),
        sa.Column("discount_percent", sa.Integer(), nullable=True),
        sa.Column("discount_amount_minor", sa.Integer(), nullable=True),
        sa.Column("currency_code", sa.String(length=3), nullable=True),
        sa.Column("issued_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "discount_amount_minor IS NULL OR discount_amount_minor > 0",
            name=op.f("ck_generated_rewards_generated_reward_discount_amount_minor_positive"),
        ),
        sa.CheckConstraint(
            "discount_percent IS NULL OR (discount_percent > 0 AND discount_percent <= 100)",
            name=op.f("ck_generated_rewards_generated_reward_discount_percent_valid"),
        ),
        sa.ForeignKeyConstraint(
            ["business_id"], ["businesses.id"], name=op.f("fk_generated_rewards_business_id_businesses")
        ),
        sa.ForeignKeyConstraint(
            ["campaign_completion_id"],
            ["campaign_completions.id"],
            name=op.f("fk_generated_rewards_campaign_completion_id_campaign_completions"),
        ),
        sa.ForeignKeyConstraint(
            ["campaign_id"], ["campaigns.id"], name=op.f("fk_generated_rewards_campaign_id_campaigns")
        ),
        sa.ForeignKeyConstraint(
            ["customer_id"], ["users.id"], name=op.f("fk_generated_rewards_customer_id_users")
        ),
        sa.ForeignKeyConstraint(
            ["issuer_business_id"],
            ["businesses.id"],
            name=op.f("fk_generated_rewards_issuer_business_id_businesses"),
        ),
        sa.ForeignKeyConstraint(
            ["reward_template_id"],
            ["reward_templates.id"],
            name=op.f("fk_generated_rewards_reward_template_id_reward_templates"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_generated_rewards")),
        sa.UniqueConstraint(
            "campaign_completion_id", name=op.f("uq_generated_rewards_campaign_completion_id")
        ),
    )
    op.create_index(
        op.f("ix_generated_rewards_business_id"), "generated_rewards", ["business_id"], unique=False
    )
    op.create_index(
        op.f("ix_generated_rewards_campaign_completion_id"),
        "generated_rewards",
        ["campaign_completion_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_generated_rewards_campaign_id"), "generated_rewards", ["campaign_id"], unique=False
    )
    op.create_index(
        op.f("ix_generated_rewards_customer_id"), "generated_rewards", ["customer_id"], unique=False
    )
    op.create_index(
        op.f("ix_generated_rewards_expires_at"), "generated_rewards", ["expires_at"], unique=False
    )
    op.create_index(
        op.f("ix_generated_rewards_issuer_business_id"),
        "generated_rewards",
        ["issuer_business_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_generated_rewards_reward_template_id"),
        "generated_rewards",
        ["reward_template_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_generated_rewards_reward_type"), "generated_rewards", ["reward_type"], unique=False
    )
    op.create_index(
        op.f("ix_generated_rewards_status"), "generated_rewards", ["status"], unique=False
    )

    op.create_table(
        "reward_usages",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("generated_reward_id", sa.Uuid(), nullable=False),
        sa.Column("redeemed_business_id", sa.Uuid(), nullable=False),
        sa.Column("issuer_business_id", sa.Uuid(), nullable=False),
        sa.Column("customer_id", sa.Uuid(), nullable=False),
        sa.Column("staff_id", sa.Uuid(), nullable=False),
        sa.Column("action_id", sa.Uuid(), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("note", sa.String(length=500), nullable=True),
        sa.Column("settlement_status", reward_settlement_status, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["action_id"], ["loyalty_actions.id"], name=op.f("fk_reward_usages_action_id_loyalty_actions")
        ),
        sa.ForeignKeyConstraint(
            ["customer_id"], ["users.id"], name=op.f("fk_reward_usages_customer_id_users")
        ),
        sa.ForeignKeyConstraint(
            ["generated_reward_id"],
            ["generated_rewards.id"],
            name=op.f("fk_reward_usages_generated_reward_id_generated_rewards"),
        ),
        sa.ForeignKeyConstraint(
            ["issuer_business_id"],
            ["businesses.id"],
            name=op.f("fk_reward_usages_issuer_business_id_businesses"),
        ),
        sa.ForeignKeyConstraint(
            ["redeemed_business_id"],
            ["businesses.id"],
            name=op.f("fk_reward_usages_redeemed_business_id_businesses"),
        ),
        sa.ForeignKeyConstraint(["staff_id"], ["users.id"], name=op.f("fk_reward_usages_staff_id_users")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_reward_usages")),
        sa.UniqueConstraint("generated_reward_id", name=op.f("uq_reward_usages_generated_reward_id")),
    )
    op.create_index(op.f("ix_reward_usages_action_id"), "reward_usages", ["action_id"], unique=False)
    op.create_index(
        op.f("ix_reward_usages_customer_id"), "reward_usages", ["customer_id"], unique=False
    )
    op.create_index(
        op.f("ix_reward_usages_generated_reward_id"),
        "reward_usages",
        ["generated_reward_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_reward_usages_issuer_business_id"),
        "reward_usages",
        ["issuer_business_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_reward_usages_redeemed_business_id"),
        "reward_usages",
        ["redeemed_business_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_reward_usages_settlement_status"),
        "reward_usages",
        ["settlement_status"],
        unique=False,
    )
    op.create_index(op.f("ix_reward_usages_staff_id"), "reward_usages", ["staff_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_reward_usages_staff_id"), table_name="reward_usages")
    op.drop_index(op.f("ix_reward_usages_settlement_status"), table_name="reward_usages")
    op.drop_index(op.f("ix_reward_usages_redeemed_business_id"), table_name="reward_usages")
    op.drop_index(op.f("ix_reward_usages_issuer_business_id"), table_name="reward_usages")
    op.drop_index(op.f("ix_reward_usages_generated_reward_id"), table_name="reward_usages")
    op.drop_index(op.f("ix_reward_usages_customer_id"), table_name="reward_usages")
    op.drop_index(op.f("ix_reward_usages_action_id"), table_name="reward_usages")
    op.drop_table("reward_usages")
    op.drop_index(op.f("ix_generated_rewards_status"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_reward_type"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_reward_template_id"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_issuer_business_id"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_expires_at"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_customer_id"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_campaign_id"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_campaign_completion_id"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_business_id"), table_name="generated_rewards")
    op.drop_table("generated_rewards")
    op.drop_index(op.f("ix_reward_templates_reward_type"), table_name="reward_templates")
    op.drop_index(op.f("ix_reward_templates_issuer_business_id"), table_name="reward_templates")
    op.drop_index(op.f("ix_reward_templates_campaign_id"), table_name="reward_templates")
    op.drop_index(op.f("ix_reward_templates_business_id"), table_name="reward_templates")
    op.drop_table("reward_templates")

    postgresql.ENUM(name="reward_settlement_status").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="reward_settlement_policy").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="reward_redeem_scope").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="reward_status").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="reward_type").drop(op.get_bind(), checkfirst=True)
