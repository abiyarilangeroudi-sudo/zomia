"""generalize reward generation source

Revision ID: 0005_reward_source
Revises: 0004_reward_engine
Create Date: 2026-06-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0005_reward_source"
down_revision: str | None = "0004_reward_engine"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    reward_generation_source_type = postgresql.ENUM(
        "individual_campaign_completion",
        "group_campaign_completion",
        name="reward_generation_source_type",
        create_type=False,
    )
    reward_generation_source_type.create(op.get_bind(), checkfirst=True)

    op.add_column(
        "generated_rewards",
        sa.Column("source_type", reward_generation_source_type, nullable=True),
    )
    op.add_column("generated_rewards", sa.Column("source_id", sa.Uuid(), nullable=True))

    op.execute(
        """
        UPDATE generated_rewards
        SET source_type = 'individual_campaign_completion',
            source_id = campaign_completion_id
        WHERE source_type IS NULL
        """
    )

    op.alter_column(
        "generated_rewards",
        "source_type",
        existing_type=reward_generation_source_type,
        nullable=False,
    )
    op.alter_column("generated_rewards", "source_id", existing_type=sa.Uuid(), nullable=False)

    op.drop_constraint(
        "uq_generated_rewards_campaign_completion_id",
        "generated_rewards",
        type_="unique",
    )
    op.alter_column(
        "generated_rewards",
        "campaign_completion_id",
        existing_type=sa.Uuid(),
        nullable=True,
    )

    op.create_index(
        op.f("ix_generated_rewards_source_type"),
        "generated_rewards",
        ["source_type"],
        unique=False,
    )
    op.create_index(
        op.f("ix_generated_rewards_source_id"),
        "generated_rewards",
        ["source_id"],
        unique=False,
    )
    op.create_unique_constraint(
        "uq_generated_rewards_source_type_source_id_customer_id",
        "generated_rewards",
        ["source_type", "source_id", "customer_id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_generated_rewards_source_type_source_id_customer_id",
        "generated_rewards",
        type_="unique",
    )
    op.drop_index(op.f("ix_generated_rewards_source_id"), table_name="generated_rewards")
    op.drop_index(op.f("ix_generated_rewards_source_type"), table_name="generated_rewards")
    op.alter_column(
        "generated_rewards",
        "campaign_completion_id",
        existing_type=sa.Uuid(),
        nullable=False,
    )
    op.create_unique_constraint(
        "uq_generated_rewards_campaign_completion_id",
        "generated_rewards",
        ["campaign_completion_id"],
    )
    op.drop_column("generated_rewards", "source_id")
    op.drop_column("generated_rewards", "source_type")
    postgresql.ENUM(name="reward_generation_source_type").drop(op.get_bind(), checkfirst=True)
