"""repeatable campaign cycles

Revision ID: 0007_repeatable_campaign_cycles
Revises: 0006_qr_tokens
Create Date: 2026-06-14
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0007_repeatable_campaign_cycles"
down_revision: str | None = "0006_qr_tokens"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.drop_constraint(
        op.f("uq_campaign_completions_campaign_id"),
        "campaign_completions",
        type_="unique",
    )
    op.create_unique_constraint(
        "campaign_completion_cycle_unique",
        "campaign_completions",
        ["campaign_id", "customer_id", "completion_number"],
    )

    op.drop_constraint(
        op.f("ck_campaigns_campaign_max_completions_per_customer_positive"),
        "campaigns",
        type_="check",
    )
    op.alter_column("campaigns", "max_completions_per_customer", nullable=True)
    op.create_check_constraint(
        op.f("ck_campaigns_campaign_max_completions_per_customer_positive"),
        "campaigns",
        "max_completions_per_customer IS NULL OR max_completions_per_customer > 0",
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("ck_campaigns_campaign_max_completions_per_customer_positive"),
        "campaigns",
        type_="check",
    )
    op.execute(
        """
        UPDATE campaigns
        SET max_completions_per_customer = 1
        WHERE max_completions_per_customer IS NULL
        """
    )
    op.alter_column("campaigns", "max_completions_per_customer", nullable=False)
    op.create_check_constraint(
        op.f("ck_campaigns_campaign_max_completions_per_customer_positive"),
        "campaigns",
        "max_completions_per_customer > 0",
    )

    op.drop_constraint(
        "campaign_completion_cycle_unique",
        "campaign_completions",
        type_="unique",
    )
    op.create_unique_constraint(
        op.f("uq_campaign_completions_campaign_id"),
        "campaign_completions",
        ["campaign_id", "customer_id"],
    )
