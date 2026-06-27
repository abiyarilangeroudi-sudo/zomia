# Production Rollback Runbook

Date: 2026-06-27

This runbook explains how to roll back the private-pilot Zomia deployment when a release breaks production.

It is intentionally conservative. Do not use database restore as the first reaction unless the database itself was damaged or a migration must be reversed.
Treat this as an operator checklist. Verify the active release paths on the server before changing symlinks or restoring data.

## Current Production Shape

- Web app: `https://zomia.eu/webapp/`
- API base: `https://zomia.eu/api/v1`
- Health check: `https://zomia.eu/health`
- Frontend releases: `/var/www/zomia/releases/`
- Active frontend symlink: `/var/www/zomia/webapp`
- Backend releases: `/opt/zomia/backend/releases/`
- Backend service: `zomia-backend.service`
- Production env: `/opt/zomia/env/backend.env`
- PostgreSQL backups: `/var/backups/zomia/postgresql`
- PostgreSQL backup log: `/var/log/zomia/postgres-backup.log`

## Rollback Decision Rule

### Frontend-only rollback

Use this when:

- The issue is visual/UI-only.
- The app fails to load because of built web assets.
- A Flutter route, button, dialog, or client-side API call is broken.
- Backend health is OK and no database migration was part of the release.

Expected action:

- Switch `/var/www/zomia/webapp` back to the previous known-good frontend release.
- No backend restart is required unless Nginx config changed.
- No database restore is required.

### Backend rollback

Use this when:

- API behavior is broken.
- Backend service fails to start.
- Logs show new backend exceptions after a release.
- The release did not require an irreversible database migration.

Expected action:

- Switch the backend service target back to the previous known-good backend release.
- Restart `zomia-backend.service`.
- Keep the current database unless the migration/data state is proven unsafe.

### Database restore

Use this only when:

- A migration corrupted data.
- A destructive script changed production data incorrectly.
- The app cannot safely run against the current database state.
- The team explicitly accepts losing data created after the selected backup.

Expected action:

- Stop the backend first.
- Restore a known backup.
- Restart the backend only after restore verification.
- Record the data-loss window.

Do not restore the database only to fix a UI issue.
Do not restore the database only because a backend release has a bug.

## Before Any Rollback

Record:

- Current time.
- Current frontend symlink target.
- Current backend release target.
- Current Git commit or release id, if known.
- Whether a database migration ran.
- Whether new customer/business data was created after the release.
- The exact user-visible failure.

Check:

- `https://zomia.eu/health`
- Backend service status.
- Nginx error log.
- Backend journal log.

## Frontend Rollback Steps

1. List available frontend releases under `/var/www/zomia/releases/`.
2. Identify the previous known-good release.
3. Switch `/var/www/zomia/webapp` to that release.
4. Confirm Nginx can read the target release.
5. Open `https://zomia.eu/webapp/?v=rollback-check`.
6. Confirm the Login version label matches the expected previous version.
7. Run a short browser smoke check for the broken flow.

Post-check:

- `https://zomia.eu/webapp/` opens.
- `https://zomia.eu/webapp/main.dart.js` returns `200`.
- `https://zomia.eu/health` still returns `{"status":"ok"}`.
- Browser console has no new unexpected `4xx` or `5xx` errors for the checked flow.

## Backend Rollback Steps

1. Confirm which backend release is currently active.
2. Identify the previous known-good backend release.
3. Confirm whether the bad release ran migrations.
4. If migrations ran, decide whether app rollback alone is compatible with the current schema.
5. Switch the backend service target to the previous release.
6. Restart `zomia-backend.service`.
7. Check `https://zomia.eu/health`.
8. Check backend logs for startup errors.
9. Run one authenticated smoke flow if auth or loyalty APIs were affected.

Post-check:

- `zomia-backend.service` is active.
- Backend listens only on `127.0.0.1:8000`.
- `https://zomia.eu/health` returns `{"status":"ok"}`.
- A known API request reaches the backend through Nginx.

## Database Restore Steps

Use only after the database restore decision is explicitly made.

Required approval note:

- The operator must write down why restore is necessary.
- The operator must write down which data may be lost.
- If the issue can be fixed by frontend or backend rollback, do not restore the database.

Before restore:

- Confirm the selected backup file.
- Confirm the backup timestamp.
- Estimate data that will be lost after that timestamp.
- Stop `zomia-backend.service`.
- Take a final emergency backup of the current broken database state if possible.

Restore:

1. Restore the selected PostgreSQL backup into the production database.
2. Confirm restore completed without errors.
3. Run a minimal database connectivity check.
4. Start `zomia-backend.service`.
5. Check `https://zomia.eu/health`.
6. Run focused smoke tests for login and the affected role flow.

After restore:

- Record backup filename.
- Record restore start/end time.
- Record data-loss window.
- Record reason restore was necessary.

## Smoke Tests After Rollback

Always:

- Web app opens at `https://zomia.eu/webapp/`.
- Login page shows the expected version.
- Health endpoint returns OK.
- Nginx does not show repeated new errors.
- Backend logs do not show repeated new exceptions.

If auth changed:

- Customer login.
- Owner login.
- Staff login.
- Sign out.

If loyalty changed:

- Customer QR opens.
- Staff resolves QR.
- Staff registers one action.
- Customer progress/reward state updates as expected.

If legal/static routing changed:

- `https://zomia.eu/legal` returns `200` and `text/html`.
- Legal links from registration or Drawer open outside the web app.

## What To Avoid

- Do not delete old releases during an incident.
- Do not run a second migration while investigating a broken first migration.
- Do not overwrite backups.
- Do not use database restore as a normal deploy rollback.
- Do not hide the incident only by changing UI text if backend data is wrong.

## Incident Note Template

```text
Date/time:
Detected by:
Broken release:
Rollback type: frontend / backend / database
Previous known-good release:
Database migration ran: yes / no
Database restored: yes / no
Backup used:
Data-loss window:
User-visible issue:
Root cause:
Follow-up:
```
