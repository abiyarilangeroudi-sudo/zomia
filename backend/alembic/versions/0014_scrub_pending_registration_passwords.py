"""scrub pending registration passwords

Revision ID: 0014_scrub_registration_password
Revises: 0013_remove_paused_status
Create Date: 2026-07-10
"""

from collections.abc import Sequence

from alembic import op


revision: str = "0014_scrub_registration_password"
down_revision: str | None = "0013_remove_paused_status"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        DELETE FROM email_verification_otps
        WHERE purpose IN ('customer_registration', 'owner_registration')
        """
    )


def downgrade() -> None:
    pass
