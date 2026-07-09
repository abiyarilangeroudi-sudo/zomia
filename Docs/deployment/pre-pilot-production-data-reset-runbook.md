# Pre-Pilot Production Data Reset Runbook

Date: 2026-07-09

Status: `Prepared, not executed`

This runbook is for the one-time production data cleanup before onboarding the first real customer.
It is destructive and must only be executed after the project owner explicitly requests the reset for the real private-pilot session.

Do not use this runbook during ordinary development, UI testing, or release deployment.

## Goal

Fully remove production test data and leave production in a clean, migrated state where the first real Business Owner registers through the normal Business Register UI.

The reset must leave no seeded:

- owner accounts;
- customer accounts;
- staff accounts or invitations;
- businesses;
- missions;
- reward templates;
- campaigns;
- loyalty actions;
- rewards;
- QR tokens.

The only expected persistent database content after reset is migration metadata such as `alembic_version`.

## Approval Gate

Before running any destructive command, record:

- Project owner explicit approval.
- Date and time.
- Operator name.
- Current backend release path.
- Current frontend release path.
- Current Git commit if known.
- Reason for reset: `first real-customer private pilot`.

If there is any real customer, business, staff, mission, campaign, reward, or loyalty action data in production, stop and make a separate data-retention decision before continuing.

## Pre-Reset Safety Checks

Confirm:

- `https://zomia.eu/health` returns `{"status":"ok"}`.
- `zomia-backend.service` is active before the maintenance window.
- PostgreSQL is local-only.
- Latest scheduled local backup exists.
- Latest scheduled encrypted off-server backup exists.
- The rollback runbook is available: `Docs/deployment/production-rollback-runbook.md`.
- The backend release at `/opt/zomia/backend/current` is the intended current production release.
- The production env file exists at `/opt/zomia/env/backend.env`.
- The production database is expected to be `zomia` and the application database user is expected to be `zomia_app`.

Do not continue if any of these checks fail.

## Required Pre-Reset Backups

Run the existing production backup scripts from the server:

```bash
sudo /opt/zomia/backend/scripts/backup_postgres.sh
sudo /opt/zomia/backend/scripts/sync_postgres_backup_offsite.sh
```

Then confirm and record:

- New local backup filename under `/var/backups/zomia/postgresql`.
- New encrypted off-server backup filename.
- Backup timestamps.
- Backup sizes.
- Backup log entries in `/var/log/zomia/postgres-backup.log`.
- Off-server upload log entries in `/var/log/zomia/postgres-offsite-backup.log`.

Do not reset production data until both the local backup and encrypted off-server backup are confirmed.

## Maintenance Window

Stop the backend before changing database state:

```bash
sudo systemctl stop zomia-backend.service
sudo systemctl is-active zomia-backend.service
```

Expected result:

```text
inactive
```

If the service does not stop cleanly, stop and investigate before touching the database.

## Reset Database Schema

Confirm the database name and application user from the protected production env file before running this step.

For the current private-pilot production database shape, reset the public schema:

```bash
sudo -u postgres psql -d zomia -v ON_ERROR_STOP=1 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public AUTHORIZATION zomia_app; GRANT USAGE, CREATE ON SCHEMA public TO zomia_app;"
```

This command is intentionally destructive. It removes production test data by dropping the application schema.

Do not run this command if:

- the target database is not confirmed as production `zomia`;
- pre-reset backups are missing;
- there is any real user data that must be preserved;
- the project owner did not explicitly approve the reset.

## Recreate Schema With Migrations

Run Alembic from the active backend release with the production env loaded:

```bash
sudo -u zomia bash -lc 'set -a; source /opt/zomia/env/backend.env; set +a; cd /opt/zomia/backend/current; .venv/bin/alembic upgrade head'
sudo -u zomia bash -lc 'set -a; source /opt/zomia/env/backend.env; set +a; cd /opt/zomia/backend/current; .venv/bin/alembic current'
```

Expected:

- `alembic upgrade head` completes without errors.
- `alembic current` reports the current head revision.

