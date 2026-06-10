"""identity engine

Revision ID: 0001_identity_engine
Revises:
Create Date: 2026-06-09
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0001_identity_engine"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    user_role = postgresql.ENUM(
        "CUSTOMER", "OWNER", "STAFF", "ADMIN", name="user_role", create_type=False
    )
    business_status = postgresql.ENUM(
        "ACTIVE", "SUSPENDED", name="business_status", create_type=False
    )
    user_role.create(op.get_bind(), checkfirst=True)
    business_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("phone", sa.String(length=32), nullable=True),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("full_name", sa.String(length=120), nullable=False),
        sa.Column("role", user_role, nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_users")),
        sa.UniqueConstraint("email", name=op.f("uq_users_email")),
        sa.UniqueConstraint("phone", name=op.f("uq_users_phone")),
    )
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=False)
    op.create_index(op.f("ix_users_role"), "users", ["role"], unique=False)

    op.create_table(
        "businesses",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("legal_name", sa.String(length=180), nullable=True),
        sa.Column("slug", sa.String(length=180), nullable=False),
        sa.Column("category", sa.String(length=80), nullable=True),
        sa.Column("public_email", sa.String(length=255), nullable=True),
        sa.Column("public_phone", sa.String(length=32), nullable=True),
        sa.Column("website_url", sa.String(length=500), nullable=True),
        sa.Column("address_line1", sa.String(length=180), nullable=True),
        sa.Column("address_line2", sa.String(length=180), nullable=True),
        sa.Column("city", sa.String(length=120), nullable=True),
        sa.Column("region", sa.String(length=120), nullable=True),
        sa.Column("postal_code", sa.String(length=32), nullable=True),
        sa.Column("country_code", sa.String(length=2), nullable=False),
        sa.Column("timezone", sa.String(length=64), nullable=False),
        sa.Column("currency_code", sa.String(length=3), nullable=False),
        sa.Column("status", business_status, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"], name=op.f("fk_businesses_owner_id_users")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_businesses")),
        sa.UniqueConstraint("slug", name=op.f("uq_businesses_slug")),
    )
    op.create_index(op.f("ix_businesses_owner_id"), "businesses", ["owner_id"], unique=False)
    op.create_index(op.f("ix_businesses_slug"), "businesses", ["slug"], unique=False)

    op.create_table(
        "staff_members",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["business_id"], ["businesses.id"], name=op.f("fk_staff_members_business_id_businesses")
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name=op.f("fk_staff_members_user_id_users")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_staff_members")),
        sa.UniqueConstraint("business_id", "user_id", name=op.f("uq_staff_members_business_id")),
    )
    op.create_index(op.f("ix_staff_members_business_id"), "staff_members", ["business_id"], unique=False)
    op.create_index(op.f("ix_staff_members_user_id"), "staff_members", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_staff_members_user_id"), table_name="staff_members")
    op.drop_index(op.f("ix_staff_members_business_id"), table_name="staff_members")
    op.drop_table("staff_members")
    op.drop_index(op.f("ix_businesses_slug"), table_name="businesses")
    op.drop_index(op.f("ix_businesses_owner_id"), table_name="businesses")
    op.drop_table("businesses")
    op.drop_index(op.f("ix_users_role"), table_name="users")
    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.drop_table("users")
    postgresql.ENUM(name="business_status").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="user_role").drop(op.get_bind(), checkfirst=True)
