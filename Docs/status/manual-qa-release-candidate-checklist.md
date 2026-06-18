# Manual QA Release Candidate Checklist

Date: 2026-06-18

This checklist is the repeatable manual QA path before calling a local build release-candidate ready.

It is not a feature backlog. If a scenario fails, record the failure, fix the smallest responsible layer, and rerun the affected section.

## Rules

- Test against the local backend and Flutter web build.
- Keep frontend text in English.
- Do not accept new UI patterns that are not approved in the UI catalog.
- Do not accept frontend-owned loyalty, campaign, reward, or account-policy logic.
- Expected rejected requests may appear as browser network `400` entries, but the user must see a clear UI message.
- If backend/API behavior changes, update `Docs/api/api-endpoint-inventory.md`.
- If product policy changes, update the relevant status document before continuing.

## Build And Startup

Status: Pending

- Backend starts on `http://127.0.0.1:8000`.
- Flutter web starts on `http://127.0.0.1:8080`.
- App version shown on Login matches `frontend/lib/app/app_version.dart`.
- Browser refresh does not create a new Customer QR token unless the user explicitly refreshes QR.
- No local seed/demo data is required for the main happy path except where explicitly stated.

## Authentication

Status: Pending

- Customer registration requires email OTP before account creation/login.
- Owner business registration requires email OTP before account creation/login.
- Login works for Customer, Owner, and Staff.
- Logout clears local session state and returns to Login.
- Refresh-token session recovery works after page refresh.
- Expired/invalid session returns to Login with a user-friendly message.
- Forgot Password sends OTP and allows password reset without auto-login.
- Password reset revokes old refresh tokens.

## Customer Account

Status: Pending

- Customer can open Profile from Drawer.
- Customer can edit display name and see the updated value after save.
- Customer Settings shows Account actions.
- Customer can change password and is asked to sign in again.
- Customer can change email with password plus OTP to the new email.
- Old email remains active until the new email OTP is verified.
- Customer can remove account with password and explicit confirmation.
- Removed Customer cannot continue using the old session after refresh-token failure.

## Owner Account And Business

Status: Pending

- Owner can login and reach Owner Dashboard.
- Owner Profile shows Account Settings.
- Owner can change password and is asked to sign in again.
- Owner can change email with password plus OTP to the new email.
- Owner can open Business Settings from Profile.
- Owner can edit safe business fields:
  - Business name
  - Category
  - Public email
  - Public phone
  - Website
  - Address fields
  - Country code
  - Timezone
- Owner cannot edit slug, status, currency, ownership, or deletion from MVP UI.

## Staff Account

Status: Pending

- Staff can login and reach Staff Dashboard.
- Staff Profile shows Account Settings.
- Staff can change password and is asked to sign in again.
- Staff does not see self-service email change or account removal.
- Inactive Staff cannot access Staff workflows for that business.

## Owner Setup Workflow

Status: Pending

- Owner can create Staff.
- Owner can switch Staff between Active and Inactive.
- Owner can create Mission.
- Owner can create Reward Template independently from Campaign.
- Owner can create Campaign by selecting Mission and Reward Template.
- Campaign date range is required.
- Individual Campaign repeatable default is enabled in Owner UI.
- `Limit completions` starts at 2 when enabled.
- Owner can see recent Staff activity for the selected business.

## Customer QR

Status: Pending

- Customer can open QR fullscreen dialog from AppTopBar.
- QR dialog shows a valid QR and token.
- Manual QR refresh changes the QR/token.
- Old QR becomes invalid after manual refresh.
- QR refresh shows a short warning that the old QR is invalid.
- QR token raw value is not exposed through Staff customer details beyond the scan/resolve flow.

## Staff Service Flow

Status: Pending

- Staff can open QR scanner fullscreen dialog.
- Staff can scan Customer QR.
- Backend resolves the Customer token.
- Staff sees Customer card first.
- Staff can reject Customer context and clear the service flow.
- Staff can confirm Customer context.
- If Customer has no active rewards, Active Rewards card is not shown.
- If Customer has active rewards, Staff can use a reward after confirm dialog.
- Reward use registers a `reward_use` action and clears Customer context.
- Staff can register Mission Action.
- Mission Action registers points, evaluates campaigns, may issue reward, and clears Customer context.
- Staff sees `Reward used.` or `Action registered.` after the operation.
- Staff Recent Actions shows Staff-scoped activity, not Customer recent actions.

## Campaign And Reward

Status: Pending

- Customer Campaign tab shows backend-owned progress labels and badges.
- Campaign All tab shows active/current items.
- Campaign Archive tab shows archived/completed/ended items according to backend state.
- Campaign cards show date range.
- Non-repeatable Campaign completes once and does not repeat.
- Repeatable Campaign starts a new cycle after threshold completion.
- Repeatable Campaign with max completions stops at the backend-owned limit state.
- Repeatable Campaign without max completions remains unlimited inside campaign dates.
- Actions outside campaign date range do not create new campaign progress/rewards.
- Customer Reward tab shows active and archived rewards through the approved tab pattern.
- Used rewards do not appear as active rewards for Staff service.

## Console And Error UX

Status: Pending

- Expected invalid QR resolve shows a clear user-facing message.
- Expected used/invalid reward use shows a clear user-facing message.
- Expected invalid form submissions show clear field or banner messages.
- Unknown backend details are not leaked directly to users.
- Browser console is reviewed after the QA run.
- Known local-only noise is recorded separately from product failures.

## UI Catalog Compliance

Status: Pending

- Login and registration use approved form styling.
- OTP screen uses approved form styling.
- Customer Dashboard uses approved AppTopBar, Drawer, BottomNavBar, SegmentedTabs, QRCard, ProgressCard, and RewardCard.
- Staff Dashboard uses approved AppTopBar, BottomNavBar, ScannerSheetFrame, ConfirmDialog, InlineBanner, MissionRow, and RewardCard patterns.
- Owner Dashboard uses approved AppTopBar, BottomNavBar, FAB, CreateActionSheet, forms, and cards.
- No unapproved reusable visual pattern is introduced in product screens.

## Release Candidate Decision

Status: Pending

Use this section at the end of a QA pass.

- Build tested:
- Backend commit:
- Frontend version:
- Tester:
- Date:
- Result: Pending / Passed / Failed / Blocked
- Notes:

