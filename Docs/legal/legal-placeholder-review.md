# Legal Placeholder Review

Date: 2026-06-27

This document records the current legal page state for the Zomia private-pilot MVP.
It is not legal advice and does not provide final legal text.

## Current UI Status

Public legal pages now live outside the Flutter web app:

- `https://zomia.eu/legal`
- `https://zomia.eu/legal/privacy`
- `https://zomia.eu/legal/terms`
- `https://zomia.eu/legal/business-terms`
- `https://zomia.eu/legal/cookies`
- `https://zomia.eu/legal/impressum`

The pages now contain minimum private-pilot draft text instead of one-line placeholders.
They are reachable from the web app, but they still require legal/provider review before broader public use.

### Customer Registration

- Shows a Terms acceptance row with:
  - `Terms`
  - `Privacy`
- Both links open public static legal pages outside the Flutter web app in a new tab/page.
- Customer registration is blocked until the checkbox is accepted.

### Business Registration

- Shows a Terms acceptance row with:
  - `Business Terms`
  - `Privacy`
- Both links open public static legal pages outside the Flutter web app in a new tab/page.
- Business registration is blocked until the checkbox is accepted.

### Customer Drawer

- Drawer currently includes `Profile`, `Setting`, `Legal`, and `Sign out`.
- `Setting` opens real Account Settings.
- `Legal` opens the public static legal index outside the Flutter web app.

### Owner Drawer

- Drawer currently includes `Profile`, `Setting`, `Legal`, and `Sign out`.
- `Setting` opens real Account Settings.
- `Legal` opens the public static legal index outside the Flutter web app.

### Staff Drawer

- Drawer currently includes `Profile`, `Setting`, `Legal`, and `Sign out`.
- `Setting` opens real Account Settings.
- `Legal` opens the public static legal index outside the Flutter web app.

## Role Needs

### Customer

- Terms of use for customer account usage.
- Privacy policy / GDPR information.
- Impressum.
- Cookie/local storage policy.
- Account removal and data deletion explanation aligned with the implemented Remove Account flow.

### Owner / Business

- Business Terms.
- Privacy policy / GDPR information.
- Impressum.
- Cookie/local storage policy.
- Explanation that Staff invitations are sent by the business owner and require the invited Staff email address.
- Clarification of business data, customer action data, reward data, and staff activity visibility.

### Staff

- Privacy policy / GDPR information.
- Staff account and invitation data handling.
- Explanation that Staff activity is visible to the business owner.
- Impressum access through the app shell.

## Current Legal Text Status

For a very small private pilot, the current draft pages can reduce risk compared with blank placeholders, but they are not a substitute for legal review.

Current draft pages:

- `Terms`
- `Business Terms`
- `Privacy`
- `Cookie Policy`
- `Impressum`

Current private-pilot status:

- The pages are no longer one-line placeholders.
- Impressum includes provider details for Bellis Prennis, contact email, address, registration/VAT status, and consumer dispute wording.
- Legal pages passed a final private-pilot consistency pass on 2026-06-27.
- The pages still require legal review before broader public onboarding.

## What Should Not Be Exposed As Final

- Placeholder text such as `This content is not available yet.`
- Generic legal placeholder dialogs that look final.
- Acceptance checkboxes that imply legally complete terms while the linked terms are missing.
- Flutter routes under `/webapp/#/legal...` for public legal documents.
- Static legal placeholder dialogs inside the web app.

## Open Decisions

- Final Terms for Customers.
- Final Business Terms for Owners.
- Final Privacy/GDPR policy.
- Final Cookie Policy / local storage notice.
- Data retention wording for loyalty actions, rewards, account deletion, and staff activity.
- Final controller/processor model between Zomia and participating businesses.
- AVV/DPA coverage for hosting, SMTP, and any future database/monitoring providers.
- Staff privacy notice wording.
- Discount/reward transparency wording before broader consumer-facing discount use.
- Static public legal pages under `https://zomia.eu/legal/...` were selected in `Docs/decisions/0006-minimum-legal-pages.md`.
- Legal Drawer entries now follow `Docs/decisions/0007-legal-drawer-entry.md`.
- Whether registration should be blocked until final legal pages exist, or allowed only for controlled private-pilot testers.

## MStV Decision

MStV is not currently treated as a required standalone legal page for Zomia's MVP because the product is a loyalty software application, not a journalistic/editorial media offering.

Revisit this decision if Zomia later adds editorial content, public news-like content, media publishing, or another feature that changes the product into a media-style offering.

## Recommended Next Step

Before broader public onboarding, review or replace the private-pilot legal drafts with legal counsel.
The safest implementation path is to keep legal content outside loyalty logic:

- Static public pages under `https://zomia.eu/` for legal documents.
- App links from registration and drawers to those pages.
- No backend or loyalty behavior changes required.

Related decision matrix:

- `Docs/legal/legal-compliance-matrix.md`
- `Docs/legal/legal-draft-review-notes.md`
- `Docs/decisions/0006-minimum-legal-pages.md`
- `Docs/decisions/0007-legal-drawer-entry.md`