## Empty-State Verification

Verify that application tables contain no business data:

```bash
sudo -u postgres psql -d zomia -v ON_ERROR_STOP=1 -c "
SELECT 'users' AS table_name, count(*) FROM users
UNION ALL SELECT 'businesses', count(*) FROM businesses
UNION ALL SELECT 'staff_members', count(*) FROM staff_members
UNION ALL SELECT 'staff_invitations', count(*) FROM staff_invitations
UNION ALL SELECT 'missions', count(*) FROM missions
UNION ALL SELECT 'reward_templates', count(*) FROM reward_templates
UNION ALL SELECT 'campaigns', count(*) FROM campaigns
UNION ALL SELECT 'loyalty_actions', count(*) FROM loyalty_actions
UNION ALL SELECT 'generated_rewards', count(*) FROM generated_rewards
UNION ALL SELECT 'reward_usages', count(*) FROM reward_usages
UNION ALL SELECT 'customer_qr_tokens', count(*) FROM customer_qr_tokens;
"
```

Expected result:

- Every listed table returns `0`.

If any listed table returns a non-zero count, do not continue to onboarding.

## Restart Backend

Start the backend only after migration and empty-state checks pass:

```bash
sudo systemctl start zomia-backend.service
sudo systemctl status zomia-backend.service --no-pager
```

Then check:

```bash
curl -fsS https://zomia.eu/health
```

Expected response:

```json
{"status":"ok"}
```

## Post-Reset Smoke Checks

Run the repeatable production smoke check from the local repository:

```bash
make production-smoke
```

Also manually confirm:

- `https://zomia.eu/webapp/` opens.
- Login page shows the expected current version.
- Business registration screen opens.
- Customer registration screen opens.
- Staff invitation acceptance route is reachable only through a real invitation link later.
- `/docs`, `/redoc`, and `/openapi.json` still return `404` in production.

Do not create test accounts after the reset.

## Post-Reset Baseline Backups

After the clean state and smoke checks pass, create a fresh baseline backup pair:

```bash
sudo /opt/zomia/backend/scripts/backup_postgres.sh
sudo /opt/zomia/backend/scripts/sync_postgres_backup_offsite.sh
```

Record:

- Post-reset local baseline backup filename.
- Post-reset encrypted off-server baseline backup filename.
- Backup timestamps and sizes.
- Smoke-check result.
- Health-check result.
- Alembic current revision.

## Operations Checklist Entry Template

Add an entry to `Docs/deployment/production-operations-checklist.md`:

```text
## YYYY-MM-DD Pre-Pilot Production Data Reset

- Project owner approval: yes, requested at <timestamp>.
- Goal: remove production test data before first real-customer private pilot.
- Backend release before reset: <path>.
- Frontend release before reset: <path>.
- Pre-reset local backup: <filename>.
- Pre-reset encrypted off-server backup: <filename>.
- Backend stopped before reset: yes.
- Schema reset completed: yes.
- Alembic current after reset: <revision>.
- Empty-state verification: passed.
- Backend health after restart: ok.
- Production smoke check: passed.
- Post-reset local baseline backup: <filename>.
- Post-reset encrypted off-server baseline backup: <filename>.
- No seeded accounts after reset: confirmed.
- First real Owner must register through Business Register UI.
```

## Stop Conditions

Stop immediately if:

- Pre-reset backup or off-server upload fails.
- The target database or app user does not match the expected production values.
- Backend cannot be stopped cleanly.
- Schema reset or migration fails.
- Empty-state verification returns non-zero rows.
- Backend health does not recover after restart.
- Production smoke checks fail.
- Logs show repeated new backend or database errors.

If a stop condition occurs after the destructive reset, use the database restore section of `Docs/deployment/production-rollback-runbook.md`.

## Explicit Non-Goals

This runbook must not:

- seed demo data;
- create the first owner manually;
- create a business manually;
- bypass email verification;
- bypass staff invitation acceptance;
- change backend or frontend code;
- deploy a new release;
- replace the first private-pilot onboarding plan.
