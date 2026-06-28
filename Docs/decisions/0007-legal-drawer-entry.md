# 0007: Legal Drawer Entry

Date: 2026-06-28

## Status

Accepted for private-pilot planning.

## Context

The app currently exposes a single `Legal` Drawer entry that opens the public static legal index outside the Flutter web app.
After removing `MStV` from the MVP legal surface, a standalone `Impressum` Drawer entry is too narrow for the legal pages Zomia needs.

Minimum legal pages are defined in `Docs/decisions/0006-minimum-legal-pages.md`.

## Decision

Customer, Owner, and Staff Drawers should use a single `Legal` entry instead of a standalone `Impressum` entry.

The `Legal` entry must open the public static legal index outside the Flutter web app:

```text
Legal -> https://zomia.eu/legal
```

The public legal index links to:

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

This pattern has been approved for the MVP:

- The Drawer shows one `Legal` entry.
- It does not open a Flutter dialog.
- It does not route to `/webapp/#/legal`.
- It opens `https://zomia.eu/legal` in a new tab/page.
- Public legal documents stay outside the web app bundle.

## Consequences

- Drawer stays simpler and avoids adding five separate legal entries.
- Webapp stays lighter because legal document pages are not implemented as Flutter screens.
- Legal content remains reachable without encoding legal rules inside loyalty features.
- Legal links stay aligned with public static pages under `https://zomia.eu/legal/...`.
- Backend, loyalty, QR, campaign, reward, and account logic do not need to change.

## Follow-Up

- Replace private-pilot draft content with legally reviewed content before broader public launch.
- Keep `MStV` out unless the product scope changes.
