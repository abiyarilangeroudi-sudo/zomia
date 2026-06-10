"""individual campaign foundation

Revision ID: 0003_individual_campaign
Revises: 0002_loyalty_foundation
Create Date: 2026-06-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0003_individual_campaign"
down_revision: str | None = "0002_loyalty_foundation"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("ALTER TYPE audit_event_type ADD VALUE IF NOT EXISTS 'campaign_created'")
    op.execute("ALTER TYPE audit_event_type ADD VALUE IF NOT EXISTS 'campaign_completed'")

    campaign_type = postgresql.ENUM(
        "individual", "group", "cross_network", name="campaign_type", create_type=False
    )
    campaign_scope_type = postgresql.ENUM(
        "single_business", "fans_group", "partner_network", name="campaign_scope_type", create_type=False
    )
    campaign_participation_mode = postgresql.ENUM(
        "automatic",
        "explicit",
        "group_membership",
        name="campaign_participation_mode",
        create_type=False,
    )
    campaign_progress_metric = postgresql.ENUM(
        "points", "quantity", "action_count", name="campaign_progress_metric", create_type=False
    )
    campaign_status = postgresql.ENUM(
        "draft", "active", "paused", "ended", name="campaign_status", create_type=False
    )

    campaign_type.create(op.get_bind(), checkfirst=True)
    campaign_scope_type.create(op.get_bind(), checkfirst=True)
    campaign_participation_mode.create(op.get_bind(), checkfirst=True)
    campaign_progress_metric.create(op.get_bind(), checkfirst=True)
    campaign_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "campaigns",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("creator_business_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("description", sa.String(length=500), nullable=True),
        sa.Column("campaign_type", campaign_type, nullable=False),
        sa.Column("scope_type", campaign_scope_type, nullable=False),
        sa.Column("participation_mode", campaign_participation_mode, nullable=False),
        sa.Column("progress_metric", campaign_progress_metric, nullable=False),
        sa.Column("threshold_points", sa.Integer(), nullable=False),
        sa.Column("is_repeatable", sa.Boolean(), nullable=False),
        sa.Column("max_completions_per_customer", sa.Integer(), nullable=False),
        sa.Column("status", campaign_status, nullable=False),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("ends_at > starts_at", name=op.f("ck_campaigns_campaign_time_window_valid")),
        sa.CheckConstraint(
            "max_completions_per_customer > 0",
            name=op.f("ck_campaigns_campaign_max_completions_per_customer_positive"),
        ),
        sa.CheckConstraint(
            "threshold_points > 0", name=op.f("ck_campaigns_campaign_threshold_points_positive")
        ),
        sa.ForeignKeyConstraint(
            ["creator_business_id"],
            ["businesses.id"],
            name=op.f("fk_campaigns_creator_business_id_businesses"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_campaigns")),
    )
    op.create_index(op.f("ix_campaigns_campaign_type"), "campaigns", ["campaign_type"], unique=False)
    op.create_index(
        op.f("ix_campaigns_creator_business_id"), "campaigns", ["creator_business_id"], unique=False
    )
    op.create_index(op.f("ix_campaigns_ends_at"), "campaigns", ["ends_at"], unique=False)
    op.create_index(op.f("ix_campaigns_scope_type"), "campaigns", ["scope_type"], unique=False)
    op.create_index(op.f("ix_campaigns_starts_at"), "campaigns", ["starts_at"], unique=False)
    op.create_index(op.f("ix_campaigns_status"), "campaigns", ["status"], unique=False)

    op.create_table(
        "campaign_missions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("campaign_id", sa.Uuid(), nullable=False),
        sa.Column("mission_id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["campaign_id"], ["campaigns.id"], name=op.f("fk_campaign_missions_campaign_id_campaigns")
        ),
        sa.ForeignKeyConstraint(
            ["mission_id"], ["missions.id"], name=op.f("fk_campaign_missions_mission_id_missions")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_campaign_missions")),
        sa.UniqueConstraint("campaign_id", "mission_id", name=op.f("uq_campaign_missions_campaign_id")),
    )
    op.create_index(
        op.f("ix_campaign_missions_campaign_id"), "campaign_missions", ["campaign_id"], unique=False
    )
    op.create_index(
        op.f("ix_campaign_missions_mission_id"), "campaign_missions", ["mission_id"], unique=False
    )

    op.create_table(
        "campaign_completions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("campaign_id", sa.Uuid(), nullable=False),
        sa.Column("customer_id", sa.Uuid(), nullable=False),
        sa.Column("progress_points", sa.Integer(), nullable=False),
        sa.Column("threshold_points", sa.Integer(), nullable=False),
        sa.Column("completion_number", sa.Integer(), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reward_generated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "completion_number > 0",
            name=op.f("ck_campaign_completions_campaign_completion_number_positive"),
        ),
        sa.CheckConstraint(
            "progress_points > 0",
            name=op.f("ck_campaign_completions_campaign_completion_progress_points_positive"),
        ),
        sa.CheckConstraint(
            "threshold_points > 0",
            name=op.f("ck_campaign_completions_campaign_completion_threshold_points_positive"),
        ),
        sa.ForeignKeyConstraint(
            ["campaign_id"],
            ["campaigns.id"],
            name=op.f("fk_campaign_completions_campaign_id_campaigns"),
        ),
        sa.ForeignKeyConstraint(
            ["customer_id"], ["users.id"], name=op.f("fk_campaign_completions_customer_id_users")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_campaign_completions")),
        sa.UniqueConstraint(
            "campaign_id", "customer_id", name=op.f("uq_campaign_completions_campaign_id")
        ),
    )
    op.create_index(
        op.f("ix_campaign_completions_campaign_id"),
        "campaign_completions",
        ["campaign_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_campaign_completions_customer_id"),
        "campaign_completions",
        ["customer_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_campaign_completions_customer_id"), table_name="campaign_completions")
    op.drop_index(op.f("ix_campaign_completions_campaign_id"), table_name="campaign_completions")
    op.drop_table("campaign_completions")
    op.drop_index(op.f("ix_campaign_missions_mission_id"), table_name="campaign_missions")
    op.drop_index(op.f("ix_campaign_missions_campaign_id"), table_name="campaign_missions")
    op.drop_table("campaign_missions")
    op.drop_index(op.f("ix_campaigns_status"), table_name="campaigns")
    op.drop_index(op.f("ix_campaigns_starts_at"), table_name="campaigns")
    op.drop_index(op.f("ix_campaigns_scope_type"), table_name="campaigns")
    op.drop_index(op.f("ix_campaigns_ends_at"), table_name="campaigns")
    op.drop_index(op.f("ix_campaigns_creator_business_id"), table_name="campaigns")
    op.drop_index(op.f("ix_campaigns_campaign_type"), table_name="campaigns")
    op.drop_table("campaigns")

    postgresql.ENUM(name="campaign_status").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="campaign_progress_metric").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="campaign_participation_mode").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="campaign_scope_type").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="campaign_type").drop(op.get_bind(), checkfirst=True)
