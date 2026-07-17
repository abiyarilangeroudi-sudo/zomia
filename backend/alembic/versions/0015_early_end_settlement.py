"""add early end settlement reward source

Revision ID: 0015_early_end_settlement
Revises: 0014_scrub_registration_password
Create Date: 2026-07-17
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0015_early_end_settlement"
down_revision: str | None = "0014_scrub_registration_password"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        "ALTER TYPE reward_generation_source_type "
        "ADD VALUE IF NOT EXISTS 'early_end_settlement'"
    )
    op.execute("ALTER TYPE audit_event_type ADD VALUE IF NOT EXISTS 'campaign_ended'")


def downgrade() -> None:
    # PostgreSQL enum values are intentionally retained on downgrade.
    pass
