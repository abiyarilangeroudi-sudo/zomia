# MVP Readiness Review After F10

Date: 2026-06-18

This review is a decision checkpoint after the Identity and Account lifecycle work.

It does not introduce a new feature. It summarizes what is ready for demo, what needs care before production, and what the next product step should be.

## Current Verdict

Zomia is in a strong local MVP/demo state.

The core workflow is usable end to end:

```text
Customer QR
-> Staff scan
-> Customer resolve
-> Reward use or mission action registration
-> Points ledger
-> Campaign evaluation
-> Reward generation
-> Recent activity visibility
```

The MVP is not production-ready yet. The remaining work is less about proving the loyalty concept and more about operational polish, production hardening, business profile management, deployment, and final UX consistency.

## Ready For Demo

### Identity And Account

- Customer self-registration with email OTP.
- Owner/business registration with email OTP.
- Staff invitation by Owner with secure email link acceptance.
- Login, logout, refresh token rotation, and session recovery.
- Password recovery by email OTP.
- Account Settings by role:
  - Customer: Change Password, Change Email, Remove Account.
  - Owner: Change Password, Change Email.
  - Staff: Change Password.
- Role behavior is documented in `Docs/status/identity-role-matrix.md`.

### Owner Workflow

- Owner can view/select business context.
- Owner can send Staff invitation.
- Owner can switch Staff Active/Inactive.
- Owner can create Mission.
- Owner can create Reward Template.
- Owner can create Campaign by selecting Mission and Reward Template.
- Owner can see recent Staff activity for the selected business.

### Staff Workflow

- Staff login loads Staff business context.
- Staff account becomes usable only after accepting the secure invitation link and setting a password.
- Staff can scan Customer QR.
- Staff can resolve Customer context.
- Staff can confirm Customer context.
- Staff can use active rewards.
- Staff can register mission actions.
- Staff sees Staff-scoped recent actions.
- Staff context is cleared after service actions.

### Customer Workflow

- Customer can register, login, sign out.
- Customer can show and manually refresh QR.
- Customer can see campaign progress.
- Customer can see active/archived rewards.
- Customer can update display name.
- Customer can manage account settings according to role policy.

### Backend Domain

- Identity is separate from Loyalty.
- QR is separate from Loyalty and wraps scan/service workflows.
- Campaign creation/evaluation/progress now lives in `CampaignService`.
- Loyalty action registration, points ledger, reward generation, and reward use are covered by tests.
- Repeatable Campaign cycles are implemented for Individual Campaigns.
- Group/Cross behavior remains intentionally out of MVP execution.

### Frontend Structure

- Shared UI components live under `frontend/lib/app/ui/`.
- Account Settings moved under Auth presentation ownership.
- Customer, Staff, and Owner screen files are not tiny, but they are still within controlled orchestration boundaries.
- UI catalog remains the approval gate for new reusable patterns.
- Frontend text is English.

## Needs Care Before Production

### Production Blockers

- Deployment stack is still out of scope:
  - Ubuntu 24.04
  - Nginx
  - Systemd
  - GitHub Actions
  - production secrets handling
- PostgreSQL production migration/backup/restore procedure still needs a final pass.
- SMTP provider is usable locally, but production sender identity, deliverability, SPF/DKIM/DMARC, and email templates need final review.
- Legal pages are placeholders:
  - Impressum
  - Terms
  - Privacy/GDPR policy
  - Cookie Policy
- Customer account removal is implemented, but production GDPR policy still needs legal/product review.
- Owner account removal is intentionally not implemented until business ownership policy exists.
- Staff email change/removal policy is intentionally not self-service.

### Security Hardening

- Already-issued access tokens remain valid until expiry after password reset/change; refresh tokens are revoked. Before production, decide whether to add `password_changed_at` or session-version checks.
- Rate limiting is not yet documented as implemented for login, OTP, password recovery, QR resolve, reward use, or action registration.
- Admin/back-office identity is not implemented.
- OAuth/social login is intentionally out of scope.

### Console And Error UX

- Known expected backend `400` responses are mapped to user-facing messages.
- Browser network entries can still show red `400` rows for expected rejection paths.
- `flutter.js.map` 404 and browser WebGL/camera warnings remain local/dev noise unless they break user flow.
- Final production console hygiene pass remains open.

### UI And Branding

- UI/Branding is much more stable than before, but final production polish is still needed.
- Do not introduce one-off UI patterns outside the catalog.
- Dialogs, empty states, business forms, and owner setup UX still need a final design pass.
- Customer Home final composition is not decided and should not be rushed.

### Backend Architecture

- `CampaignService` extraction reduced campaign chaos.
- `LoyaltyService` is still an orchestration hotspot.
- Before Group or Cross-Network Campaigns, extract Reward responsibilities into a dedicated service and keep Individual Campaign behavior green.
- Do not add Group/Cross rules until service boundaries are clearer.

## Do Not Touch Without A Specific Reason

- Do not redesign Identity again unless a real production requirement appears.
- Do not add Group Campaign or Cross-Network Campaign execution yet.
- Do not add wallet/credit economy.
- Do not move loyalty rules into Flutter.
- Do not make Staff email self-service until the Owner/business membership policy is explicit.
- Do not implement Owner removal until business ownership transfer/removal policy exists.
- Do not replace the approved design system with one-off screens.

## Recently Completed Feature

```text
F11: Business Settings / Business Profile
```

Reason this was the right next feature:

- Owner can create and operate loyalty tools, but business profile editing is still not a complete product experience.
- Business identity is central to Customer, Staff, Campaign, Reward, QR, legal pages, and future marketplace/cross-network behavior.
- It is smaller and safer than Group/Cross Campaigns.
- It improves production readiness without creating new domain complexity.

F11 completed scope:

- Owner can view and edit safe business profile details:
  - business name
  - category
  - public email
  - public phone
  - website
  - address fields
  - timezone
- API inventory was updated.
- Frontend UI remains English and catalog-based.
- Owner cannot edit `owner_id`, `slug`, `status`, `currency_code`, ownership transfer, or business deletion from the MVP UI.

## Recommended Next Step

The next step is:

```text
F12: Manual QA Release Candidate Checklist
```

Reason:

- The MVP now has enough moving pieces that manual testing must be repeatable.
- Visual approval, role behavior, QR flow, account lifecycle, and campaign/reward behavior need one shared checklist.
- This is safer than adding another feature before validating the full product path.

After F12, likely next candidates are:

- Production deployment preparation.
- Final UI/Branding consistency pass.
- RewardService extraction before advanced campaign types.

## Current Sources Of Truth

- Current product status: `Docs/status/current-stability-check.md`
- Production gaps: `Docs/status/mvp-production-gap-list.md`
- Manual QA release-candidate checklist: `Docs/status/manual-qa-release-candidate-checklist.md`
- Identity role policy: `Docs/status/identity-role-matrix.md`
- Endpoint inventory: `Docs/api/api-endpoint-inventory.md`
- Production deployment plan: `Docs/deployment/production-deployment-plan.md`
- Historical sprint docs: useful for context, not the current source of truth.
