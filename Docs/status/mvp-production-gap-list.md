# MVP Production Gap List

Date: 2026-06-27

This document lists the remaining gaps before calling Zomia a production-ready MVP.

The goal is not to add features blindly. The goal is to know what must be closed, what can wait, and what needs a design decision before implementation.

## Current Status

The MVP has moved beyond local-only readiness and is running as a private-pilot deployment:

- Production web app: `https://zomia.eu/webapp/`
- Root domain: `https://zomia.eu/` is intentionally reserved for a future public landing page.
- Public legal placeholder pages: `https://zomia.eu/legal/...`
- Current Flutter version: `1.0.118 (119)`

Confirmed manually across local and production smoke passes:

- Customer registration, auto-login, sign out
- Customer login and dashboard
- Customer QR fullscreen dialog
- QR refresh changes the QR/token only when explicitly requested
- Page refresh does not rotate the Customer QR token
- Owner dashboard can manage Staff, Mission, Campaign, and Reward Template
- Staff can scan QR, resolve customer, register action, generate/check reward, use reward, and see recent actions
- Production registration/login, Staff scan/action, reward generation/use, Owner activity, account settings, legal link routing, and major UI polish flows have passed manual checks.

## Must Fix Before Production MVP

### 1. Error UX and Console Hygiene

Current browser console still shows noisy logs during normal local testing.

Required:

- Map expected backend `400` responses to clear user-facing UI messages.
- Show a clear warning after manual QR refresh: previously scanned QR codes become invalid.
- Investigate `flutter.js.map` 404 in local web serving.
- Understand WebGL/camera/video warnings and decide whether they are harmless local dev noise or need mitigation.
- Keep console clean enough that real failures are easy to notice.

F10.1 progress:

- Staff-facing QR and reward errors are mapped to clearer UI messages.
- Customer manual QR refresh shows a short warning: `Old QR is invalid.`
- `flutter.js.map` 404 is caused by generated web files referencing `flutter.js.map` while the local build output does not include that map file; keep it as a local serving/build artifact cleanup item.
- WebGL/camera/video warnings are still tracked as browser/camera lifecycle noise until proven otherwise.

F10.7 progress:

- Customer QR backend details are mapped to user-facing QR refresh/access messages.
- Owner setup backend details are mapped to clearer business, mission, campaign, and staff email messages.
- Expected backend `400` responses can still appear as red network entries in the browser console; the MVP goal is that users see clear UI messages instead of raw backend details.
- Source-map/WebGL/camera warnings remain tracked as local/dev console noise unless they produce a broken user flow.

F10.12 progress:

- Frontend error mapping no longer exposes unknown backend `detail` text directly in the UI.
- Auth, Customer QR, Staff Service, and Owner Setup now use generic fallback messages for unknown backend details.
- Mapper tests confirm unknown backend details do not leak to users.
- Browser red network entries for real rejected requests remain expected browser behavior; product UX must show clear UI messages.

### 2. Auth and Session Hardening

Current MVP uses JWT access tokens plus rotating opaque refresh tokens.

Required:

- Keep token expiry behavior clear.
- Ensure sign out clears all local role/session-related caches.
- Keep 401/403 handling standardized in Flutter.
- Keep expired-session messaging user-friendly.

F10.14 progress:

- Login now returns an access token and refresh token.
- Refresh tokens are opaque random tokens; only their SHA-256 hash is stored server-side.
- `/auth/refresh` rotates refresh tokens and rejects replay of revoked refresh tokens.
- `/auth/logout` revokes the provided refresh token.
- Flutter stores access and refresh tokens separately, retries one failed authenticated request after refresh, and clears local auth/QR cache if refresh fails.
- App startup can recover a session from a stored refresh token when access token is absent.

F15.8 progress:

- Flutter Web uses browser storage for local production sessions because `flutter_secure_storage` can hang during web startup.
- App startup refreshes a stored refresh token before calling `/auth/me`, so stale access tokens do not create expected `401 /auth/me` console noise.
- Long-term production security still needs a token storage decision: keep localStorage only as the MVP web fallback or move refresh tokens to HttpOnly Secure Cookie before a hardened production release.

