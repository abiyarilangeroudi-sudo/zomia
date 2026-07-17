# Business And Account Lifecycle Roadmap

## Purpose

This roadmap defines the future lifecycle work for Staff, Business, and Owner
accounts without expanding the private-pilot MVP prematurely.

It separates three different decisions that must never be conflated:

- **Staff deactivation:** temporarily remove one Staff membership from one
  Business. It is reversible and preserves history.
- **Business suspension:** temporarily stop a whole Business operationally. It
  is reserved for Operations/Admin, not Owner self-service in the MVP.
- **Business closure and Owner deactivation:** end a business relationship and
  later disable the Owner identity. It is a controlled process, not a quick
  delete button.

The current private pilot needs only Release 1. Releases 2 and 3 are planned
work and must not be exposed before their entry criteria are met.

## Current Baseline

- Owners can already activate and deactivate a Staff membership through
  `PATCH /api/v1/owner/staff/{staff_member_id}`.
- An inactive Staff member cannot use QR, register a Mission action, or use a
  Reward for that Business.
- `BusinessStatus` already has `active` and `suspended` values in the database,
  but no public API or Owner UI changes Business status.
- Customer account removal is soft deletion/anonymization. Owner and Business
  closure are intentionally not implemented.

## Shared Delivery Rules

Every release below follows the same safeguards:

1. Backend state and authorization decide lifecycle behavior; Flutter only
   presents it.
2. Historical actions, points ledger entries, rewards, invitations, and audit
   records are never hard-deleted as a side effect of a status change.
3. State-changing endpoints are owner/Admin scoped, validated, auditable, and
   idempotent for retries.
4. Existing access tokens must be rechecked against the current user,
   membership, and business state in every sensitive workflow.
5. Each release needs focused backend tests, Flutter tests where UI changes,
   a local manual workflow, and production smoke checks before release.
6. Production data is never used to test closure. Use local fixtures or a
   designated non-production test Business.

## Implemented Campaign End Policy

Business closure work must preserve the distinction between natural Campaign
expiry and manual early termination:

- **Expired** is the natural time-based result after `ends_at`. It freezes
  incomplete progress in Customer Archive and creates no new Reward.
- **Ended** is a manual Owner action before `ends_at`. It requires an **Early
  End Settlement**: every Customer with non-zero incomplete progress in the
  current cycle receives one final Reward before the Campaign becomes ended.
- Customers with zero progress receive no settlement Reward. Previously issued
  Rewards stay governed by their own validity period.
- The backend previews the affected Customer count, issues each settlement
  Reward idempotently, and makes the Campaign terminal only after the whole
  settlement succeeds. Flutter displays the preview and confirmation; it never
  determines eligibility.

## Release 1: Staff Deactivation Hardening

### Goal

Make the existing active/inactive Staff membership behavior clear, immediate,
auditable, and robust across multiple Businesses.

### Scope

- Keep the existing model: `StaffMember.is_active` is scoped to one Business,
  not a global deletion of the Staff user.
- Keep Owner controls limited to activate/deactivate. No hard delete and no
  Staff self-service account removal.
- Confirm every Staff workflow checks an active membership for the selected
  Business at request time.
- Make the Owner Team screen explain status through concise labels and a
  confirmation dialog.
- Refresh Owner and Staff context after a status change so the UI never shows
  a stale actionable membership.

### Backend Work

1. Trace every Staff-protected endpoint: Staff context, QR resolve, Mission
   action registration, Reward use, and activity reads.
2. Centralize the active-membership guard where possible; do not duplicate
   policy in routers or Flutter.
3. Add an audit event for activate/deactivate with Owner id, Staff membership
   id, Business id, previous state, new state, and timestamp.
4. Make repeated requests to set the already-current state return a stable,
   successful response without creating duplicate audit events.
5. Keep a deactivated Staff user able to sign in only when they retain another
   active Business membership; otherwise their Staff context is empty and no
   service workflow is available.

