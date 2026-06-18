# Current Stability Check

Date: 2026-06-17

This document is the short checkpoint before the next feature phase.

## Completed Scope

- Backend core MVP is implemented through Identity, Loyalty Foundation, Individual Campaign, Reward Engine, QR Staff Workflow, and Staff Context.
- Flutter MVP is implemented through Auth, Customer QR, Staff Dashboard, Owner Dashboard, Customer Registration, and UI/Branding recovery.
- Customer registration is available from the Login screen and auto-signs the customer in after successful registration.
- Customer profile allows the customer to update their display name; email stays read-only.
- Owner minimal setup can create Staff, Mission, Reward Template, and Campaign from Flutter.
- Owner Campaign creation now follows the current domain flow: select a Reward Template and included Missions when creating the Campaign.
- Owner can view recent Staff activity for the selected business.
- Staff can scan Customer QR, resolve the customer, register actions, and use active rewards.
- Customer can view QR, campaign progress, active rewards, and profile basics.

## Verification Snapshot

- Backend tests: `57 passed`
- Frontend tests: `28 passed`
- Flutter analyze: no issues
- Git status before this stability pass: clean

## Current Frontend Structure

- Shared UI components live in `frontend/lib/app/ui/`.
- Auth screens share `auth_form_layout.dart`.
- Customer dashboard is split into `customer_screen.dart`, `customer_views.dart`, `customer_presenter.dart`, and `customer_qr_dialog.dart`.
- Customer dashboard display formatting lives in `customer_presenter.dart`; campaign progress labels and badges are backend-owned and only rendered by Flutter.
- Customer Home is intentionally summary-only for now; detailed campaign progress stays in the Campaign tab, and final Home composition will be decided before production.
- Staff dashboard/service UI is split into `staff_home_screen.dart`, `staff_panel.dart`, `staff_service_cards.dart`, `staff_service_presenter.dart`, and `qr_scanner_sheet.dart`.
- Staff service display formatting lives in `staff_service_presenter.dart`; action registration, campaign evaluation, reward generation, and reward use decisions remain backend-owned.
- Owner dashboard is split into:
  - `owner_screen.dart`
  - `owner_setup_controller.dart`
  - `owner_presenter.dart`
  - `owner_profile_widgets.dart` as a compatibility barrel
  - `owner_profile_cards.dart`
  - `owner_activity_dialog.dart`
  - `owner_business_widgets.dart`
  - `owner_staff_widgets.dart`
  - `owner_loyalty_widgets.dart`
  - `owner_setup_shared_widgets.dart`
  - `owner_setup_widgets.dart` as the export barrel

## Current Backend Structure

- Identity module owns users, owner registration, customer registration, staff creation, and staff context.
- Identity now issues short-lived access tokens with rotating refresh tokens; only refresh token hashes are stored server-side.
- Loyalty module owns missions, actions, points ledger, campaigns, rewards, reward use, and audit events.
- `CampaignService` owns campaign creation, campaign listing, customer campaign progress, action evaluation, cycle calculation, and campaign completion creation.
- `LoyaltyService` still orchestrates action registration and reward generation after campaign completions.
- QR module owns customer QR tokens and staff QR workflow wrappers.

## Watch Items

- MVP production gaps are tracked in `Docs/status/mvp-production-gap-list.md`.
- Reward generation and reward usage still need a later `RewardService` extraction before Group Campaign or Cross-Network Campaign.
- Before Group Campaign or Cross-Network Campaign, continue splitting `LoyaltyService` into smaller services without changing individual campaign behavior.
- Owner recent activity is live for MVP; broader audit review remains separate from owner-facing activity.
- Data and audit posture is documented in `Docs/status/data-audit-review.md`.
- Auth and session hardening now includes refresh token rotation and server-side refresh token revocation on sign out.
- Phone remains out of Customer Registration and Customer Profile editing until a product decision makes it explicit.
- Console Hygiene / Error UX now maps known backend details to clearer UI messages and hides unknown backend details behind generic user-facing fallbacks. Browser network `400` entries, `flutter.js.map` 404, and WebGL/camera warnings remain tracked as dev/browser noise unless they break a user flow.
- Historical sprint docs may still describe what existed during that sprint; use this status document, `Docs/README.md`, and the latest code as the current source of truth.

## Flutter Architecture Guardrail

- Flutter must not own loyalty decisions.
- Backend owns campaign eligibility, campaign time status, progress state, display labels, badge labels, badge tones, reward generation, reward use validity, and idempotency.
- Flutter screens own only UI orchestration: loading state, route/dialog opening, API calls, and passing backend data into approved components.
- Feature presenters may format dates, map backend display tokens to UI enums, compose subtitles, and flatten backend response data for display.
- Presenters must not introduce new campaign/reward rules. If a display needs a new business concept, add it to the backend contract first.
- Shared UI components remain visual only and must not encode Zomia loyalty rules.

## Continue Rules

- Before new UI work, agree on a short execution text first.
- If a new UI feature needs a new reusable component, add it to the UI catalog first, extract its direction from `frontend/zomia_Branding/` when relevant, get manual approval, and then use it in product screens.
- The UI catalog is the approval source of truth: `Approved` means explicitly approved by manual review, `Needs review` means visible in the catalog but not final, and `Draft` means exploration only.
- New components must not receive an `Approved` badge by default. Drawer, tab, navigation, dialog, and dashboard layout components require explicit approval before product usage.
- `Brand Palette` is approved: product UI must use `BrandColors` only, with no one-off colors outside the catalog.
- `Typography` is approved: product UI text must use the theme text scale instead of one-off font styles.
- Customer Dashboard cleanup must start from the catalog `ProgressCard` review before changing product screens.
- Account Settings is implemented per role. Use `Docs/status/identity-role-matrix.md` before changing Customer, Owner, or Staff account actions.
- Keep frontend text in English.
- Bump `frontend/pubspec.yaml` and `frontend/lib/app/app_version.dart` on every Flutter change.
- Keep screen files focused on orchestration; move reusable UI to feature widgets or shared UI components.
- Keep domain rules out of Flutter screens, widgets, and presenters. If frontend logic starts deciding campaign/reward outcomes, stop and move the rule to backend/API contract.
- Do not add Group/Cross campaign behavior before the current individual MVP remains green.