### 3. Backend Service Split Before Advanced Campaigns

`backend/app/modules/loyalty/service.py` is still intentionally large.

Required before Group or Cross-Network Campaign:

- Split action registration, campaign evaluation, reward generation, reward usage, and audit orchestration into smaller services.
- Keep current tests green during the split.
- Do not change Group/Cross behavior until individual campaign flow remains stable.

F10.10.1 progress:

- Campaign responsibilities were extracted into `CampaignService`.
- `CampaignService` now owns campaign creation, campaign listing, customer campaign progress, action evaluation, cycle calculation, and campaign completion creation.
- `LoyaltyService` remains the orchestration layer for action registration and still triggers reward generation after Campaign completions are returned.
- Reward generation and reward usage still need a later `RewardService` extraction before Group/Cross-Network Campaign work.

F10.12 architecture progress:

- Reward Template is now independent from Campaign.
- Campaign selects a Reward Template through `campaign_reward_templates`.
- MVP still enforces one Reward Template per Campaign, but the join table leaves room for later multi-reward Campaigns.
- Owner UX now follows the intended setup order: create Mission, create Reward Template, then create Campaign by selecting both.

### 4. Owner Activity Endpoint

Owner dashboard now has live recent staff activity for the selected business.

F10.5 progress:

- Added Owner-scoped `GET /api/v1/owner/activity/recent`.
- Owner activity is business-scoped and only visible to the owner of that business.
- Owner activity reads loyalty actions and shows action type, Staff, Customer, points granted, created time, and a short summary.
- Flutter Owner recent actions dialog now loads live activity with loading, empty, and error states.
- Staff recent actions and Owner recent activity remain separate product concepts.

### 5. QR Lifecycle Clarity

Current QR token behavior is now stable for MVP, but production rules need to be explicit.

Required:

- Define QR token expiration UX.
- Decide whether Customer can manually revoke/rotate from Profile as well as the QR dialog.
- Make invalid/expired QR messages understandable for Staff.
- Make sure rotate behavior is documented: old QR becomes invalid immediately.

### 6. Data and Audit Review

Current Basic Audit exists, but production MVP needs a clearer audit review.

Required:

- Confirm which user actions create audit events.
- Confirm owner-visible vs internal-only audit data.
- Confirm idempotency coverage for action registration and reward use.
- Confirm no raw QR token is stored in the database.

F10.13 progress:

- Data and audit posture is documented in `Docs/status/data-audit-review.md`.
- Owner-visible recent activity is explicitly separated from internal audit events.
- QR raw token storage is covered by a backend test; only `token_hash` is stored.
- QR issue/rotate/resolve remain outside loyalty audit for MVP unless a later security audit decision changes that.

### 7. UI Consistency Pass

UI/Branding recovery reduced chaos, but production MVP still needs a final consistency pass.

Required:

- Re-check Login, Register, Customer, Staff, Owner, dialogs, empty states, and error states against the component catalog.
- Avoid new one-off cards, forms, dialogs, or navigation patterns.
- Keep frontend text in English.

F10.9 progress:

- Staff QR catalog example now matches the current product direction: camera scan only, no manual token fallback pattern.
- Unused secondary-action API was removed from `QRCard` so manual resolve patterns do not re-enter through the shared component.
- Owner dashboard presentation widgets were split by responsibility so Owner profile, activity, business, and staff UI can evolve separately.
- `owner_profile_widgets.dart` remains only as a compatibility barrel.
- New UI features that need a new component must first add it to the UI catalog, extract reference direction when relevant, receive explicit manual approval, and only then use it in product screens.
- New catalog entries must not be marked `Approved` automatically. `Approved` is a manual decision, not a default badge.

F10.11 progress:

- Staff, Customer, and Owner dashboards now have feature presenters for display-only formatting and token-to-UI mapping.
- `staff_service_presenter.dart`, `customer_presenter.dart`, and `owner_presenter.dart` keep screen/widget files focused on orchestration and approved component composition.
- Flutter is explicitly not allowed to own loyalty decisions such as campaign eligibility, reward generation, reward use validity, repeatable cycle status, or campaign time status.
- Customer campaign progress continues to render backend-owned `display_label`, `badge_label`, and `badge_tone`.
- Any future UI need that requires a new campaign/reward concept must first become a backend/API contract, then be rendered by Flutter.

