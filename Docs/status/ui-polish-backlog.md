# UI Polish Backlog

Date: 2026-06-27

This document tracks UI items that are acceptable for the current MVP but should be revisited before a final production UI pass.

## Current Rule

- Keep frontend text in English.
- Do not add one-off UI patterns directly to product screens.
- The UI catalog remains the approval source for reusable components and interaction patterns.
- New UI components or patterns must be added to the catalog, manually reviewed, and approved before product usage.
- Flutter must not own loyalty rules; UI polish must not change backend, API, or loyalty behavior.

## Passed For MVP, Revisit Later

- Staff customer card is acceptable for MVP. Re-check mobile spacing, chip wrapping, and confirmation action sizing in the final UI pass.
- Staff customer recent actions are acceptable for MVP. Revisit visual density, date formatting, and badge text/tone consistency later.
- Owner create-flow placeholders and form copy improved during the production polish pass, but final copy review is still needed.
- Customer, Staff, and Owner empty states are usable now. Re-check wording and spacing in the final UI pass.
- InlineBanner height and close behavior were improved. Re-test dismiss behavior across Login, Register, Owner, Staff, and Customer screens before final release.
- Drawer, sign out placement, and account settings entry points are acceptable for MVP but need final product review.
- Legal links now open public static pages outside the web app; legal content text still needs final product/legal review.
- Dialog inventory and allowed dialog patterns are tracked in `Docs/status/frontend-dialog-inventory.md`.
- Mobile spacing is currently acceptable for tested flows. Re-check on small iPhone widths before production launch.

## Console Hygiene

- Non-breaking browser warnings such as WebGL/camera messages can remain tracked as browser noise unless they break a user flow.
- Source map warnings should stay suppressed in production builds.
- Unexpected `4xx` or `5xx` console errors during normal user flows should be investigated and either mapped to clear UI feedback or fixed.

## Final UI Pass Reminder

Before calling the UI production-ready, re-check:

- Login, Customer Register, Business Register, Verify Email
- Customer Dashboard, QR dialog, Campaign tab, Reward tab, Profile, Account Settings
- Staff Dashboard, QR scanner, Customer card, Mission registration, Reward use, Staff recent actions
- Owner Dashboard, Business profile, Staff invitations, Mission/Reward/Campaign create dialogs, Owner activity
- UI catalog approval status for every shared component used by product screens
