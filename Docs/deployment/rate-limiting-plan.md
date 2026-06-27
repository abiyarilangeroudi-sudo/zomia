# Rate Limiting Plan

Date: 2026-06-27

This document defines the private-pilot rate limiting direction for Zomia.

It is a deployment/security plan, not a loyalty feature. It must not change loyalty rules, QR rules, reward rules, or frontend behavior.

## Decision

For the private pilot, use conservative Nginx IP-based rate limiting for public and abuse-sensitive API routes.

This is enough for controlled private-pilot traffic, but it is not the final hardening model for scale.

If usage grows, if Zomia moves to multiple app servers, or if abuse needs account/email/business-aware controls, move to an application-level or Redis-backed limiter.

## Production Status

Applied on 2026-06-27.

Production Nginx files:

- Zone definitions: `/etc/nginx/conf.d/zomia-rate-limits.conf`
- Shared API proxy snippet: `/etc/nginx/snippets/zomia-api-proxy.conf`
- Route locations: `/etc/nginx/sites-available/zomia`
- Pre-change backup: `/etc/nginx/sites-available/zomia.backup-202606271955-rate-limit`

Applied zones:

| Zone | Key | Rate | Burst | Notes |
| --- | --- | --- | --- | --- |
| `zomia_auth_strict` | IP address | `10r/m` | `20` | Auth, registration, OTP, password recovery, Staff invitation preview/accept |
| `zomia_token_moderate` | IP address | `30r/m` | `30` | Refresh/logout |
| `zomia_service_moderate` | IP address | `60r/m` | `60` | QR resolve, Staff action registration, reward use |
| `zomia_owner_write_moderate` | IP address for `POST`/`PATCH`; empty key for other methods | `30r/m` | `30` | Owner write endpoints only; GET reads are not counted |

All zones return `429` when exceeded.

Production verification:

- `nginx -t` passed.
- Nginx reload succeeded.
- `https://zomia.eu/health` returned healthy.
- `https://zomia.eu/webapp/` returned `200`.
- Internal auth strict smoke produced `429` after repeated fast requests.
- Internal Owner GET smoke returned repeated `401` and did not produce `429`, confirming Owner read endpoints are not rate-limited by the owner-write zone.

## Why Nginx First

- It is already in the production request path.
- It protects the backend before requests reach FastAPI.
- It does not require backend domain changes.
- It is easy to roll back by removing the Nginx rate-limit blocks.
- It is suitable for a small controlled pilot.

## Limits To Protect First

### Public Authentication And Recovery

These routes should receive the strictest limits:

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register/customer/start`
- `POST /api/v1/auth/register/customer/verify`
- `POST /api/v1/auth/register/owner/start`
- `POST /api/v1/auth/register/owner/verify`
- `POST /api/v1/auth/password-recovery/start`
- `POST /api/v1/auth/password-recovery/verify`
- `POST /api/v1/auth/password-recovery/complete`
- `GET /api/v1/auth/staff-invitations/preview`
- `POST /api/v1/auth/staff-invitations/accept`

Risk:

- Brute force.
- OTP guessing.
- Email enumeration attempts.
- Password recovery abuse.
- Staff invitation token probing.

Private-pilot direction:

- Use a strict IP-based Nginx zone for these routes.
- Keep backend neutral responses for flows where enumeration risk exists.
- Do not expose raw backend details to users.

### Token Session Endpoints

These routes should receive moderate limits:

- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`

Risk:

- Refresh token replay attempts.
- Token endpoint noise.

Private-pilot direction:

- Use a moderate IP-based Nginx zone.
- Keep backend refresh-token rotation and replay rejection as the source of truth.

### Staff Service And QR

These routes should receive moderate limits:

- `POST /api/v1/staff/qr/resolve`
- `POST /api/v1/staff/service/actions`
- `POST /api/v1/staff/service/rewards/{reward_id}/use`
- `POST /api/v1/staff/actions`
- `POST /api/v1/staff/rewards/{reward_id}/use`

Risk:

- QR probing.
- Action spam.
- Reward use retry abuse.

Private-pilot direction:

- Use a moderate IP-based Nginx zone.
- Keep backend authorization, idempotency, QR validation, and reward status checks as the source of truth.

### Owner Write Endpoints

These routes should receive moderate limits:

- `POST /api/v1/owner/businesses`
- `PATCH /api/v1/owner/businesses/{business_id}`
- `POST /api/v1/owner/staff/invitations`
- `PATCH /api/v1/owner/staff/{staff_member_id}`
- `POST /api/v1/owner/missions`
- `POST /api/v1/owner/campaigns`
- `POST /api/v1/owner/reward-templates`

Risk:

- Accidental rapid creation.
- Invitation email abuse.
- Authenticated misuse.

Private-pilot direction:

- Use a moderate authenticated-write Nginx zone.
- Keep backend owner/business authorization as the source of truth.

## Routes That Do Not Need First-Pass Strict Limits

Read endpoints should remain protected by authentication and ordinary Nginx behavior for the private pilot:

- `GET /api/v1/auth/me`
- `GET /api/v1/owner/businesses`
- `GET /api/v1/owner/staff`
- `GET /api/v1/owner/missions`
- `GET /api/v1/owner/campaigns`
- `GET /api/v1/owner/reward-templates`
- `GET /api/v1/owner/activity/recent`
- `GET /api/v1/customers/me/status`
- `GET /api/v1/customers/me/campaigns/progress`
- `GET /api/v1/customers/me/rewards`
- `GET /api/v1/staff/me/context`
- `GET /api/v1/staff/service/missions`
- `GET /api/v1/staff/service/recent-actions`

If logs show repeated abuse or accidental loops, add route-specific limits later.

## Suggested Nginx Zones

Initial private-pilot direction:

- `auth_strict`: for login, registration, OTP, password recovery, and staff invitation accept/preview.
- `token_moderate`: for refresh/logout.
- `service_moderate`: for QR resolve, action registration, and reward use.
- `owner_write_moderate`: for owner write endpoints.

Exact numeric values should be conservative and tested manually before production use.

Do not set aggressive values that break legitimate mobile users on unstable networks.

## Future Hardening

Before broader launch, decide whether to add:

- Redis-backed rate limiting.
- Per-email limits for registration, login, OTP, and password recovery.
- Per-account limits after authentication.
- Per-business limits for Staff action/reward flows.
- Separate limits for failed attempts vs successful requests.
- Temporary lockout or cooldown rules.
- Abuse logging and alerting.

## Manual QA After Applying Limits

After Nginx limits are applied, test:

- Normal login still works.
- Customer registration OTP start/verify still works.
- Business registration OTP start/verify still works.
- Password recovery still works.
- Staff invitation preview/accept still works.
- Staff QR resolve still works.
- Staff action registration still works.
- Staff reward use still works.
- Owner create Mission/Campaign/Reward Template still works.
- Repeated fast requests receive `429` instead of backend errors.
- Browser UI shows existing generic error UX and does not expose raw Nginx text as a normal product state.

## Current Boundary

This plan only chooses the direction.

Applying Nginx limits must be a separate change with:

- A backup of the active Nginx config.
- `nginx -t`.
- Nginx reload.
- Production smoke checks.
- Manual QA for the protected flows.
