"""loyalty foundation

Revision ID: 0002_loyalty_foundation
Revises: 0001_identity_engine
Create Date: 2026-06-10
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0002_loyalty_foundation"
down_revision: str | None = "0001_identity_engine"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    mission_type = postgresql.ENUM(
        "purchase", "visit", "referral", "custom", name="mission_type", create_type=False
    )
    loyalty_action_type = postgresql.ENUM(
        "mission_progress",
        "reward_use",
        "service_operation",
        name="loyalty_action_type",
        create_type=False,
    )
    audit_event_type = postgresql.ENUM(
        "mission_created",
        "action_recorded",
        "points_granted",
        "idempotency_replayed",
        name="audit_event_type",
        create_type=False,
    )
    mission_type.create(op.get_bind(), checkfirst=True)
    loyalty_action_type.create(op.get_bind(), checkfirst=True)
    audit_event_type.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "missions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("description", sa.String(length=500), nullable=True),
        sa.Column("mission_type", mission_type, nullable=False),
        sa.Column("point_value", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("point_value > 0", name=op.f("ck_missions_mission_point_value_positive")),
        sa.ForeignKeyConstraint(
            ["business_id"], ["businesses.id"], name=op.f("fk_missions_business_id_businesses")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_missions")),
    )
    op.create_index(op.f("ix_missions_business_id"), "missions", ["business_id"], unique=False)
    op.create_index(op.f("ix_missions_mission_type"), "missions", ["mission_type"], unique=False)

    op.create_table(
        "loyalty_actions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("customer_id", sa.Uuid(), nullable=False),
        sa.Column("staff_id", sa.Uuid(), nullable=False),
        sa.Column("action_type", loyalty_action_type, nullable=False),
        sa.Column("idempotency_key", sa.String(length=120), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("note", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["business_id"], ["businesses.id"], name=op.f("fk_loyalty_actions_business_id_businesses")
        ),
        sa.ForeignKeyConstraint(
            ["customer_id"], ["users.id"], name=op.f("fk_loyalty_actions_customer_id_users")
        ),
        sa.ForeignKeyConstraint(["staff_id"], ["users.id"], name=op.f("fk_loyalty_actions_staff_id_users")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_loyalty_actions")),
        sa.UniqueConstraint("business_id", "idempotency_key", name=op.f("uq_loyalty_actions_business_id")),
    )
    op.create_index(op.f("ix_loyalty_actions_business_id"), "loyalty_actions", ["business_id"], unique=False)
    op.create_index(op.f("ix_loyalty_actions_customer_id"), "loyalty_actions", ["customer_id"], unique=False)
    op.create_index(op.f("ix_loyalty_actions_staff_id"), "loyalty_actions", ["staff_id"], unique=False)

    op.create_table(
        "loyalty_action_items",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("action_id", sa.Uuid(), nullable=False),
        sa.Column("mission_id", sa.Uuid(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("unit_points", sa.Integer(), nullable=False),
        sa.Column("total_points", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "quantity > 0", name=op.f("ck_loyalty_action_items_loyalty_action_item_quantity_positive")
        ),
        sa.CheckConstraint(
            "unit_points > 0", name=op.f("ck_loyalty_action_items_loyalty_action_item_unit_points_positive")
        ),
        sa.CheckConstraint(
            "total_points > 0", name=op.f("ck_loyalty_action_items_loyalty_action_item_total_points_positive")
        ),
        sa.ForeignKeyConstraint(
            ["action_id"],
            ["loyalty_actions.id"],
            name=op.f("fk_loyalty_action_items_action_id_loyalty_actions"),
        ),
        sa.ForeignKeyConstraint(
            ["mission_id"], ["missions.id"], name=op.f("fk_loyalty_action_items_mission_id_missions")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_loyalty_action_items")),
    )
    op.create_index(
        op.f("ix_loyalty_action_items_action_id"), "loyalty_action_items", ["action_id"], unique=False
    )
    op.create_index(
        op.f("ix_loyalty_action_items_mission_id"), "loyalty_action_items", ["mission_id"], unique=False
    )

    op.create_table(
        "points_ledger",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("customer_id", sa.Uuid(), nullable=False),
        sa.Column("action_id", sa.Uuid(), nullable=False),
        sa.Column("action_item_id", sa.Uuid(), nullable=False),
        sa.Column("points", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(length=120), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("points > 0", name=op.f("ck_points_ledger_points_ledger_points_positive")),
        sa.ForeignKeyConstraint(
            ["action_id"], ["loyalty_actions.id"], name=op.f("fk_points_ledger_action_id_loyalty_actions")
        ),
        sa.ForeignKeyConstraint(
            ["action_item_id"],
            ["loyalty_action_items.id"],
            name=op.f("fk_points_ledger_action_item_id_loyalty_action_items"),
        ),
        sa.ForeignKeyConstraint(
            ["business_id"], ["businesses.id"], name=op.f("fk_points_ledger_business_id_businesses")
        ),
        sa.ForeignKeyConstraint(
            ["customer_id"], ["users.id"], name=op.f("fk_points_ledger_customer_id_users")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_points_ledger")),
    )
    op.create_index(op.f("ix_points_ledger_action_id"), "points_ledger", ["action_id"], unique=False)
    op.create_index(
        op.f("ix_points_ledger_action_item_id"), "points_ledger", ["action_item_id"], unique=False
    )
    op.create_index(op.f("ix_points_ledger_business_id"), "points_ledger", ["business_id"], unique=False)
    op.create_index(op.f("ix_points_ledger_customer_id"), "points_ledger", ["customer_id"], unique=False)

    op.create_table(
        "audit_events",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("event_type", audit_event_type, nullable=False),
        sa.Column("actor_user_id", sa.Uuid(), nullable=True),
        sa.Column("business_id", sa.Uuid(), nullable=True),
        sa.Column("entity_type", sa.String(length=80), nullable=False),
        sa.Column("entity_id", sa.Uuid(), nullable=False),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["actor_user_id"], ["users.id"], name=op.f("fk_audit_events_actor_user_id_users")
        ),
        sa.ForeignKeyConstraint(
            ["business_id"], ["businesses.id"], name=op.f("fk_audit_events_business_id_businesses")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_audit_events")),
    )
    op.create_index(op.f("ix_audit_events_business_id"), "audit_events", ["business_id"], unique=False)
    op.create_index(op.f("ix_audit_events_entity_id"), "audit_events", ["entity_id"], unique=False)
    op.create_index(op.f("ix_audit_events_event_type"), "audit_events", ["event_type"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_audit_events_event_type"), table_name="audit_events")
    op.drop_index(op.f("ix_audit_events_entity_id"), table_name="audit_events")
    op.drop_index(op.f("ix_audit_events_business_id"), table_name="audit_events")
    op.drop_table("audit_events")
    op.drop_index(op.f("ix_points_ledger_customer_id"), table_name="points_ledger")
    op.drop_index(op.f("ix_points_ledger_business_id"), table_name="points_ledger")
    op.drop_index(op.f("ix_points_ledger_action_item_id"), table_name="points_ledger")
    op.drop_index(op.f("ix_points_ledger_action_id"), table_name="points_ledger")
    op.drop_table("points_ledger")
    op.drop_index(op.f("ix_loyalty_action_items_mission_id"), table_name="loyalty_action_items")
    op.drop_index(op.f("ix_loyalty_action_items_action_id"), table_name="loyalty_action_items")
    op.drop_table("loyalty_action_items")
    op.drop_index(op.f("ix_loyalty_actions_staff_id"), table_name="loyalty_actions")
    op.drop_index(op.f("ix_loyalty_actions_customer_id"), table_name="loyalty_actions")
    op.drop_index(op.f("ix_loyalty_actions_business_id"), table_name="loyalty_actions")
    op.drop_table("loyalty_actions")
    op.drop_index(op.f("ix_missions_mission_type"), table_name="missions")
    op.drop_index(op.f("ix_missions_business_id"), table_name="missions")
    op.drop_table("missions")
    postgresql.ENUM(name="audit_event_type").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="loyalty_action_type").drop(op.get_bind(), checkfirst=True)
    postgresql.ENUM(name="mission_type").drop(op.get_bind(), checkfirst=True)

