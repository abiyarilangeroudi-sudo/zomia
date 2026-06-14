# Current Stability Check

Date: 2026-06-13

This document is the short checkpoint before the next feature phase.

## Completed Scope

- Backend core MVP is implemented through Identity, Loyalty Foundation, Individual Campaign, Reward Engine, QR Staff Workflow, and Staff Context.
- Flutter MVP is implemented through Auth, Customer QR, Staff Dashboard, Owner Dashboard, Customer Registration, and UI/Branding recovery.
- Customer registration is available from the Login screen and auto-signs the customer in after successful registration.
- Customer profile allows the customer to update their display name; email stays read-only.
- Owner minimal setup can create Staff, Mission, Campaign, and Reward Template from Flutter.
- Owner can view recent Staff activity for the selected business.
- Staff can scan Customer QR, resolve the customer, register actions, and use active rewards.
- Customer can view QR, campaign progress, active rewards, and profile basics.

## Verification Snapshot

- Backend tests: `45 passed`
- Frontend tests: `11 passed`
- Flutter analyze: no issues
- Git status before this stability pass: clean

## Current Frontend Structure

- Shared UI components live in `frontend/lib/app/ui/`.
- Auth screens share `auth_form_layout.dart`.
- Customer dashboard is split into `customer_screen.dart`, `customer_views.dart`, and `customer_qr_dialog.dart`.
- Staff dashboard/service UI is split into `staff_home_screen.dart`, `staff_panel.dart`, `staff_service_cards.dart`, and `qr_scanner_sheet.dart`.
- Owner dashboard is split into:
  - `owner_screen.dart`
  - `owner_setup_controller.dart`
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
- Loyalty module owns missions, actions, points ledger, campaigns, rewards, reward use, and audit events.
- QR module owns customer QR tokens and staff QR workflow wrappers.

## Watch Items

- MVP production gaps are tracked in `Docs/status/mvp-production-gap-list.md`.
- `backend/app/modules/loyalty/service.py` is intentionally not refactored in this pass because it contains sensitive tested business logic.
- Before Group Campaign or Cross-Network Campaign, split `LoyaltyService` into smaller services such as action registration, campaign evaluation, reward generation, reward usage, and audit orchestration.
- Owner recent activity is live for MVP; broader audit review remains separate from owner-facing activity.
- Phone remains out of Customer Registration and Customer Profile editing until a product decision makes it explicit.
- Console Hygiene / Error UX has started: Staff, Customer QR, and Owner setup now map expected backend details to clearer UI messages. Browser network `400` entries, `flutter.js.map` 404, and WebGL/camera warnings remain tracked as dev/browser noise unless they break a user flow.
- Historical sprint docs may still describe what existed during that sprint; use this status document, `Docs/README.md`, and the latest code as the current source of truth.

## Continue Rules

- Before new UI work, agree on a short execution text first.
- If a new UI feature needs a new reusable component, add it to the UI catalog first, get approval, and then use it in product screens.
- The UI catalog is the approval source of truth: `Approved` components may be reused, `Needs review` components may stay only where already introduced, and `Draft` components must not be used in product screens until approved.
- `Brand Palette` is approved: product UI must use `BrandColors` only, with no one-off colors outside the catalog.
- `Typography` is approved: product UI text must use the theme text scale instead of one-off font styles.
- Customer Dashboard cleanup must start from the catalog `ProgressCard` review before changing product screens.
- Keep frontend text in English.
- Bump `frontend/pubspec.yaml` and `frontend/lib/app/app_version.dart` on every Flutter change.
- Keep screen files focused on orchestration; move reusable UI to feature widgets or shared UI components.
- Do not add Group/Cross campaign behavior before the current individual MVP remains green.
