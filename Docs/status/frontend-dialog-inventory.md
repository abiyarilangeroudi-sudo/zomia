# Frontend Dialog Inventory

Date: 2026-06-27

This document tracks remaining dialogs and fullscreen flows after the legal/static-content cleanup.

## Dialog Rule

- Static legal or informational content must not be implemented as Flutter dialogs.
- Public legal content lives outside the web app under `https://zomia.eu/legal/...`.
- Dialogs are acceptable for short-lived operational flows, confirmations, scanners, and account-management steps.
- If a dialog grows into a multi-step or frequently revisited workflow, convert it to a screen or route.
- No dialog may introduce loyalty, campaign, reward, or access-control rules in Flutter.

## Approved Or Acceptable For MVP

### Shared confirmation

- `ConfirmDialog`
- Used for explicit confirmation before sensitive actions.
- Status: Keep.

### Customer

- `CustomerQrDialog`
  - Purpose: temporary QR presentation from the Customer AppTopBar.
  - Status: Keep for MVP.

- `CustomerProfileDialog`
  - Purpose: profile view opened from Drawer.
  - Status: Keep for MVP; revisit if Profile grows.

- `CustomerEditProfileDialog`
  - Purpose: short profile edit flow.
  - Status: Keep for MVP; revisit if profile fields grow.

### Staff

- QR scanner fullscreen flow from `StaffPanel`.
  - Purpose: camera scan workflow.
  - Status: Keep.

- `AccountSettingsDialog` opened from Staff Drawer.
  - Purpose: account settings entry point.
  - Status: Keep for MVP.

### Owner

- `OwnerRecentActionsDialog`
  - Purpose: temporary recent Staff activity view.
  - Status: Keep for MVP.

- `OwnerInviteStaffDialog`
  - Purpose: short Staff invitation flow.
  - Status: Keep.

- `OwnerBusinessSettingsDialog`
  - Purpose: business profile settings.
  - Status: Keep for MVP; convert to page if business profile expands.

- `OwnerMissionCreateDialog`
- `OwnerCampaignCreateDialog`
- `OwnerRewardTemplateCreateDialog`
  - Purpose: owner MVP setup/create flows.
  - Status: Keep for MVP; convert to dedicated screens or guided setup if owner tools become larger.

- `AccountSettingsDialog` opened from Owner Drawer.
  - Purpose: account settings entry point.
  - Status: Keep for MVP.

### Account settings

- `AccountChangePasswordDialog`
- `AccountChangeEmailDialog`
- `AccountRemoveDialog`
  - Purpose: focused account-management flows.
  - Status: Keep.

## Removed Or Forbidden Pattern

- `AppDrawerInfoDialog`
  - Removed after legal/static placeholders were moved out of Flutter.
  - Do not reintroduce for Terms, Privacy, Business Terms, Cookie Policy, Impressum, or other static public content.

- Flutter routes under `/webapp/#/legal...`
  - Removed.
  - Do not reintroduce for public legal documents.

## Watch Items

- Profile dialogs may become real screens if profile/account UX grows.
- Owner create dialogs may become real setup screens if Mission, Reward Template, or Campaign creation becomes multi-step.
- Staff scanner remains fullscreen; keep it focused and avoid adding unrelated service-panel content inside it.
- Account settings can remain dialog-based for MVP, but should be reviewed before broader production release.
