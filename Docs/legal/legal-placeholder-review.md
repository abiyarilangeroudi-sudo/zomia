# Legal Placeholder Review

Date: 2026-06-27

This document records the current legal placeholder state for the Zomia private-pilot MVP.
It is not legal advice and does not provide final legal text.

## Current UI Status

### Customer Registration

- Shows a Terms acceptance row with:
  - `Terms`
  - `Privacy`
- Both links currently open a placeholder fullscreen dialog:
  - `This content is not available yet.`
- Customer registration is blocked until the checkbox is accepted.

### Business Registration

- Shows a Terms acceptance row with:
  - `Business Terms`
  - `Privacy`
- Both links currently open a placeholder fullscreen dialog:
  - `This content is not available yet.`
- Business registration is blocked until the checkbox is accepted.

### Customer Drawer

- Drawer includes `Profile`, `Setting`, `Impressum`, and `Sign out`.
- `Setting` opens real Account Settings.
- `Impressum` currently opens a placeholder info dialog.

### Owner Drawer

- Drawer includes `Profile`, `Setting`, `Impressum`, and `Sign out`.
- `Setting` opens real Account Settings.
- `Impressum` currently opens a placeholder info dialog.

### Staff Drawer

- Drawer includes `Profile`, `Setting`, `Impressum`, and `Sign out`.
- `Setting` opens real Account Settings.
- `Impressum` currently opens a placeholder info dialog.

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

## What Can Remain Placeholder Temporarily

For a very small private pilot, placeholders can remain temporarily only if this is accepted as an explicit pilot risk and no public marketing launch is implied.

The following should not be treated as production-ready:

- `Terms`
- `Business Terms`
- `Privacy`
- `Impressum`
- `Cookie Policy`

## What Should Not Be Exposed As Final

- Placeholder text such as `This content is not available yet.`
- Generic legal placeholder dialogs that look final.
- Acceptance checkboxes that imply legally complete terms while the linked terms are missing.

## Open Decisions

- Final legal owner/entity details for Impressum.
- Final Terms for Customers.
- Final Business Terms for Owners.
- Final Privacy/GDPR policy.
- Final Cookie Policy / local storage notice.
- Data retention wording for loyalty actions, rewards, account deletion, and staff activity.
- Static public legal pages under `https://zomia.eu/legal/...` were selected in `Docs/decisions/0006-minimum-legal-pages.md`.
- Whether registration should be blocked until final legal pages exist, or allowed only for controlled private-pilot testers.

## MStV Decision

MStV is not currently treated as a required standalone legal page for Zomia's MVP because the product is a loyalty software application, not a journalistic/editorial media offering.

Revisit this decision if Zomia later adds editorial content, public news-like content, media publishing, or another feature that changes the product into a media-style offering.

## Recommended Next Step

Before onboarding real customers or businesses, create minimum legal pages and replace the current placeholders.
The safest implementation path is to keep legal content outside loyalty logic:

- Static public pages under `https://zomia.eu/` for legal documents.
- App links from registration and drawers to those pages.
- No backend or loyalty behavior changes required.

Related decision matrix:

- `Docs/legal/legal-compliance-matrix.md`
- `Docs/decisions/0006-minimum-legal-pages.md`
