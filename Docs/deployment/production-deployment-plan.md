# Production Deployment Plan

Date: 2026-06-24

This document is the first production deployment preparation plan for Zomia.
It does not deploy the project. It defines the target shape, required checks, and open decisions before a real production release.

## Scope

In scope:

- Backend deployment on Ubuntu 24.04.
- PostgreSQL production database planning.
- Flutter web static build deployment.
- Nginx reverse proxy and static file serving.
- Systemd service ownership for the backend.
- Environment variables and secret handling.
- Migration, backup, restore, and rollback procedure.
- GitHub Actions outline.
- Production readiness checklist.

Out of scope for this step:

- Real server provisioning.
- Real domain or DNS changes.
- Running a production deployment.
- Backend behavior changes.
- Loyalty logic changes.
- Database schema changes.
- Flutter UI changes.

## Target Architecture

```text
Browser
-> HTTPS
-> Nginx
   -> Flutter web static files
   -> /api/* reverse proxy
      -> FastAPI backend via localhost
         -> PostgreSQL
         -> SMTP provider
```

Production should keep clear boundaries:

- Nginx owns public HTTP/HTTPS, TLS, static web files, and reverse proxying.
- FastAPI owns API behavior only.
- PostgreSQL owns persistent application data.
- Systemd owns backend process lifecycle.
- GitHub Actions owns repeatable build and verification.

## Server Assumptions

Initial target:

- Ubuntu 24.04 LTS.
- One VM/server for the first production MVP.
- PostgreSQL can run on the same server for the first release if backup/restore is reliable.
- Backend runs as a dedicated non-root system user.
- Nginx is the only public web process.
- Backend listens on localhost only.

Do not expose the backend process directly to the internet.

## Private Pilot Server

Current private pilot server:

```text
Provider: Hetzner
Plan: ubuntu-4gb-nbg1-1
Location: Nuremberg, Germany
Network zone: eu-central
IPv4: 178.104.74.107
IPv6: 2a01:4f8:1c19:49f0::/64
```

Pilot direction:

- Use this server for the first real-customer private pilot.
- Run Nginx, Flutter web static files, FastAPI backend, and initially PostgreSQL on this server.
- Keep PostgreSQL same-server only as the private-pilot fallback path.
- Move to managed PostgreSQL later if customer usage grows or operational risk becomes too high.

Before allowing real customer traffic:

- SSH password login must be disabled or explicitly reviewed.
- A dedicated non-root deployment user must be created.
- Firewall rules must expose only SSH, HTTP, and HTTPS.
- HTTPS must be enabled before customer login or registration.
- PostgreSQL must not be publicly reachable.
- A daily backup job must exist.
- At least one restore test must pass.
- Minimal legal pages must be available or explicitly accepted as a pilot risk.

Server hardening checklist:

- `Docs/deployment/server-hardening-checklist.md`

## Runtime Components

Required production components:

- Python 3.12+ runtime.
- Backend virtual environment.
- PostgreSQL 16 or compatible managed PostgreSQL.
- Nginx.
- Systemd service for FastAPI.
- Certbot or another TLS certificate process.
- SMTP credentials for transactional emails.

Local Docker Compose remains a development tool. It is not the production deployment model unless a separate Docker production plan is explicitly created.

## Production Database Decision

Recommended direction:

- Use managed PostgreSQL in an EU/Germany region for the first real public production release, if budget allows.
- Use same-server PostgreSQL only as an early private-beta fallback, and only after backup/restore has been tested.

Reason:

- Zomia stores identity, business, staff, customer, QR, action, campaign, reward, and account lifecycle data.
- Losing or corrupting the database would damage both trust and product continuity.
- A managed PostgreSQL service reduces operational risk around disk failure, upgrades, monitoring, and backups.
- Same-server PostgreSQL is simpler and cheaper, but it makes the application server a single point of failure.

Decision for F15:

```text
Preferred production path:
  Managed PostgreSQL in EU/Germany

Allowed temporary fallback:
  PostgreSQL 16 on the same Ubuntu 24.04 server
  only for private beta or very early MVP traffic
```

If same-server PostgreSQL is used temporarily:

