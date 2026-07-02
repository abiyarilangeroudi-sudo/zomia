# Data And Audit Review

Date: 2026-06-17

This document records the current MVP data and audit posture before moving toward production readiness.

## Scope

This review covers the existing individual campaign MVP flow only:

```text
Customer QR
-> Staff Scan
-> Action Registration
-> Points Ledger
-> Campaign Evaluation
-> Reward Generation
-> Reward Use
```

Group Campaign and Cross-Network Campaign are intentionally out of scope.

## Audit Events

Current internal audit events:

- `mission_created`
- `campaign_created`
- `reward_template_created`
- `action_recorded`
- `points_granted`
- `campaign_completed`
- `reward_generated`
- `reward_used`
- `reward_expired`
- `idempotency_replayed`

These events are internal audit records. They are not the same thing as Owner-visible recent activity.

## Owner-Visible Activity

Owner-visible activity is currently built from loyalty actions:

- Mission progress actions
- Reward use actions
- Staff, Customer, points, summary, and created time

Owner activity is product-facing operational history. It should remain separate from internal audit records.

## Internal Operations Dashboard Decision

Status: `Deferred until after the first private pilot`

An internal `Operations` or `Admin Operations Dashboard` would be useful for support and incident review, but it is not part of the pre-first-customer scope.

Current private-pilot observability already includes:

- `GET` and `HEAD` `/health`
- UptimeRobot external uptime monitoring
- Backend Sentry error tracking
- Production logs
- Local and encrypted off-server PostgreSQL backups
- Owner and Staff recent activity views for product-facing activity

Decision:

- Do not build an Admin Operations Dashboard before the first real customer session.
- Do not add a broad new internal UI surface before the first private pilot.
- Treat a future Operations page as a post-private-pilot roadmap item, not a blocker.
- If debugging during the first pilot is too slow, start with backend operations events before building UI.

Future direction:

- Define internal operations events such as:
  - `business_registered`
  - `customer_registered`
  - `staff_invited`
  - `mission_created`
  - `campaign_created`
  - `action_registered`
  - `reward_issued`
  - `reward_used`
  - `email_failed`
- Keep these events separate from owner-visible recent activity.
- Build a small internal Operations view only after the event boundaries are clear.

## Idempotency

Action registration and reward use both use `business_id + idempotency_key` through `loyalty_actions`.

Current coverage:

- Replayed mission action requests return the existing action.
- Replayed reward use requests return the existing usage.
- Reusing an idempotency key for a different operation returns a conflict.
- Campaign completion and reward generation remain idempotent through action replay and completion/source constraints.

## QR Token Storage

Raw QR tokens are not stored in the database.

Current behavior:

- The API returns the raw token only to the authenticated Customer when issuing or rotating the QR token.
- The database stores `customer_qr_tokens.token_hash`.
- Staff QR resolve hashes the scanned token and looks up the stored hash.
- Rotating a QR token revokes previously active tokens for that Customer.

QR issue, rotate, and resolve do not currently create loyalty audit events. This is acceptable for MVP because the loyalty audit trail starts at service actions and rewards. If production needs security/session audit, that should be added as a separate security audit decision rather than mixed into loyalty audit.

## Remaining Watch Items

- Define whether QR issue/rotate/resolve should become security audit events before production.
- Decide which internal audit records should ever be exposed to Owner, if any.
- Extract `RewardService` before Group or Cross-Network Campaign work.
- Keep idempotency tests in place when splitting service responsibilities.
