# MVP Production Gap List

Date: 2026-06-16

This document lists the remaining gaps before calling Zomia a production-ready MVP.

The goal is not to add features blindly. The goal is to know what must be closed, what can wait, and what needs a design decision before implementation.

## Current Status

F9 manual readiness passed.

Confirmed manually:

- Customer registration, auto-login, sign out
- Customer login and dashboard
- Customer QR fullscreen dialog
- QR refresh changes the QR/token only when explicitly requested
- Page refresh does not rotate the Customer QR token
- Owner dashboard can manage Staff, Mission, Campaign, and Reward Template
- Staff can scan QR, resolve customer, register action, generate/check reward, use reward, and see recent actions

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

### 2. Auth and Session Hardening

Current MVP uses simple JWT access token storage.

Required:

- Define token expiry behavior clearly.
- Decide whether refresh tokens are needed before production MVP.
- Ensure sign out clears all local role/session-related caches.
- Standardize 401/403 handling in Flutter.
- Add user-friendly expired-session messaging.

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

### 8. Staff Lifecycle Management

Owner can create Staff and F10.2 adds Active/Inactive switching.

Required:

- Keep deactivate/reactivate instead of hard delete for MVP, because actions and audit history must remain valid.
- Make inactive Staff unable to access Staff workflows for that business.
- Show clear active/inactive Staff status in Owner dashboard.
- Add tests for inactive Staff access denial.

F10.2 progress:

- Owner can switch Staff between Active and Inactive.
- Inactive Staff are removed from Staff context for that business.
- Inactive Staff cannot resolve Customer QR for that business.
- Owner UI shows Active/Inactive state and confirms the switch.

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

## Should Fix Soon, But Not Production Blockers

- Add phone as optional profile completion later, not registration requirement.
- Improve Owner setup forms after the current MVP workflow remains stable.
- Add more realistic empty states for businesses with no activity.
- Add a formal manual QA checklist file for future release candidates.
- Add Customer-facing explanation for repeatable vs completed campaigns after repeatable rules are defined.

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
- Production deployment stack with Nginx/Systemd/GitHub Actions
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

## Recently Completed Phase

F10.5:

```text
Owner Activity Endpoint
```

Outcome:

- Owner can review recent staff actions for the selected business.
- Auth recovery remains on hold until the email delivery decision.

## Current Recommended Phase

F10.7 should continue with:

```text
Console Hygiene / Error UX manual review
```

Focus:

- Confirm the UI message is clear when Staff uses an old QR token.
- Confirm reward-used and reward-expired errors are clear.
- Confirm Owner activity error state uses mapped messages.
- Keep browser/dev warnings documented without overengineering around harmless local noise.
