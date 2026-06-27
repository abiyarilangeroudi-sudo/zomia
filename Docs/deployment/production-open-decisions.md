# Production Open Decisions

Date: 2026-06-27

This document tracks decisions that must stay visible during the private-pilot production phase.

The goal is to avoid accidental production hardening by guesswork. Each item has a current MVP direction and a later hardening decision.

## Decision Status Legend

- `Accepted for private pilot`: good enough for the controlled pilot, but not necessarily final.
- `Needs decision before broader launch`: must be decided before public launch or wider onboarding.
- `Later hardening`: not blocking the private pilot, but should not be forgotten.

## 1. OpenAPI Exposure

Status: `Needs decision before broader launch`

Current private-pilot direction:

- Keep API behavior stable.
- Do not depend on public OpenAPI visibility for users.
- If OpenAPI docs are exposed, treat them as developer/operator tooling, not product UI.

Open decision:

- Choose one before broader launch:
  - Disable public docs in production.
  - Protect docs behind admin/basic auth/VPN.
  - Keep docs public temporarily and explicitly accept the risk.

Why it matters:

- Public docs can help debugging, but they also expose endpoint structure.
- Security does not rely on obscurity, but unnecessary public surface should still be minimized.

## 2. Rate Limiting

Status: `Needs decision before broader launch`

Current private-pilot direction:

- Manual monitoring is acceptable only while traffic is controlled.
- Expected error UX is mapped, but abuse protection is not yet a full rate-limit layer.

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

Open decision:

- Decide whether rate limiting lives in Nginx, FastAPI middleware, Redis-backed limiter, or a managed edge/proxy layer.
- Decide whether limits are per IP, per account, per email, per business, or a combination.

## 3. Monitoring And Alerting

Status: `Later hardening`

Current private-pilot direction:

- Manual checks are acceptable for the current controlled pilot.
- Operators check Nginx logs, backend journal logs, PostgreSQL logs, and backup logs.

Needs decision before broader launch:

- Uptime monitoring for `https://zomia.eu/health`.
- Alert channel for downtime.
- Error tracking for backend exceptions.
- Backup failure alerting.
- Disk-space monitoring.
- TLS renewal monitoring.

Open decision:

- Choose the first monitoring stack.
- Define who receives alerts.
- Define what counts as an incident.

## 4. Backup Restore Cadence

Status: `Accepted for private pilot`

Current private-pilot direction:

- Daily PostgreSQL backups run at `03:15 Europe/Berlin`.
- Retention is `14` days.
- Restore was tested once during server hardening.
- Database restore is treated as a last-resort recovery action, not a normal app rollback.

Needs decision before broader launch:

- How often restore tests must be repeated.
- Whether backups should be copied off-server.
- Whether point-in-time recovery is required.
- Whether managed PostgreSQL should replace same-server PostgreSQL.

Recommended next checkpoint:

- Re-test restore after the next meaningful database/schema change or before onboarding a non-test business.

## 5. Legal Placeholder Risk

Status: `Needs provider details and legal review before broader launch`

Current private-pilot direction:

- Legal pages exist under `https://zomia.eu/legal/...`.
- Registration links and Drawer Legal links open those public pages outside the Flutter web app.
- The pages now contain minimum private-pilot draft text instead of one-line placeholders.
- The Impressum is still incomplete until real provider details are added.
- Draft source and review notes are tracked in `Docs/legal/legal-draft-review-notes.md`.

Open decision:

- Complete provider details for Impressum.
- Review or replace the draft legal content before broader onboarding, or explicitly record that the private pilot accepts legal-text risk.

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

Status: `Accepted for private pilot`

Current private-pilot direction:

- Manual deploy remains acceptable while release frequency is low and operator attention is high.
- Each release must keep a previous known-good frontend/backend release available.
- Rollback rules are documented in `Docs/deployment/production-rollback-runbook.md`.

Needs decision before broader launch:

- Whether GitHub Actions builds artifacts only, or also deploys.
- Whether deployment requires manual approval.
- Whether production deploys are tag-based, main-branch based, or release-branch based.
- Where deployment logs and release notes are stored.

Recommended boundary:

- Do not automate SSH deployment until rollback, backup, secrets, and smoke checks are boring and repeatable.

## 7. Token Storage And Session Hardening

Status: `Later hardening`

Current private-pilot direction:

- Flutter Web uses browser storage for MVP production sessions because secure storage blocked web startup.
- Access tokens are short-lived.
- Refresh tokens are rotating opaque tokens stored hashed server-side.

Needs decision before hardened production:

- Keep localStorage only as controlled MVP fallback, or move refresh tokens to HttpOnly Secure cookies.
- Decide whether access tokens issued before password reset/change must be rejected immediately using a session version or `password_changed_at` check.

## 8. Managed Database Migration

Status: `Later hardening`

Current private-pilot direction:

- Same-server PostgreSQL is accepted only for the private pilot while backups and restore remain reliable.

Needs decision before scale:

- Choose managed PostgreSQL provider/location in EU/Germany.
- Test migration from same-server PostgreSQL to managed PostgreSQL.
- Decide backup/PITR requirements.

## Current Priority Order

1. Complete Impressum provider details and review legal draft pages.
2. OpenAPI exposure decision.
3. Rate limiting direction.
4. Backup restore cadence and off-server backup decision.
5. Monitoring/alerting minimum.
6. GitHub Actions/manual deploy boundary.
7. Token storage/session hardening.
8. Managed PostgreSQL migration.
