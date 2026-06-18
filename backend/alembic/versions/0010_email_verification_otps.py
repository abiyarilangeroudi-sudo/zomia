"""email verification otps

Revision ID: 0010_email_verification_otps
Revises: 0009_refresh_tokens
Create Date: 2026-06-18
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op


revision: str = "0010_email_verification_otps"
down_revision: str | None = "0009_refresh_tokens"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("email_verified_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_table(
        "email_verification_otps",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("purpose", sa.String(length=64), nullable=False),
        sa.Column("code_hash", sa.String(length=64), nullable=False),
        sa.Column("payload_json", sa.JSON(), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("attempt_count", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_email_verification_otps")),
    )
    op.create_index(
        op.f("ix_email_verification_otps_email"),
        "email_verification_otps",
        ["email"],
    )
    op.create_index(
        op.f("ix_email_verification_otps_expires_at"),
        "email_verification_otps",
        ["expires_at"],
    )
    op.create_index(
        op.f("ix_email_verification_otps_purpose"),
        "email_verification_otps",
        ["purpose"],
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_email_verification_otps_purpose"), table_name="email_verification_otps")
    op.drop_index(
        op.f("ix_email_verification_otps_expires_at"), table_name="email_verification_otps"
    )
    op.drop_index(op.f("ix_email_verification_otps_email"), table_name="email_verification_otps")
    op.drop_table("email_verification_otps")
    op.drop_column("users", "email_verified_at")