F15.8 UI polish backlog:

- Review placeholder copy across Login, Register, Owner, Staff, and Customer screens.
- Add a close affordance for alert/banner messages where dismissal is useful.
- Shorten or responsively wrap long button labels, including mobile Staff customer confirmation actions.
- Re-check mobile Staff customer card spacing, chip wrapping, and button sizing.
- Keep all UI polish changes routed through approved catalog components.

P9 polish tracking:

- Current MVP UI pass decisions are tracked in `Docs/status/ui-polish-backlog.md`.
- Items accepted for MVP but still needing final production UI review must be added there instead of being kept only in chat.

Legal placeholder tracking:

- Current legal placeholder status is tracked in `Docs/legal/legal-placeholder-review.md`.
- Legal/data-protection decision gaps are tracked in `Docs/legal/legal-compliance-matrix.md`.
- `Terms`, `Business Terms`, `Privacy`, `Cookie Policy`, and `Impressum` are now public static placeholder pages under `https://zomia.eu/legal/...`.
- The legal pages are reachable outside the Flutter web app, but their text is not production-ready legal content yet.
- `MStV` is not treated as required for the current loyalty software MVP unless editorial/media content is introduced later.
- Registration checkboxes currently block registration until accepted and link out to public legal pages, but the linked legal content is still placeholder text.
- Before real customer or business onboarding, replace placeholders with reviewed legal pages or explicitly accept this as a private-pilot risk.

P20/P21 legal and dialog cleanup:

- Drawer `Legal` entries open public static pages outside the Flutter web app in a new tab/page.
- Flutter legal routes under `/webapp/#/legal...` are removed and must not be reintroduced for public legal documents.
- `AppDrawerInfoDialog` was removed.
- Remaining allowed dialog/fullscreen flows are tracked in `Docs/status/frontend-dialog-inventory.md`.

### 8. Staff Lifecycle Management

Owner can invite Staff and F10.2 adds Active/Inactive switching.

Required:

- Keep deactivate/reactivate instead of hard delete for MVP, because actions and audit history must remain valid.
- Make inactive Staff unable to access Staff workflows for that business.
- Show clear active/inactive Staff status in Owner dashboard.
- Add tests for inactive Staff access denial.
- Staff Invitation must remain the only MVP path for new Staff account activation.
- Staff must accept the secure email invitation link and set password before the Staff membership becomes usable.
- Owner should see Staff invitation states such as `Pending`, `Active`, and `Inactive`; resend/cancel invitation can be added as MVP-safe controls later.

F10.2 progress:

- Owner can switch Staff between Active and Inactive.
- Inactive Staff are removed from Staff context for that business.
- Inactive Staff cannot resolve Customer QR for that business.
- Owner UI shows Active/Inactive state and confirms the switch.

F12 gap:

- Manual QA found that Owner-created Staff currently becomes an account without Staff email verification.
- Production MVP direction is Staff Invitation, not direct Staff account creation.

F13 progress:

- Direct Owner-created Staff account activation is disabled.
- Owner now sends secure Staff invitation links.
- Staff invitation token is single-use, time-limited, and stored hashed.
- Staff email is locked by the invitation; Staff sets password only during accept.
- Staff membership becomes active only after invitation accept.
- Owner Staff list includes pending invitations alongside active/inactive memberships.
- Resend/cancel invitation controls remain future work.

### 9. Repeatable Campaign Cycles

Current individual campaign flow is stable. Repeatable behavior is now defined as threshold-based cycles inside the campaign time window.

Required:

- Keep non-repeatable campaign behavior as the default.
- A repeatable campaign can issue one reward for each completed threshold cycle.
- `max_completions_per_customer = null` means unlimited cycles for the campaign time window.
- A positive `max_completions_per_customer` caps cycles per customer.
- Daily/weekly/monthly reset remains out of MVP until there is a separate product decision.
- Customer campaign progress must show the current cycle progress, not total lifetime points.
- Customer campaign progress status and display labels must be backend-owned.
- Reward generation must stay idempotent inside each cycle.

