"""qr tokens

Revision ID: 0006_qr_tokens
Revises: 0005_reward_source
Create Date: 2026-06-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0006_qr_tokens"
down_revision: str | None = "0005_reward_source"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    customer_qr_token_status = postgresql.ENUM(
        "active",
        "revoked",
        "expired",
        name="customer_qr_token_status",
        create_type=False,
    )
    customer_qr_token_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "customer_qr_tokens",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("customer_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("status", customer_qr_token_status, nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["customer_id"], ["users.id"], name=op.f("fk_customer_qr_tokens_customer_id_users")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_customer_qr_tokens")),
        sa.UniqueConstraint("token_hash", name=op.f("uq_customer_qr_tokens_token_hash")),
    )
    op.create_index(
        op.f("ix_customer_qr_tokens_customer_id"),
        "customer_qr_tokens",
        ["customer_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_customer_qr_tokens_expires_at"),
        "customer_qr_tokens",
        ["expires_at"],
        unique=False,
    )
    op.create_index(
        op.f("ix_customer_qr_tokens_status"),
        "customer_qr_tokens",
        ["status"],
        unique=False,
    )
    op.create_index(
        op.f("ix_customer_qr_tokens_token_hash"),
        "customer_qr_tokens",
        ["token_hash"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_customer_qr_tokens_token_hash"), table_name="customer_qr_tokens")
    op.drop_index(op.f("ix_customer_qr_tokens_status"), table_name="customer_qr_tokens")
    op.drop_index(op.f("ix_customer_qr_tokens_expires_at"), table_name="customer_qr_tokens")
    op.drop_index(op.f("ix_customer_qr_tokens_customer_id"), table_name="customer_qr_tokens")
    op.drop_table("customer_qr_tokens")
    postgresql.ENUM(name="customer_qr_token_status").drop(op.get_bind(), checkfirst=True)