### Frontend Work

1. Show `Active` or `Inactive` for every Staff membership in Owner Team.
2. Use a clear confirmation before deactivation and a reversible Activate
   action for inactive memberships.
3. After success, reload the Team list and do not leave obsolete actions on
   screen.
4. In Staff context, show a neutral empty state when there are no active
   memberships. Do not expose internal suspension or authorization details.

### Acceptance Criteria

- An Owner can deactivate and reactivate only Staff of their own Business.
- A deactivated Staff member cannot scan a QR, register an action, or use a
  Reward for that Business, including with an already-issued access token.
- Other active Business memberships of the same Staff user continue working.
- Existing actions and Owner recent activity remain visible.
- Repeating deactivate/reactivate is stable and creates no duplicate effects.

### Release Gate

Release 1 can ship during the private pilot. It requires no migration unless
the audit record needs a new persistence structure.

## Release 2: Business Suspension (Operations/Admin Only)

### Goal

Give Operations/Admin a reversible emergency or temporary-closure control
without turning it into an Owner feature.

### Product Policy

- There is no Owner suspension button or public Business-status endpoint.
- `suspended` means the Business is temporarily unavailable for service, not
  deleted or closed.
- Only a future authenticated Admin/Operations workflow may request or apply
  it. Until that workflow exists, any change is an audited operational action
  performed under a documented runbook.
- Suspension is for a verified temporary operational need, not routine campaign
  management. Campaign end remains the Owner tool for ending a campaign.

### Required Policy Decisions Before Coding

1. Define who may approve suspension and reactivation, and how the request is
   recorded.
2. Define the customer wording and whether a suspended Business is hidden or
   shown as temporarily unavailable.
3. Confirm that Staff service, QR resolution, Mission actions, and Reward use
   are all blocked while suspended.
4. Define what happens to valid unredeemed Rewards: the recommended default is
   to preserve them and allow redemption again after reactivation if they have
   not expired.
5. Decide whether campaign dates continue running while suspended. Recommended:
   they continue; reactivation does not silently extend the offer.

### Backend Work

1. Add a dedicated internal/Admin status transition contract, for example
   `PATCH /api/v1/admin/businesses/{business_id}/status`, accepting only
   approved transitions between `active` and `suspended`.
2. Add a Business-state guard to all service and loyalty mutation paths.
3. Exclude suspended Businesses from Staff service context or return them as
   explicitly unavailable; choose one behavior and use it consistently.
4. Ensure Customers cannot earn progress, receive a new Reward, or redeem a
   Reward with a suspended Business.
5. Persist an audit event containing actor, reason, previous status, new
   status, and timestamp.
6. Add an operations-only status read path. Do not add an Owner route by
   accident.

### Frontend Work

- No Owner UI work in this release.
- Add an Admin Operations UI only after Admin identity, authorization, and the
  operational runbook exist.
- Customer and Staff UI may show a concise unavailable message only if the
  approved policy calls for it.

### Acceptance Criteria

- A suspended Business cannot process any QR-service workflow or loyalty
  mutation.
- No new customer progress, rewards, or reward use can occur while suspended.
- Owners retain read-only management access unless a later policy says
  otherwise.
- Reactivation restores only currently valid normal workflow; it does not
  recreate expired campaigns or rewards.
- Every transition is authorized, auditable, and reversible.

### Release Gate

Release 2 is post-pilot unless a real temporary-closure case appears. It is
blocked by the absence of an Admin identity/UI and the policy decisions above.

## Release 3: Business Closure And Owner Deactivation

### Goal

Provide a controlled exit process for a Business and its Owner without losing
the history required for rewards, disputes, security, accounting, or legal
retention.

### Product Policy

- Closure is not suspension: it is a terminal operational state.
- Closure is requested by the Owner but approved and completed through
  Operations until a reviewed self-service flow is justified.
