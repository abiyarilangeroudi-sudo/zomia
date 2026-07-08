"""remove paused campaign status

Revision ID: 0013_remove_paused_status
Revises: 0012_user_session_version
Create Date: 2026-07-08
"""

from collections.abc import Sequence

from alembic import op


revision: str = "0013_remove_paused_status"
down_revision: str | None = "0012_user_session_version"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("UPDATE campaigns SET status = 'ended' WHERE status = 'paused'")
    op.execute("ALTER TYPE campaign_status RENAME TO campaign_status_old")
    op.execute("CREATE TYPE campaign_status AS ENUM ('draft', 'active', 'ended')")
    op.execute(
        """
        ALTER TABLE campaigns
        ALTER COLUMN status TYPE campaign_status
        USING status::text::campaign_status
        """
    )
    op.execute("DROP TYPE campaign_status_old")


def downgrade() -> None:
    op.execute("ALTER TYPE campaign_status RENAME TO campaign_status_old")
    op.execute("CREATE TYPE campaign_status AS ENUM ('draft', 'active', 'paused', 'ended')")
    op.execute(
        """
        ALTER TABLE campaigns
        ALTER COLUMN status TYPE campaign_status
        USING status::text::campaign_status
        """
    )
    op.execute("DROP TYPE campaign_status_old")
