# 0006: Minimum Legal Pages

Date: 2026-06-27

## Status

Accepted for private-pilot planning.

## Context

Zomia now has a production-like private-pilot deployment at `https://zomia.eu/webapp/`.
The app still contains legal placeholders in registration and drawer flows.

Before onboarding real customers or businesses, the project needs a clear decision about where minimum legal pages live and which pages are part of the MVP legal surface.

This decision does not provide final legal text and is not legal advice.

## Decision

Minimum legal pages will be public static pages under the root domain, not Flutter-only app dialogs.

Required MVP legal page routes:

```text
https://zomia.eu/legal/privacy
https://zomia.eu/legal/terms
https://zomia.eu/legal/business-terms
https://zomia.eu/legal/cookies
https://zomia.eu/legal/impressum
```

`MStV` is not part of the current MVP legal surface because Zomia is currently a loyalty software application, not a journalistic/editorial media offering.

If Zomia later adds editorial, public media, news-like content, or another media-style feature, the MStV decision must be reviewed again.

## Rationale

Static public legal pages are preferred because they are:

- Accessible without login.
- Linkable from registration, drawers, emails, and future landing pages.
- Independent from Flutter route state and app authentication.
- Safe to serve from the root domain without touching loyalty logic.
- Easier to review and replace with legally reviewed content later.

## Consequences

- Current placeholder dialogs are not production-ready legal content.
- Real customer or business onboarding remains a legal/product risk until minimum legal content exists or the pilot risk is explicitly accepted.
- Future UI work should link registration and drawer legal actions to these static pages.
- Backend, QR, loyalty, campaign, reward, and account logic do not need to change for this decision.

## Follow-Up

- Create static public pages for the required legal routes.
- Replace registration Terms/Privacy placeholder dialogs with links to the static pages.
- Replace Drawer Impressum placeholder with a link to the static Impressum page.
- Keep legal content text review separate from engineering implementation.
- Review `Docs/legal/legal-compliance-matrix.md` before writing final content.
