# Current Stability Check

Date: 2026-06-13

This document is the short checkpoint before the next feature phase.

## Completed Scope

- Backend core MVP is implemented through Identity, Loyalty Foundation, Individual Campaign, Reward Engine, QR Staff Workflow, and Staff Context.
- Flutter MVP is implemented through Auth, Customer QR, Staff Dashboard, Owner Dashboard, Customer Registration, and UI/Branding recovery.
- Customer registration is available from the Login screen and auto-signs the customer in after successful registration.
- Owner minimal setup can create Staff, Mission, Campaign, and Reward Template from Flutter.
- Staff can scan Customer QR, resolve the customer, register actions, and use active rewards.
- Customer can view QR, campaign progress, active rewards, and profile basics.

## Verification Snapshot

- Backend tests: `41 passed`
- Frontend tests: `7 passed`
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
  - `owner_profile_widgets.dart`
  - `owner_loyalty_widgets.dart`
  - `owner_setup_shared_widgets.dart`
  - `owner_setup_widgets.dart` as the export barrel

## Current Backend Structure

- Identity module owns users, owner registration, customer registration, staff creation, and staff context.
- Loyalty module owns missions, actions, points ledger, campaigns, rewards, reward use, and audit events.
- QR module owns customer QR tokens and staff QR workflow wrappers.

## Watch Items

- `backend/app/modules/loyalty/service.py` is intentionally not refactored in this pass because it contains sensitive tested business logic.
- Before Group Campaign or Cross-Network Campaign, split `LoyaltyService` into smaller services such as action registration, campaign evaluation, reward generation, reward usage, and audit orchestration.
- Owner recent staff actions dialog is UI-ready, but it still needs a dedicated Owner activity endpoint before it can show live data.
- Phone remains out of Customer Registration and should be added later as a profile completion field.
- Console Hygiene / Error UX needs a future cleanup pass: investigate `flutter.js.map` 404 logs, understand WebGL/camera warnings, map expected 400 responses to clear UI messages, and warn customers that manual QR refresh invalidates any previously scanned QR.
- Historical sprint docs may still describe what existed during that sprint; use this status document, `Docs/README.md`, and the latest code as the current source of truth.

## Continue Rules

- Before new UI work, agree on a short execution text first.
- Keep frontend text in English.
- Bump `frontend/pubspec.yaml` and `frontend/lib/app/app_version.dart` on every Flutter change.
- Keep screen files focused on orchestration; move reusable UI to feature widgets or shared UI components.
- Do not add Group/Cross campaign behavior before the current individual MVP remains green.
