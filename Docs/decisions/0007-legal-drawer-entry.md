# 0007: Legal Drawer Entry

Date: 2026-06-27

## Status

Accepted for private-pilot planning.

## Context

The app currently exposes legal placeholder access through Drawer entries.
After removing `MStV` from the MVP legal surface, a standalone `Impressum` Drawer entry is too narrow for the legal pages Zomia needs.

Minimum legal pages are defined in `Docs/decisions/0006-minimum-legal-pages.md`.

## Decision

Customer, Owner, and Staff Drawers should use a single `Legal` entry instead of a standalone `Impressum` entry.

The `Legal` entry should open a simple fullscreen dialog or screen containing links to:

```text
Privacy Policy      -> https://zomia.eu/legal/privacy
Terms & Conditions  -> https://zomia.eu/legal/terms
Business Terms      -> https://zomia.eu/legal/business-terms
Cookie Policy       -> https://zomia.eu/legal/cookies
Impressum           -> https://zomia.eu/legal/impressum
```

For the MVP, all legal links may be visible for all roles to keep the interaction simple.
Role-specific hiding can be added later if it becomes necessary.

`MStV` must not be reintroduced unless the product adds editorial/media content and the legal decision changes.

## UI Guardrail

Before this pattern is used in product screens:

- Add the `Legal` Drawer entry and legal link list pattern to the UI Catalog.
- Do not mark the new catalog pattern as `Approved` automatically.
- Get manual approval.
- Then replace the product Drawer `Impressum` entries with `Legal`.

## Consequences

- Drawer stays simpler and avoids adding five separate legal entries.
- Legal content remains reachable without encoding legal rules inside loyalty features.
- Legal links stay aligned with public static pages under `https://zomia.eu/legal/...`.
- Backend, loyalty, QR, campaign, reward, and account logic do not need to change.

## Follow-Up

- Add catalog example for `Legal` Drawer entry and legal links.
- After approval, update Customer, Owner, and Staff Drawers.
- After static legal pages exist, make the links open the public pages.
