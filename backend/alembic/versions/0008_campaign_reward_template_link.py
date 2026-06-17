"""campaign reward template link

Revision ID: 0008_campaign_reward_link
Revises: 0007_repeatable_campaign_cycles
Create Date: 2026-06-17
"""

from typing import Sequence
from uuid import uuid4

import sqlalchemy as sa
from alembic import op


revision: str = "0008_campaign_reward_link"
down_revision: str | None = "0007_repeatable_campaign_cycles"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "campaign_reward_templates",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("campaign_id", sa.Uuid(), nullable=False),
        sa.Column("reward_template_id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["campaign_id"],
            ["campaigns.id"],
            name=op.f("fk_campaign_reward_templates_campaign_id_campaigns"),
        ),
        sa.ForeignKeyConstraint(
            ["reward_template_id"],
            ["reward_templates.id"],
            name=op.f("fk_campaign_reward_templates_reward_template_id_reward_templates"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_campaign_reward_templates")),
        sa.UniqueConstraint("campaign_id", name=op.f("uq_campaign_reward_templates_campaign_id")),
        sa.UniqueConstraint(
            "campaign_id",
            "reward_template_id",
            name=op.f("uq_campaign_reward_templates_campaign_id_reward_template_id"),
        ),
    )
    op.create_index(
        op.f("ix_campaign_reward_templates_campaign_id"),
        "campaign_reward_templates",
        ["campaign_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_campaign_reward_templates_reward_template_id"),
        "campaign_reward_templates",
        ["reward_template_id"],
        unique=False,
    )

    bind = op.get_bind()
    reward_templates = bind.execute(
        sa.text("SELECT id, campaign_id, created_at FROM reward_templates")
    ).mappings()
    bind.execute(
        sa.text(
            """
            INSERT INTO campaign_reward_templates (
                id,
                campaign_id,
                reward_template_id,
                created_at
            )
            VALUES (
                :id,
                :campaign_id,
                :reward_template_id,
                :created_at
            )
            """
        ),
        [
            {
                "id": uuid4(),
                "campaign_id": row["campaign_id"],
                "reward_template_id": row["id"],
                "created_at": row["created_at"],
            }
            for row in reward_templates
        ],
    )

    op.drop_constraint(
        op.f("uq_reward_templates_campaign_id"),
        "reward_templates",
        type_="unique",
    )
    op.drop_constraint(
        op.f("fk_reward_templates_campaign_id_campaigns"),
        "reward_templates",
        type_="foreignkey",
    )
    op.drop_index(op.f("ix_reward_templates_campaign_id"), table_name="reward_templates")
    op.drop_column("reward_templates", "campaign_id")


def downgrade() -> None:
    op.add_column("reward_templates", sa.Column("campaign_id", sa.Uuid(), nullable=True))
    op.execute(
        """
        UPDATE reward_templates
        SET campaign_id = campaign_reward_templates.campaign_id
        FROM campaign_reward_templates
        WHERE campaign_reward_templates.reward_template_id = reward_templates.id
        """
    )
    op.create_index(
        op.f("ix_reward_templates_campaign_id"),
        "reward_templates",
        ["campaign_id"],
        unique=False,
    )
    op.create_foreign_key(
        op.f("fk_reward_templates_campaign_id_campaigns"),
        "reward_templates",
        "campaigns",
        ["campaign_id"],
        ["id"],
    )
    op.create_unique_constraint(
        op.f("uq_reward_templates_campaign_id"),
        "reward_templates",
        ["campaign_id"],
    )
    op.alter_column("reward_templates", "campaign_id", nullable=False)
    op.drop_index(
        op.f("ix_campaign_reward_templates_reward_template_id"),
        table_name="campaign_reward_templates",
    )
    op.drop_index(
        op.f("ix_campaign_reward_templates_campaign_id"),
        table_name="campaign_reward_templates",
    )
    op.drop_table("campaign_reward_templates")
