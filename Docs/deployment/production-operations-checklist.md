# Production Operations Checklist

Date: 2026-06-27

This checklist tracks the current private-pilot production operation for Zomia.
It is for day-to-day release, rollback, backup, and verification work after the first deployment.

## Current Production Shape

- Domain: `https://zomia.eu`
- Web app: `https://zomia.eu/webapp/`
- API base path: `https://zomia.eu/api/v1`
- Health check: `https://zomia.eu/health`
- Frontend releases: `/var/www/zomia/releases/`
- Active web app symlink: `/var/www/zomia/webapp`
- Root landing placeholder: `/var/www/zomia/root/index.html`
- Backend releases: `/opt/zomia/backend/releases/`
- Backend service: `zomia-backend.service`
- Backend bind address: `127.0.0.1:8000`
- PostgreSQL: same-server private-pilot database, localhost-only

## Frontend Release Procedure

Before release:

- Confirm worktree is clean or intentionally contains only the release change.
- Confirm `frontend/pubspec.yaml` version was bumped for a Flutter change.
- Build with `scripts/build_frontend_production.sh`.
- Confirm the generated Login version label matches the target version.
- Confirm generated source-map references are not present in production web files.

Release:

- Create a new directory under `/var/www/zomia/releases/<release-id>`.
- Copy `frontend/build/web/` into the new release directory.
- Switch `/var/www/zomia/webapp` to the new release.
- Keep at least the previous release available for rollback.

Rollback:

- Point `/var/www/zomia/webapp` back to the previous known-good release.
- Verify `https://zomia.eu/webapp/?v=<cache-buster>` opens.
- Verify the Login version label changed back to the expected version.
- Follow the detailed rollback steps in `Docs/deployment/production-rollback-runbook.md`.

## Backend Release Procedure

Before release:

- Confirm backend tests pass locally or in CI.
- Review Alembic migration impact.
- Take a database backup before any production migration.
- Confirm the target Git revision or release id.

Release:

- Publish backend code into a new backend release directory.
- Install/update the backend virtual environment for that release.
- Run `alembic current`.
- Run `alembic upgrade head` only after backup is confirmed.
- Restart `zomia-backend.service`.
- Check `https://zomia.eu/health`.

Rollback:

- Roll back the backend symlink/service target to the previous known-good release.
- Restart `zomia-backend.service`.
- Decide separately whether database restore is required. Do not assume app rollback is enough after schema/data migrations.
- Follow the detailed rollback steps in `Docs/deployment/production-rollback-runbook.md`.

## Database Operations

Current private-pilot direction:

- PostgreSQL runs on the same server.
- PostgreSQL must remain localhost-only.
- Daily backups are required.
- Restore has been tested once and must be re-tested after meaningful backup changes.

Rules:

- Do not run production migrations without a fresh backup.
- Do not store backups under the public web root.
- Do not expose port `5432` publicly.
- Keep backup retention documented.
- Test restore periodically, not only when something breaks.
- Repeat restore tests after meaningful database migrations, after backup changes, at least monthly during the private pilot, and before onboarding a new real business.
- Same-server backups remain available, but encrypted off-server backups are now active and must also be monitored.

Latest backup verification:

- Date checked: 2026-06-27.
- Backup directory: `/var/backups/zomia/postgresql`.
- Latest backup observed: `zomia-20260627-031501.dump`.
- Latest backup size observed: about `96K`.
- Previous scheduled backup observed: `zomia-20260626-031501.dump`.
- Backup schedule: daily at `03:15 Europe/Berlin`.
- Retention: `14` days.
- Backup log: `/var/log/zomia/postgres-backup.log`.
- Cron service was active and enabled at the time of review.
- PostgreSQL was listening only on `127.0.0.1:5432` and `[::1]:5432`.
- Restore test was previously completed during server hardening; no new restore test was run during this review.

Off-server backup destination:

- Date selected: 2026-06-27.
- Provider: Hetzner Storage Box.
- Server: `u623378.your-storagebox.de`.
- Username: `u623378`.
- Location: Germany / EU.
- Production server automated encrypted upload is enabled.
- Off-server upload script: `/opt/zomia/backend/scripts/sync_postgres_backup_offsite.sh`.
- Off-server cron: `/etc/cron.d/zomia-postgres-offsite-backup`.
- Off-server schedule: daily at `03:30 Europe/Berlin`, after the local `03:15` PostgreSQL backup.
- Off-server log: `/var/log/zomia/postgres-offsite-backup.log`.
- Off-server backup env/passphrase files are stored outside Git under `/opt/zomia/env/`.
- Latest manual encrypted off-server upload tested: `zomia-20260627-031501.dump.gpg`.
- Restore from the encrypted off-server copy passed on 2026-06-27 using a temporary database.
- Next backup hardening step: confirm the first scheduled off-server cron run after the next `03:30 Europe/Berlin` cycle.

## Secrets And Environment

- Production secrets must not be committed.
- `.env`, SMTP credentials, JWT secrets, database credentials, and backup credentials must stay outside Git.
- Current protected env location: `/opt/zomia/env/`.
- `OTP_TEST_CODE` must not be set in production.
- SMTP sender identity must remain aligned with SPF, DKIM, and DMARC.
- Rotate secrets if they are pasted into chat, logs, screenshots, or Git by mistake.

## Nginx And TLS

Nginx must:

- Serve `/webapp/` from `/var/www/zomia/webapp`.
- Serve `/` from the root placeholder directory.
- Serve public legal draft pages under `/legal`.
- Proxy `/api/` and `/health` to the backend.
- Keep sensitive-path blocking before frontend fallback handling.
- Return `404` for missing source-map files instead of serving Flutter `index.html`.

TLS:

- HTTPS must stay active for `zomia.eu` and `www.zomia.eu`.
- Certbot renewal must be checked periodically.
- Customer registration and login must never be exposed only over plain HTTP.

## Post-Release Check

After each release, check:

- `https://zomia.eu/webapp/` opens.
- Login page shows the expected version.
- `https://zomia.eu/legal` returns `200` and `text/html`.
- `https://zomia.eu/legal/privacy` returns `200` and `text/html`.
- `https://zomia.eu/health` returns `{"status":"ok"}`.
- `https://zomia.eu/api/v1/...` paths reach the backend.
- `https://zomia.eu/docs`, `/redoc`, and `/openapi.json` return `404`.
- Rate-limited routes still allow normal user flows; repeated fast protected requests can return `429`.
- Source-map requests return `404` without breaking the app.
- Browser console has no unexpected `4xx` or `5xx` errors during the changed flow.
- Nginx and backend logs do not show repeated new errors.

Run role smoke tests only when the release risk requires it:

- Customer login and QR dialog.
- Staff login, QR resolve, and action registration.
- Owner login and create dialogs.

## Rollback Reference

Detailed rollback rules and incident notes live in:

- `Docs/deployment/production-rollback-runbook.md`

Short rule:

- Use frontend rollback for frontend/UI/static asset issues.
- Use backend rollback for API/service issues.
- Use database restore only for data corruption, destructive data mistakes, or incompatible migration state.
- Always record whether a migration ran before choosing the rollback path.

## Logs To Check

- Backend: `zomia-backend.service` journal logs.
- Nginx access log.
- Nginx error log.
- PostgreSQL logs.
- Backup cron logs or cron/system mail if configured.

## Current Risk Items

- Same-server PostgreSQL is acceptable for the private pilot only while backup/restore remains reliable.
- Monitoring and alerting are still manual/minimal.
- Backup log permissions should be tightened in a later hardening pass; the log currently contains backup filenames, sizes, and retention output, not secrets.
- Legal pages are draft pages and need final provider/legal review.
- Production email deliverability must keep SPF, DKIM, and DMARC healthy.
- Access-token invalidation after password changes is documented as a later hardening item.
- GitHub Actions deployment is not finalized; current release process is still manual.

Open production decisions are tracked in:

- `Docs/deployment/production-open-decisions.md`
