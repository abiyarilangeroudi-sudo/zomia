# Production Open Decisions

Date: 2026-06-28

This document tracks decisions that must stay visible during the private-pilot production phase.

The goal is to avoid accidental production hardening by guesswork. Each item has a current MVP direction and a later hardening decision.

## Decision Status Legend

- `Accepted for private pilot`: good enough for the controlled pilot, but not necessarily final.
- `Needs decision before broader launch`: must be decided before public launch or wider onboarding.
- `Later hardening`: not blocking the private pilot, but should not be forgotten.

## 1. OpenAPI Exposure

Status: `Accepted for private pilot`

Current private-pilot direction:

- Keep API behavior stable.
- Do not expose FastAPI Swagger/ReDoc/OpenAPI from the production backend.
- Local and non-production environments may keep FastAPI docs available as developer/operator tooling.
- Public product UI must not depend on OpenAPI visibility.

Decision:

- `APP_ENV=production` disables `/docs`, `/redoc`, and `/openapi.json` inside FastAPI.
- Production Nginx explicitly returns `404` for `/docs`, `/redoc`, and `/openapi.json`.
- If developer docs are needed later, expose them behind an admin-only or VPN-only boundary.

Why it matters:

- Public docs can help debugging, but they also expose endpoint structure.
- Security does not rely on obscurity, but unnecessary public surface should still be minimized.

## 2. Rate Limiting

Status: `Applied for private pilot`

Current private-pilot direction:

- Use conservative Nginx IP-based limits for public and abuse-sensitive routes.
- Keep backend authorization, OTP validation, refresh-token rotation, QR validation, idempotency, and reward status checks as the source of truth.
- Use Nginx as the first private-pilot shield, not as the final scaled abuse-prevention model.
- Detailed route groups are tracked in `Docs/deployment/rate-limiting-plan.md`.
- Production Nginx currently applies `auth_strict`, `token_moderate`, `service_moderate`, and `owner_write_moderate` zones.

Must cover before broader launch:

- Login.
- Refresh token replay patterns.
- Registration start/OTP verify.
- Password recovery start/verify/reset.
- Email change start/verify.
- Staff invitation accept.
- QR resolve.
- Reward use.
- Action registration.

Decision:

- Private pilot: Nginx IP-based limits.
- Later hardening: Redis-backed or application-level limiter if account/email/business-aware limits are needed.

Current boundary:

- Nginx limits are active for private pilot.
- Manual QA for normal protected flows should be repeated after any future limit change.
- Broader launch still needs a decision on whether IP-based limits are enough or whether account/email/business-aware limits are required.

## 3. Monitoring And Alerting

Status: `Minimum private-pilot monitoring active; external uptime monitor active; backend Sentry active; heartbeat hook prepared`

Current private-pilot direction:

- Manual checks are still acceptable for the current controlled pilot.
- A local production health-check script is active:
  - Script: `/opt/zomia/backend/scripts/check_production_health.sh`.
  - Cron: `/etc/cron.d/zomia-production-health-check`.
  - Schedule: hourly at minute `10`.
  - Log: `/var/log/zomia/production-health-check.log`.
  - Optional heartbeat env: `/opt/zomia/env/monitoring.env`.
- The health check verifies:
  - `https://zomia.eu/health`;
  - `nginx`, `postgresql`, and `zomia-backend.service`;
  - local PostgreSQL backup freshness;
  - encrypted off-server backup log freshness;
  - encrypted off-server file presence for the latest local backup;
  - root disk usage.
- A vendor-neutral external heartbeat hook is prepared:
  - If `MONITORING_HEARTBEAT_URL` is empty, the health check logs `monitoring_heartbeat not_configured` and stays green when all local checks pass.
  - If `MONITORING_HEARTBEAT_URL` is configured, the heartbeat is sent only after all local checks pass.
  - If the heartbeat send fails, the local health-check log records `monitoring_heartbeat send_failed`.
- An external uptime monitor for `https://zomia.eu/health` is active through UptimeRobot.
  - Public status page: `https://stats.uptimerobot.com/nxgv77u55I`.
  - Alert recipient: `info@zomia.eu`.
  - `/health` supports both `GET` and `HEAD`.
- Heartbeat alert delivery is not enabled yet because no heartbeat URL has been configured.
- Backend Sentry support is active with `SENTRY_DSN` configured in the protected backend env file.
  - Tracing should stay disabled for the private pilot with `SENTRY_TRACES_SAMPLE_RATE=0.0`.
  - Sentry must not collect passwords, OTPs, tokens, QR tokens, SMTP secrets, database URLs, email bodies, or other sensitive values.
  - Production smoke event sent successfully on 2026-07-01.
- Operators still check Nginx logs, backend journal logs, PostgreSQL logs, backup logs, and the production health-check log.

Needs decision before broader launch:

- Optional heartbeat URL for local server, backup, and disk checks.
- Decide whether frontend Sentry is needed after backend Sentry is verified.
- Backup failure alerting outside the server.
- Disk-space monitoring.
- TLS renewal monitoring.

Open decision:

- Define who receives alerts.
- Define what counts as an incident.
- Decide whether to add a heartbeat monitor later for local server checks.

## 4. Backup Restore Cadence

Status: `Accepted for private pilot; encrypted off-server sync active`

Current private-pilot direction:

- Daily PostgreSQL backups run at `03:15 Europe/Berlin`.
- Retention is `14` days.
- Restore was tested once during server hardening.
- Database restore is treated as a last-resort recovery action, not a normal app rollback.
- Restore tests must be repeated:
  - after every meaningful database/schema migration;
  - after any backup script, backup path, or storage destination change;
  - at least monthly during the private pilot;
  - before onboarding a new real business.
- A fresh production backup is required before every production migration.
- Off-server backup destination is selected:
  - Provider: Hetzner Storage Box.
  - Server: `u623378.your-storagebox.de`.
  - Username: `u623378`.
  - Location: Germany / EU.
- Encrypted off-server upload from the production server is active.
- Off-server upload script: `/opt/zomia/backend/scripts/sync_postgres_backup_offsite.sh`.
- Off-server env/passphrase files are stored outside Git under `/opt/zomia/env/`.
- Off-server cron schedule is daily at `03:30 Europe/Berlin`, after the local `03:15` PostgreSQL backup.
- Restore from the encrypted off-server copy was tested successfully on 2026-06-27 using a temporary database.

Needs decision before broader launch:

- Define off-server retention separately from local `14` day retention if needed.
- Whether point-in-time recovery is required.
- Whether managed PostgreSQL should replace same-server PostgreSQL.

Recommended next checkpoint:

- First scheduled off-server cron run was confirmed on 2026-06-28.
- Repeat restore tests on the defined cadence.

## 5. Legal Draft Review

Status: `Accepted for private pilot; legal review required before broader launch`

Current private-pilot direction:

- Legal pages exist under `https://zomia.eu/legal/...`.
- Registration links and Drawer Legal links open those public pages outside the Flutter web app.
- The pages now contain minimum private-pilot draft text instead of one-line placeholders.
- Privacy Draft Pass 2 aligns the Privacy Policy with current Customer, Owner, Staff, QR, loyalty, browser storage, transactional email, and account removal behavior.
- Terms, Business Terms, Cookie Policy, and Impressum were updated for the current private-pilot shape.
- The Impressum now includes provider details for Bellis Prennis; VAT/register/dispute wording still needs final review if the legal/business setup changes.
- Legal pages passed a final private-pilot consistency pass on 2026-06-27.
- Legal Text Finalization Pass 1 was completed and deployed on 2026-06-28.
- Draft source and review notes are tracked in `Docs/legal/legal-draft-review-notes.md`.

Open decision:

- Review or replace the draft legal content before broader onboarding, or explicitly record that the private pilot accepts legal-text risk.
- Confirm controller/processor model, AVV/DPA needs, retention wording, staff privacy notice, and discount-transparency wording.

Must cover:

- Privacy Policy / GDPR.
- Terms and Conditions.
- Business Terms.
- Cookie Policy / local storage notice.
- Impressum.
- Double opt-in policy for marketing or promotional notifications.
- Account removal / right to erasure wording.
- Discount/reward transparency.

## 6. GitHub Actions Vs Manual Deploy

Status: `Accepted for private pilot; CI-only workflow added`

Current private-pilot direction:

- Manual deploy remains acceptable while release frequency is low and operator attention is high.
- For the current private pilot, production deployment stays manual.
- GitHub Actions is introduced as CI/verification only, not as production deployment.
- CI runs backend lint/tests, migration upgrade against an ephemeral PostgreSQL service, frontend analyze/tests, and production web build.
- CI does not require Alembic offline SQL generation because the existing migration history includes data-dependent migrations that are safer to verify against a real temporary database.
- CI has no production secrets and does not connect to the production server.
- Database migrations remain manual for now.
- A fresh backup, smoke test, and log check remain mandatory around production migrations/releases.
- Each release must keep a previous known-good frontend/backend release available.
- Rollback rules are documented in `Docs/deployment/production-rollback-runbook.md`.
- Production SSH deploy automation should wait until multiple manual releases are boring and repeatable.

Needs decision before broader launch:

- When to allow GitHub Actions to deploy production artifacts.
- Whether deployment requires manual approval. The expected answer is yes for the next phase.
- Whether production deploys are tag-based, main-branch based, or release-branch based.
- Where deployment logs and release notes are stored.

Recommended boundary:

- Next phase: add GitHub Actions CI only.
- Later phase: allow GitHub Actions production deploy only with manual approval.
- Do not automate SSH deployment or database migration until rollback, backup, secrets, and smoke checks are boring and repeatable.

## 7. Token Storage And Session Hardening

Status: `Access-token invalidation active in production; cookie/session storage later hardening`

Current private-pilot direction:

- Flutter Web uses browser storage for MVP production sessions because secure storage blocked web startup.
- Access tokens are short-lived.
- Refresh tokens are rotating opaque tokens stored hashed server-side.
- Users have a `session_version` in the application schema.
- Access tokens include `session_version`.
- Protected endpoints reject access tokens when the token `session_version` no longer matches the current user.
- Password recovery completion, password change, and customer account removal increment `session_version` and revoke refresh tokens.
- Email change does not increment `session_version` and does not revoke refresh tokens by design.
- Production deployment completed on 2026-06-28 with migration `0012_user_session_version`.
- A fresh local backup and encrypted off-server backup were taken before migration.
- Production smoke checks passed after restart.
- Manual production QA confirmed that an old session is rejected after a password change and the user is returned to Login with a session-expired message.
- Existing sessions from before this release may need a refresh or sign-in once because older tokens do not carry `session_version`.

Needs decision before hardened production:

- Keep localStorage only as controlled MVP fallback, or move refresh tokens to HttpOnly Secure cookies.
- Decide whether to add a user-visible device/session list with per-device revoke.

## 8. Managed Database Migration

Status: `Accepted for private pilot; later hardening before scale`

Current private-pilot direction:

- Same-server PostgreSQL is accepted only for the private pilot while backups and restore remain reliable.
- This is an explicit cost/simplicity decision for early real-customer validation, not the final scaled database architecture.
- Production PostgreSQL must remain localhost-only.
- Daily local backups, encrypted off-server backups, and periodic restore tests are mandatory while this decision is active.
- A fresh local and encrypted off-server backup is required before every meaningful production migration.
- App rollback and database restore remain separate decisions; database restore is only for data corruption, destructive data mistakes, or incompatible migration state.

Current accepted boundary:

- Controlled private pilot.
- Limited number of real businesses and customers.
- Short maintenance/downtime windows are still operationally acceptable.
- Backup, off-server sync, and restore cadence continue to pass.

Needs decision before scale:

- Choose managed PostgreSQL provider/location in EU/Germany.
- Test migration from same-server PostgreSQL to managed PostgreSQL.
- Decide backup/PITR requirements.

Migration triggers:

- Multiple active real businesses depend on the system daily.
- Downtime becomes commercially or reputationally unacceptable.
- Point-in-time recovery is required.
- Backup, off-server sync, or restore reliability becomes questionable.
- App and database resource usage start competing on CPU, memory, or disk.
- High availability, replication, or low-risk database maintenance becomes necessary.

## Current Priority Order

1. Run the first real-customer private-pilot onboarding with `Docs/deployment/first-private-pilot-onboarding-plan.md`.
2. Keep same-server PostgreSQL under the private-pilot boundary and repeat restore tests on cadence.
3. Confirm external uptime alert recipients and decide whether to add heartbeat monitoring later.
4. Cookie-based session storage and device/session management.
5. Managed PostgreSQL migration before scale.