F10.10 progress:

- Backend supports repeatable individual campaign cycles.
- Campaign completions are unique per `campaign + customer + completion_number`.
- Reward generation remains source-based on the completion id.
- Campaigns still require `starts_at` and `ends_at`; points outside the campaign time window do not count.
- Owner UI now exposes repeatable campaign controls after adding the pattern to the UI catalog.
- Individual campaigns are repeatable by default in Owner UI.
- `Limit completions` starts from 2 when enabled; 0 and 1 are not accepted in the UI.
- Owner UI uses date picker fields for `Start date` and `End date`; defaults are today and three months later.
- UI labels unlimited repeatable campaigns as `Unlimited within campaign dates`; backend `null` is not shown as a product concept.
- Backend now returns campaign time status, progress state, display label, badge label, and badge tone for Customer campaign progress.
- Flutter renders backend-owned progress labels and badges instead of deriving completed/active/upcoming/ended locally.
- Campaign time status is backend-owned: `upcoming`, `active`, and `ended` are produced by CampaignService.
- Repeatable campaigns do not create new cycles or rewards after `ends_at`, even if Staff records a later Action for the same Mission.

### 10. Authentication Flow Completeness

Current MVP supports sign-up, sign-in, and sign-out. Production MVP needs a clearer authentication flow.

Required:

- Password Recovery / Forgot Password.
- Email Verification by OTP or activation link.
- Clear expired-session handling.
- Decide whether Social Auth is needed for MVP or later.
- Keep Google/Apple OAuth2 out of scope until the basic email/password flow is stable.

F10.3 progress:

- Flutter clears local auth state and Customer QR cache when authenticated API calls return `401`.
- Flutter shows `Your session expired. Please sign in again.` on the Login screen.
- Login/register backend error details are mapped to clearer user-facing messages.
- Password recovery and email verification remain design/contract work, not rushed implementation.
- Follow OWASP Forgot Password guidance when implementing reset: consistent responses, expiring single-use tokens/codes, secure storage, and no account change before a valid token/code is presented.

F10.4 progress:

- Password recovery and email verification contracts are documented in `Docs/status/auth-recovery-verification-contract.md`.
- No endpoints, migrations, or Flutter screens were added in F10.4.
- Auth recovery implementation is on hold until a real email provider and delivery strategy are chosen.
- Temporary local/log delivery is explicitly avoided to prevent rework and unsafe habits.

F10.15 progress:

- Customer and Owner registration now require email OTP verification before account creation/login.
- Password Recovery / Forgot Password is implemented with email OTP, a short-lived reset token, and no auto-login after reset.
- Password reset revokes the user's existing refresh tokens.
- Manual QA confirmed the expected MVP behavior: a device with an already-valid access token can remain signed in until that access token expires, but it cannot refresh with the old refresh token afterward.
- Before production, decide whether password reset must force immediate logout on all devices by rejecting still-valid access tokens issued before `password_changed_at` or a similar session-version marker.

F10.16 progress:

- Customer Settings is no longer a placeholder.
- Settings now has an `Account` section with `Change Password`, `Change Email`, and `Remove Account` entries.
- These entries are structure-only for now; implementation should proceed one action at a time, starting with `Change Password`.

F10.17 progress:

- `Settings > Account > Change Password` now has a real password-change flow.
- Backend verifies the current password before accepting the new password.
- Successful password change updates the password hash and revokes the user's existing refresh tokens.
- Flutter clears the local session and shows `Password changed. Please sign in again.`
- `Change Email` and `Remove Account` remain planned account actions.

F10.18 progress:

- `Settings > Account > Change Email` now has a Customer and Owner MVP flow.
- Starting an email change requires the current password.
- OTP is sent to the new email address.
- The old email remains active until OTP verification succeeds.
- The pending new email is temporarily reserved through the active OTP window to prevent another account claiming it during verification.
- Successful email change updates the account email and keeps existing refresh tokens valid.
- Staff email change remains a future extension of the same Identity flow.

F10.19 progress:

- `Settings > Account > Remove Account` now has a Customer-only MVP flow.
- Removal requires the current password and explicit confirmation.
- Customer removal is a GDPR-oriented soft delete: the account is deactivated, direct personal fields are anonymized, and loyalty/audit history remains intact.
- The real email is removed from `users.email` by replacing it with an internal deleted-account email, so the original email can be registered again.
- Existing refresh tokens and active Customer QR tokens are revoked after account removal.
- Owner and Staff account removal remain separate future flows because they affect business ownership and staff membership history.

F10.20 review:

- Identity endpoint inventory is current for registration, login, refresh/logout, password recovery, change password, change email, and remove account.
- `auth-recovery-verification-contract.md` was updated from early contract placeholders to the implemented endpoint names and OTP table direction.
- `flutter-mvp-phase.md` was updated so it no longer says MVP has no refresh token.
- Account settings dialogs were moved under Auth presentation ownership so Customer and Owner can reuse the same account UI without growing dashboard files into mixed-purpose files.
- Remaining cleanup watch item: Identity backend service/router are stable but growing; split only when a real second ownership boundary appears, not as speculative churn.

F10.21 progress:

- Owner Profile now links to Account Settings.
- Owner can change password through the existing authenticated change-password endpoint.
- Owner can change email through the same OTP-based email change flow as Customer.
- Owner account removal remains intentionally out of MVP until business ownership, staff membership, and campaign history policy is defined.

F10.22 progress:

- Staff Profile now links to Account Settings.
- Staff can change password through the existing authenticated change-password endpoint.
- Staff Account Settings intentionally shows only Change Password.
- Staff email change remains out of MVP until Owner/business membership policy is defined.
- Staff account removal remains Owner-managed through Active/Inactive membership controls.

F10.23 review:

- Identity role behavior is documented in `Docs/status/identity-role-matrix.md`.
- API inventory now reflects that Change Password is shared by Customer, Owner, and Staff.
- The current MVP policy is explicit: Customer has full self-service account lifecycle, Owner has password/email changes without removal, and Staff has password change only.
- Frontend may hide unavailable actions per role, but backend remains the source of truth for Identity policy.

## Should Fix Soon, But Not Production Blockers

- Add phone as optional profile completion later, not registration requirement.
- Improve Owner setup forms after the current MVP workflow remains stable.
- Add more realistic empty states for businesses with no activity.
- Add Customer-facing explanation for repeatable vs completed campaigns after repeatable rules are defined.

F12 progress:

- A formal manual release-candidate QA checklist is now tracked in `Docs/status/manual-qa-release-candidate-checklist.md`.
- The checklist covers local startup, authentication, role account settings, Owner setup, Customer QR, Staff service flow, campaign/reward behavior, console/error UX, and UI catalog compliance.
- The checklist is intentionally manual because visual approval and product flow validation still depend on human review.

## Recently Completed Feature Direction

Customer Profile completion:

- Customer can update their display name from Profile.
- Phone remains out of the MVP edit flow until the product decision is explicit.
- Email remains read-only in the Customer Profile view.

## Explicitly Out Of Current MVP

- Group Campaign implementation
- Cross-Network Campaign implementation
- Analytics dashboard
- Gamification
- Push notifications
- Offline-first scan queue
- Full admin panel
- Full production automation with Systemd service hardening and GitHub Actions deployment
- Social Auth / OAuth2 unless product decides it is required for launch

## Reference Direction

- Use OWASP ASVS as a security verification reference, not as a reason to overbuild the MVP.
- Use FastAPI deployment guidance when production HTTPS/proxy deployment begins.

## Future Architecture Guardrail

Identity and Access Management should remain conceptually separate from the Loyalty system.

Direction:

- Identity owns authentication, registration, password recovery, email verification, roles, and account lifecycle.
- Access Management owns permissions and role/business membership checks.
- Loyalty owns missions, actions, points ledger, campaigns, rewards, and audit related to loyalty behavior.
- Do not let Loyalty become responsible for password, email verification, OAuth, or account recovery.

## Recent Phase Progress

F11 completed:

```text
F11: Business Settings / Business Profile
```

- `PATCH /api/v1/owner/businesses/{business_id}` is added for Owner-safe business profile updates.
- Owner Business Settings lets Owner edit safe profile fields from Flutter.
- Slug, status, currency, owner transfer, and business deletion remain out of MVP editing.

