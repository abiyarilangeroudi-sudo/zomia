# 0008 Mobile Distribution Direction

Date: 2026-07-02

## Status

Accepted for private pilot.

## Context

Zomia currently runs as a production private-pilot web app at:

```text
https://zomia.eu/webapp/
```

The root domain is intentionally reserved for a future public landing page.

The project considered whether to add a `/download` page for iOS and Android builds.

## Decision

Do not create `https://zomia.eu/download` for the private pilot.

Do not host iOS or Android app downloads yet.

Keep the private-pilot app surface as:

```text
https://zomia.eu/webapp/
```

Native mobile distribution is deferred until there is a clear product need after private-pilot usage.

Customer NFC card identification is recorded as a possible post-pilot product
need in `Docs/roadmap/customer-nfc-card-roadmap.md`. Recording that feature does
not start native distribution or add NFC to the current private-pilot scope.

## Current Mobile Direction

- WebApp remains the primary app experience for Customer, Staff, and Owner.
- Android APK hosting is not active.
- iOS IPA hosting is not active.
- App Store release is not active.
- Google Play release is not active.
- TestFlight is not active.

## Future Direction

If native mobile distribution becomes necessary:

- Android should start with a signed release build and either:
  - Google Play Internal/Closed Testing; or
  - a deliberately approved APK download flow.
- iOS should start with TestFlight before any App Store release.
- Direct public iOS IPA download is not a normal customer distribution path and should not be used for Zomia.
- App Store and Google Play release readiness should be tracked separately before public launch.

## Guardrails

- Do not add `/download` until native distribution is intentionally started.
- Do not add store badges, app download CTAs, or mobile install promises before the build and update path exists.
- Do not treat native mobile as required for the first private pilot.
- Keep cache/version behavior for the WebApp stable because it is the active production surface.

## Consequences

- Private-pilot updates remain fast because WebApp releases are server-side.
- No App Store or Google Play review process blocks current pilot work.
- No customer-facing download page exists until it has a real artifact to serve.
- Mobile store readiness remains a later production decision, not a current blocker.