- Owner deactivation is permitted only after every Business owned by that Owner
  has completed closure or has been transferred under a separately approved
  ownership-transfer policy.
- The product must never describe this process as instant or complete data
  deletion unless the legal retention policy explicitly supports that claim.

### Required Policy And Legal Decisions Before Coding

1. Approve Business Terms, Privacy Policy, retention schedule, backup expiry,
   and a response timeline for closure/deletion requests.
2. Define whether Owner receives a data export, its contents, format, and
   secure delivery process.
3. Define treatment of active campaigns, unredeemed rewards, pending Staff
   invitations, and active Staff memberships. Recommended: closure cannot be
   finalized until each item is explicitly resolved and recorded.
4. Define responsibility for honoring outstanding rewards and handling
   customer disputes.
5. Decide whether ownership transfer is supported. It is out of scope for this
   release; if not supported, closure must precede Owner deactivation.
6. Obtain legal review of the retention and anonymization rules before any
   customer-facing promise is published.

### Data Model And Backend Work

1. Add a terminal `closed` Business status through a forward-only Alembic
   migration. Do not rewrite existing production migrations.
2. Add a `BusinessClosureRequest` record with requester, request time, reason,
   checklist state, approver, completion time, and audit references.
3. Add an Owner request endpoint such as
   `POST /api/v1/owner/businesses/{business_id}/closure-requests`; it creates a
   request only and does not close the Business immediately.
4. Add Operations/Admin endpoints to inspect, approve, reject, and complete a
   request with an immutable audit trail.
5. On completion: end active campaigns, cancel pending invitations, deactivate
   Staff memberships, block all QR/service and loyalty mutations, and preserve
   historical read models according to the approved policy.
6. Add an Owner deactivation operation that verifies no open owned Businesses
   or closure requests remain, increments `session_version`, revokes refresh
   tokens, sets the identity inactive, and applies only the legally approved
   anonymization/retention transformation.
7. Build data export and anonymization as explicit, testable operations; never
   hide them inside a generic delete route.

### Frontend And Operations Work

1. Owner Settings gets a `Request business closure` flow only after policy
   approval. It must explain that closure is reviewed, not instant deletion.
2. Show the request status and the outstanding checklist items; do not allow
   duplicate requests.
3. Keep completed/closed Business history in Owner read-only views if permitted
   by policy, with service actions removed.
4. Build an Admin Operations page after the backend workflow is proven through
   the runbook. Until then, use a protected documented operational procedure.
5. Update support macros, Business Terms, Privacy Policy, and the internal
   closure runbook together.

### Acceptance Criteria

- An Owner cannot accidentally close a Business through one click.
- A closure request has a complete audit trail and an explicit outstanding-work
  checklist.
- A closed Business cannot accept Staff work, QR scans, points, rewards, or
  new invitations.
- Historical records remain internally consistent and are retained or
  anonymized only according to the approved policy.
- Owner deactivation invalidates future sessions and is impossible while an
  owned Business remains operational.
- The process is tested with a restore-capable backup and a non-production
  closure fixture before production use.

### Release Gate

Release 3 is blocked until the legal and operational decisions above are
approved. It is not part of the current private-pilot feature scope.

## Delivery Sequence

1. Keep Release 1 as the current MVP lifecycle behavior and close only its
   hardening/test gaps when observed.
2. Gather real pilot evidence before deciding whether Release 2 is needed.
3. Complete the closure/retention policy and operational runbook before writing
   Release 3 migrations or UI.
4. Implement each release in a separate coherent change set: backend contract
   and tests, migration where required, frontend, docs, manual QA, then
   production deployment.

## Related Documents

- [Identity Role Matrix](../status/identity-role-matrix.md)
- [MVP Production Gap List](../status/mvp-production-gap-list.md)
- [Legal Compliance Matrix](../legal/legal-compliance-matrix.md)
- [Production Operations Checklist](../deployment/production-operations-checklist.md)