F12 started:

- Manual QA has a release-candidate checklist: `Docs/status/manual-qa-release-candidate-checklist.md`.
- Use it before calling any local build ready for demo/release-candidate review.

F12 result:

- Manual release-candidate QA passed on 2026-06-24.
- Covered Build/Startup, Authentication, Customer Account, Owner Account and Business, Staff Account, Owner Setup, Customer QR, Staff Service Flow, Campaign/Reward, Console/Error UX, and UI Catalog Compliance.

F14 result:

- Owner Sign out styling is aligned with Customer and Staff.
- Registration checkboxes use the approved `CheckboxRow` component.
- Owner and Staff menu icons open the approved `AppDrawer` pattern with Profile, Setting, Impressum, and Sign out.
- Owner and Staff Profile open as fullscreen dialogs from Drawer; Profile is not a BottomNavBar tab.
- `Docs/api/api-endpoint-inventory.md` remains the API reference to check before adding or changing endpoints.

F15 started:

- Production deployment preparation is now tracked in `Docs/deployment/production-deployment-plan.md`.
- This is documentation-only at this stage.
- Real deployment remains blocked until server, database, secrets, backup/restore, Nginx, Systemd, and GitHub Actions decisions are closed.

F15 database direction:

- Preferred production database path is managed PostgreSQL in an EU/Germany region.
- Same-server PostgreSQL is allowed only as an early private-beta fallback after backup/restore is tested.

F15 private pilot server:

- Hetzner `ubuntu-4gb-nbg1-1` in Nuremberg, Germany is selected for the first real-customer private pilot.
- IPv4: `178.104.74.107`
- IPv6: `2a01:4f8:1c19:49f0::/64`
- Before real customer usage, SSH hardening, firewall, HTTPS, PostgreSQL isolation, backup, and restore test must be completed.

F15.2 server hardening checklist:

- Server baseline checklist is tracked in `Docs/deployment/server-hardening-checklist.md`.
- It must be completed before installing the Zomia application stack.
- Current server baseline progress:
  - Ubuntu 24.04 is running.
  - SSH access uses `delopram`.
  - Direct root SSH login and password SSH are disabled.
  - UFW is active with only SSH, HTTP, and HTTPS open.
  - fail2ban is active for SSH.
  - Application user `zomia` and base deployment directories are created.
  - PostgreSQL 16.14 is installed, active, and bound to localhost only.
  - Database `zomia`, user `zomia_app`, and protected `DATABASE_URL` file are created.
  - Manual PostgreSQL backup and restore test passed.
  - Daily PostgreSQL backup job is installed with 14-day retention.
  - Nginx is installed and active.
  - `zomia.eu` and `www.zomia.eu` DNS point to the pilot server.
  - Let's Encrypt HTTPS is active for `zomia.eu` and `www.zomia.eu`.
  - HTTP redirects to HTTPS.
  - A bootstrap static site is served before the real frontend release.
  - Sensitive web probes such as `.env`, config files, secret files, and backup files return `404` instead of falling through to the frontend.
- Remaining before app installation:
  - Install backend runtime and application code.
  - Run Alembic migrations against the production database.
  - Publish the Flutter web release.
  - Add Systemd service files.
  - Decide the first manual deployment procedure before automating it with GitHub Actions.

F15.3 DNS/HTTPS note:

- Public DNS for `zomia.eu` is correct for IPv4 and IPv6.
- Direct IPv6 to the Hetzner server returns the bootstrap site.
- If a local workstation still loads an old IPv6 target, clear the local DNS cache before treating it as a server problem.
- HSTS is not enabled yet; decide this only after HTTPS and domain routing remain stable.

F15.4 application stack install:

- First manual application release was deployed on 2026-06-25.
- Release id is `20260625201754`.
- Backend release is active at `/opt/zomia/backend/releases/20260625201754`.
- Frontend release is active at `/var/www/zomia/releases/20260625201754`.
- Backend runs through `zomia-backend.service` as user/group `zomia`.
- Backend listens only on `127.0.0.1:8000`.
- Nginx proxies `/api/` and `/health` to backend and serves Flutter web for frontend routes.
- Alembic is at `0011_staff_invitations (head)` on the pilot database.
- Flutter web was built with `API_BASE_URL=https://zomia.eu/api/v1`.
- SMTP was verified after switching the host to `smtp.zoho.eu`.
- HTTPS smoke checks passed for frontend, backend health, Flutter assets, API 404 behavior, and sensitive-path blocking.
- Remaining before customer pilot:
  - Manual production smoke QA in the browser.
  - Confirm real registration OTP delivery from the user inbox side.
  - Decide whether to expose or hide FastAPI docs/OpenAPI publicly.
  - Document the manual rollback procedure for backend and frontend symlinks.

F15.5 webapp subpath:

- The MVP Flutter web app was moved from `/` to `/webapp/`.
- `https://zomia.eu/` now returns a blank root `index.html` for a future public landing page.
- Flutter web was rebuilt with `--base-href=/webapp/`.
- API base remains `https://zomia.eu/api/v1`.
- Active frontend webapp release is `/var/www/zomia/releases/20260625203255`.
- `/var/www/zomia/webapp` points to the active webapp release.
- Backend `FRONTEND_BASE_URL` is now `https://zomia.eu/webapp`.
- Nginx serves `/webapp/` separately while keeping `/api/`, `/health`, HTTPS redirect, and sensitive-path blocking intact.
- Smoke checks passed for root, `/webapp/`, Flutter assets, backend health, API 404, and sensitive-path blocking.

F15.6 console hygiene:

- Missing Flutter source-map requests under `/webapp/` now return `404` instead of falling through to `index.html`.
- This removes the production browser warning where devtools tried to parse the HTML app shell as a source-map JSON file.
- The active production `flutter.js` release no longer contains the generated `sourceMappingURL=flutter.js.map` reference, so browser devtools should stop requesting that missing file during normal smoke QA.
- Runtime Flutter errors must still be investigated by the exact screen/action that triggers them; minified production stack traces alone are not enough to identify the product cause.

F15.7 web storage fallback:

- Production smoke QA found that the app could remain on `Loading Zomia` after `/auth/login` returned `200`.
- Backend logs showed no follow-up `/auth/me`, so the likely blocking point was web token storage before the authenticated profile request.
- Flutter Web now uses browser `localStorage` for session tokens and Customer QR token cache.
- Non-web platforms still use `flutter_secure_storage`.
- Active webapp release is `/var/www/zomia/releases/20260625212639`.
- Smoke checks passed for `/webapp/`, production API base, `localStorage` token access in the built JS, source-map hygiene, and backend health.

F15.8 production smoke and UI polish:

- Production smoke testing found and fixed the missing Staff action point/reward behavior on production data.
- Production smoke testing found and fixed an Owner Staff Recent Actions `500` caused by deleted/anonymized customer records.
- Expected stale `/auth/me` startup `401` noise was removed by refreshing stored sessions before calling `/auth/me`.
- Source-map requests remain non-breaking and should not produce confusing JSON parse warnings.
- UI polish passes improved Staff customer card copy, action buttons, owner create placeholders, validation messages, inline banners, and legal link routing.
- Current accepted polish backlog is tracked in `Docs/status/ui-polish-backlog.md`.
- Final visual polish is still not complete; small copy, spacing, and mobile details remain explicitly tracked instead of treated as blockers.

F15.9 rollback documentation:

- Private-pilot rollback rules are documented in `Docs/deployment/production-rollback-runbook.md`.
- Frontend rollback, backend rollback, and database restore are separated.
- Database restore is explicitly treated as a last-resort data recovery action, not a normal app rollback.
- The operations checklist now links to the rollback runbook.

## Current Recommended Phase

Manual release-candidate QA and production smoke passes have passed. Choose the next phase deliberately instead of adding features opportunistically.

After that, likely candidates are:

- Complete the remaining private-pilot production documentation and rollback checklist.
- Replace or formally risk-accept public legal placeholder content before broader onboarding.
- Final UI/Branding consistency pass for visual details discovered during manual review.
- RewardService extraction before advanced campaign types.