- PostgreSQL must not be exposed publicly.
- Database access must be local-only or private-network-only.
- Daily automated backups are required.
- Manual backup is required before every migration.
- Restore must be tested before calling the setup production-ready.
- A later move to managed PostgreSQL must remain possible without schema changes.

If managed PostgreSQL is used:

- Choose an EU/Germany region.
- Enable automated backups.
- Confirm point-in-time recovery if available.
- Restrict network access to the backend server.
- Store connection credentials outside Git.
- Test migration and restore before launch.

## Environment And Secrets

Production environment values must not be committed.

Required variables:

```text
APP_ENV=production
DATABASE_URL=...
JWT_SECRET_KEY=...
JWT_ISSUER=zomia-api
ACCESS_TOKEN_MINUTES=...
REFRESH_TOKEN_DAYS=...
CORS_ALLOWED_ORIGINS=https://...
FRONTEND_BASE_URL=https://...
EMAIL_DELIVERY_MODE=smtp
OTP_EXPIRES_MINUTES=10
STAFF_INVITATION_EXPIRES_HOURS=24
SMTP_HOST=...
SMTP_PORT=587
SMTP_USERNAME=...
SMTP_PASSWORD=...
SMTP_FROM_EMAIL=...
SMTP_FROM_NAME=Zomia
SMTP_USE_TLS=true
```

Rules:

- `JWT_SECRET_KEY` must be generated with high entropy for production.
- `.env` files must stay outside Git.
- SMTP sender identity must be reviewed with SPF, DKIM, and DMARC before launch.
- Production CORS must include only the real frontend origin.
- `OTP_TEST_CODE` must not be set in production.

## Backend Deployment Shape

Backend files should be installed under an application directory such as:

```text
/opt/zomia/backend
```

Recommended process:

1. Pull a known Git revision.
2. Create/update the backend virtual environment.
3. Install backend dependencies.
4. Load production environment values from a protected env file.
5. Run Alembic migrations.
6. Restart the backend systemd service.
7. Check health endpoint.

Systemd should own the backend process. The exact service file should be created during the real deployment step, after choosing the final install path and Linux user.

## Frontend Deployment Shape

Flutter web should be built as static files:

```text
./scripts/build_frontend_production.sh
```

The production build script reads `frontend/pubspec.yaml`, passes the version to Flutter through `APP_VERSION_NAME` and `APP_VERSION_BUILD`, uses `API_BASE_URL=https://zomia.eu/api/v1`, builds with `--base-href /webapp/`, and removes generated source-map references from the web output.

The build output should be served by Nginx from a stable release directory.

Recommended layout:

```text
/var/www/zomia/current
/var/www/zomia/releases/<git-sha-or-version>
```

Deployment should publish a new release directory first, then switch `current` after the build is complete.

## Nginx Plan

Nginx responsibilities:

- Serve Flutter web assets.
- Support Flutter route fallback to `index.html`.
- Proxy `/api/` requests to the backend running on localhost.
- Terminate HTTPS.
- Apply reasonable request size and timeout settings.

Nginx should not contain application rules for loyalty, identity, campaigns, rewards, or QR behavior.

## Database Migration Plan

Before every production migration:

1. Confirm current database backup exists.
2. Confirm the target Git revision.
3. Run migration against staging or a copied database when possible.
4. Run `alembic current`.
5. Run `alembic upgrade head`.
6. Verify backend health.
7. Verify login and one read-only API path.

Rollback cannot rely only on Alembic downgrades. Production rollback must include:

- App rollback to previous release.
- Database backup restore decision.
- Clear rule for when restore is acceptable.

Detailed private-pilot rollback steps are tracked in:

- `Docs/deployment/production-rollback-runbook.md`

## Backup And Restore

Minimum production MVP backup expectations:

- Automated daily PostgreSQL backup.
- Manual backup before each migration.
- Backups stored outside the application directory.
- At least one restore test before launch.
- Documented restore command and expected restore time.
- Restore tests repeated after meaningful database migrations, after backup changes, at least monthly during the private pilot, and before onboarding a new real business.
- Off-server backup destination active: Hetzner Storage Box `u623378.your-storagebox.de` with user `u623378`.
- Automated encrypted off-server upload is active from the production server.
- Restore from the encrypted off-server copy passed on 2026-06-27.
- The first scheduled off-server cron run was confirmed on 2026-06-28.

Do not call backup complete until restore has been tested.

## GitHub Actions Outline

The first production workflow should be conservative:

```text
Pull request
-> backend lint
-> backend tests
-> migration SQL generation
-> flutter analyze
-> flutter test
-> flutter build web

Main branch tag/release
-> repeat verification
-> produce deployable frontend artifact
-> optional manual deploy approval
```

Actual SSH deployment should wait until server layout, secret storage, and rollback policy are finalized.

## Observability And Logs

Minimum production MVP visibility:

- Systemd logs for backend.
- Nginx access and error logs.
- PostgreSQL logs.
- Health endpoint check.
- Manual alert process for the first release.

Later production hardening may add structured logs, uptime monitoring, error tracking, and dashboards.

## Security Gates Before Real Production

Before the first real production release:

- HTTPS enabled.
- Production JWT secret generated and protected.
- Production CORS locked down.
- SMTP identity checked with SPF, DKIM, DMARC.
- Rate limiting plan decided for login, OTP, password recovery, QR resolve, reward use, and action registration.
- Legal pages completed:
  - Impressum
  - Terms
  - Privacy/GDPR policy
  - Cookie Policy
- Account deletion policy reviewed for Germany/EU expectations.
- Access-token invalidation hardening decision made after password reset/change.
- Admin/back-office policy decided or explicitly deferred.

## Deployment Checklist

Preparation:

- [ ] Choose production domain.
- [x] Choose server provider.
- [x] Record private pilot server.
- [x] Choose production database direction.
- [ ] Choose production database provider/location.
- [x] Prepare server hardening checklist.
- [ ] Create production env file outside Git.
- [ ] Configure SMTP production sender identity.
- [ ] Prepare Nginx config.
- [ ] Prepare systemd service.
- [ ] Prepare backup location.
- [ ] Test restore procedure.

Build and verify:

- [ ] Run backend tests.
- [ ] Run backend lint.
- [ ] Generate migration SQL.
- [ ] Run Flutter analyze.
- [ ] Run Flutter tests.
- [ ] Build Flutter web with production API base URL.

Release:

- [ ] Backup database.
- [ ] Pull exact release revision.
- [ ] Install dependencies.
- [ ] Run migrations.
- [ ] Restart backend.
- [ ] Publish frontend build.
- [ ] Reload Nginx.
- [ ] Check `/health`.
- [x] Confirm OpenAPI/Swagger/ReDoc are hidden in production.
- [ ] Run a short manual smoke test.

Post-release:

- [ ] Confirm logs are clean.
- [ ] Confirm email delivery.
- [ ] Confirm QR flow.
- [ ] Confirm Owner, Staff, and Customer login.
- [ ] Record release version and Git commit.

## Open Decisions

Current open production decisions are tracked in:

- `Docs/deployment/production-open-decisions.md`

Summary:

- OpenAPI exposure: disabled in production; reintroduce only behind admin/VPN if needed later.
- Rate limiting mechanism and ownership.
- Monitoring minimum: local production health-check script and hourly cron are active; external alerting is still a later decision.
- Backup restore cadence and off-server backup decision: active for private pilot.
- Legal placeholder risk before broader onboarding.
- Deployment method: manual private-pilot deploys vs GitHub Actions with manual approval.
- Access-token invalidation and token storage hardening.
- Managed PostgreSQL provider/location and migration timing.
- Whether to add a staging environment before first public release.

## Current Status

F15 starts as documentation-first production preparation.

Current result:

- Production target architecture is defined.
- Production database direction is defined: managed PostgreSQL in EU/Germany is preferred; same-server PostgreSQL is only a temporary private-beta fallback.
- Private pilot server is selected: Hetzner `ubuntu-4gb-nbg1-1` in Nuremberg, Germany.
- Deployment responsibilities are separated.
- Required production checks are listed.
- Real deployment remains blocked until the open decisions are closed.

Operational checklist:

- Day-to-day private-pilot release, rollback, backup, secrets, Nginx, TLS, and post-release checks are tracked in `Docs/deployment/production-operations-checklist.md`.
- Detailed rollback rules are tracked in `Docs/deployment/production-rollback-runbook.md`.
- Production open decisions are tracked in `Docs/deployment/production-open-decisions.md`.
