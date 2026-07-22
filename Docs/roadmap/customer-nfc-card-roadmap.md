# Customer NFC Card Roadmap

Date: 2026-07-22

## Status

Deferred until after the private pilot.

This document records Customer NFC cards as a future Zomia feature. It is not
part of the current MVP scope and creates no commitment to native mobile
distribution, NFC hardware procurement, or pilot delivery.

## Product Goal

Allow a Customer to use a physical NFC card as a faster alternative to showing
their QR code. Staff taps the card with an NFC-capable device, Zomia resolves
the Customer for the selected Business, and Staff explicitly confirms the
Customer before registering a Mission action or using a Reward.

NFC should be an additional Customer-identification method. QR remains the
fallback and the existing loyalty workflow remains the source of truth.

## Intended Experience

1. An authorized Zomia operator assigns an NFC card to a Customer account.
2. Staff starts the Customer service flow and selects NFC.
3. Staff taps the Customer card with an NFC-capable device.
4. Backend validates the card, active Staff membership, Business context, and
   Customer state.
5. Staff sees the same Customer summary currently produced by QR resolution.
6. Staff explicitly confirms the Customer.
7. Staff may use an active Reward or register a Mission action through the
   existing loyalty rules.

Reading a card must never automatically grant points or use a Reward.

## Architecture Direction

- Store an opaque random credential on the card, never Customer PII, email,
  points, or a database identifier.
- Store only a cryptographic hash of the credential in PostgreSQL.
- Model card lifecycle explicitly: `active`, `lost`, `revoked`, and `replaced`.
- Keep card issuance, revocation, and replacement in a focused Identity/Access
  service; do not move credential decisions into Flutter or Loyalty widgets.
- Reuse the existing Staff service summary and Loyalty services after Customer
  resolution instead of creating a second action/reward workflow.
- Keep authorization scoped to the authenticated Staff member and selected
  Business. A card must not expose activity from another Business.
- Preserve idempotency, auditability, account-state checks, and QR fallback.
- Prefer a short-lived service context after card resolution so write requests
  do not repeatedly carry the long-lived card credential.

The hardware tag UID must not be the primary credential. Tag identifiers are
not consistently reliable across tag technologies and do not provide adequate
protection against cloning.

## Platform Direction

The current private-pilot product remains a Flutter WebApp. Reliable NFC support
must be proven on the actual Staff devices before implementation begins.

- A controlled Android Staff reader is the preferred first technical spike.
- Browser-based Web NFC may be evaluated for supported Android environments,
  but must not be treated as cross-platform support.
- iPhone support requires a separate native-distribution decision and device
  validation.
- QR must remain available whenever NFC is unsupported, disabled, or fails.

This feature does not change the accepted mobile-distribution decision in
`Docs/decisions/0008-mobile-distribution.md`.

## Security Boundaries

- Use a high-entropy revocable credential and never log its raw value.
- Make provisioned NDEF cards read-only where supported, while recognizing that
  read-only tags can still be copied.
- Provide an immediate lost-card revoke and replacement process.
- Reject inactive, revoked, replaced, expired, or unknown cards.
- Require an active Staff membership at every sensitive request.
- Rate-limit repeated invalid card resolution attempts.
- Audit card issuance, assignment, revocation, replacement, and successful use.
- Consider cryptographic dynamic tags only if pilot evidence shows that cloning
  risk justifies the additional hardware and operational complexity.

## Entry Criteria

Reopen this feature only after the private pilot when at least one of these is
supported by real usage evidence:

- QR presentation is a repeated source of delay or failure for Customers.
- A Business requests a physical loyalty card for customers without convenient
  smartphone access.
- Staff service speed would materially improve with tap-based identification.
- The project intentionally starts native Android or iOS distribution.

Before implementation, confirm the target Staff devices, card issuer, lost-card
process, one-card-versus-multiple-card policy, cross-Business behavior, hardware
cost, and legal/privacy wording.

## Delivery Outline

1. Run an isolated Android/NDEF hardware spike without changing production.
2. Approve the credential model, lifecycle policy, and device support boundary.
3. Add the backend model, migration, service, endpoints, audit events, and tests.
4. Add restricted card provisioning and replacement tooling.
5. Add the Staff NFC reader while reusing the existing confirmation and service
   workflow.
6. Test real devices, lost/revoked cards, wrong-Business access, repeated taps,
   idempotency, and QR fallback before any controlled rollout.

## Pilot Decision

No NFC code, dependency, database table, endpoint, UI control, card purchase, or
native application work is required for the current private pilot.
