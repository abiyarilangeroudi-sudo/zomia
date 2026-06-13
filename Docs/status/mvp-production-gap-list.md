# MVP Production Gap List

Date: 2026-06-13

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

### 4. Owner Activity Endpoint

Owner dashboard has a recent staff actions dialog, but it does not yet have live backend data.

Required:

- Add Owner-scoped recent staff activity endpoint.
- Show staff actions by business.
- Keep Staff recent actions and Owner recent activity as separate product concepts.

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

Current individual campaign flow is stable, but repeatable campaign behavior still needs a product decision.

Required:

- Decide whether a campaign can issue more than one reward per customer.
- Define cycle rules: unlimited, limited count, daily/weekly/monthly reset, or explicit campaign reset.
- Decide how Customer campaign progress should show completed cycles and next-cycle progress.
- Ensure reward generation stays idempotent inside each cycle.
- Keep non-repeatable campaign behavior as the default until repeatable rules are explicit.

### 10. Authentication Flow Completeness

Current MVP supports sign-up, sign-in, and sign-out. Production MVP needs a clearer authentication flow.

Required:

- Password Recovery / Forgot Password.
- Email Verification by OTP or activation link.
- Clear expired-session handling.
- Decide whether Social Auth is needed for MVP or later.
- Keep Google/Apple OAuth2 out of scope until the basic email/password flow is stable.

## Should Fix Soon, But Not Production Blockers

- Add phone as optional profile completion, not registration requirement.
- Add better Customer profile editing.
- Improve Owner setup forms after the current MVP workflow remains stable.
- Add more realistic empty states for businesses with no activity.
- Add a formal manual QA checklist file for future release candidates.
- Add Customer-facing explanation for repeatable vs completed campaigns after repeatable rules are defined.

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

## Next Recommended Phase

F10.1 should be:

```text
Error UX and Console Hygiene
```

Reason:

- It came directly from F9 manual testing.
- It improves trust in testing.
- It does not require changing the product model.
- It makes future manual QA less confusing.
