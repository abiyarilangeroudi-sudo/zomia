"""staff invitations

Revision ID: 0011_staff_invitations
Revises: 0010_email_verification_otps
Create Date: 2026-06-18
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "0011_staff_invitations"
down_revision: str | None = "0010_email_verification_otps"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    staff_invitation_status = postgresql.ENUM(
        "PENDING",
        "ACCEPTED",
        "CANCELLED",
        "EXPIRED",
        name="staff_invitation_status",
        create_type=False,
    )
    staff_invitation_status.create(op.get_bind(), checkfirst=True)
    op.create_table(
        "staff_invitations",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("invited_email", sa.String(length=255), nullable=False),
        sa.Column("invited_by_owner_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("status", staff_invitation_status, nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["business_id"],
            ["businesses.id"],
            name=op.f("fk_staff_invitations_business_id_businesses"),
        ),
        sa.ForeignKeyConstraint(
            ["invited_by_owner_id"],
            ["users.id"],
            name=op.f("fk_staff_invitations_invited_by_owner_id_users"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_staff_invitations")),
        sa.UniqueConstraint("token_hash", name=op.f("uq_staff_invitations_token_hash")),
    )
    op.create_index(
        op.f("ix_staff_invitations_business_id"),
        "staff_invitations",
        ["business_id"],
    )
    op.create_index(
        op.f("ix_staff_invitations_expires_at"),
        "staff_invitations",
        ["expires_at"],
    )
    op.create_index(
        op.f("ix_staff_invitations_invited_by_owner_id"),
        "staff_invitations",
        ["invited_by_owner_id"],
    )
    op.create_index(
        op.f("ix_staff_invitations_invited_email"),
        "staff_invitations",
        ["invited_email"],
    )
    op.create_index(
        op.f("ix_staff_invitations_status"),
        "staff_invitations",
        ["status"],
    )
    op.create_index(
        op.f("ix_staff_invitations_token_hash"),
        "staff_invitations",
        ["token_hash"],
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_staff_invitations_token_hash"), table_name="staff_invitations")
    op.drop_index(op.f("ix_staff_invitations_status"), table_name="staff_invitations")
    op.drop_index(op.f("ix_staff_invitations_invited_email"), table_name="staff_invitations")
    op.drop_index(
        op.f("ix_staff_invitations_invited_by_owner_id"), table_name="staff_invitations"
    )
    op.drop_index(op.f("ix_staff_invitations_expires_at"), table_name="staff_invitations")
    op.drop_index(op.f("ix_staff_invitations_business_id"), table_name="staff_invitations")
    op.drop_table("staff_invitations")
    sa.Enum(name="staff_invitation_status").drop(op.get_bind(), checkfirst=True)
