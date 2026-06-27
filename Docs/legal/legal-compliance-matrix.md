# Legal Compliance Matrix

Date: 2026-06-27

This document is a working decision matrix for Zomia legal and privacy readiness.
It is not legal advice, does not claim compliance, and does not provide final legal text.

The goal is to make legal/product gaps visible before onboarding real customers or businesses.

## Matrix Rules

- Treat this as a decision checklist, not as final legal wording.
- Do not assume acceptance of Terms equals consent for every data processing activity.
- Keep legal content outside loyalty logic.
- Before Group or Cross-Network Campaigns, revisit controller/processor roles and DPIA need.

## Processing Matrix

| Area | Data involved | Data source | Visible to | GDPR role question | Legal basis candidate | Retention question | Required legal notice/page | Open decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Customer registration/login | Name, email, password hash, account status, auth tokens, verification state | Customer | Customer, Zomia operations | Is Zomia controller for customer identity? | Contract / pre-contract, security legitimate interest | Account lifetime plus deletion/backup retention | Customer Terms, Privacy Policy | Final customer identity role and retention |
| Business/Owner registration | Owner email, password hash, business name, category, verification state | Owner | Owner, Zomia operations | Zomia likely controller for owner identity; business data role needs review | Contract / pre-contract | Business account lifetime plus retention after closure | Business Terms, Privacy Policy, Impressum | Business closure and ownership policy |
| Staff invitation/account | Staff email, invitation token hash, invitation status, password hash after accept | Owner provides email; Staff accepts | Owner, Staff, Zomia operations | Business may be controller for inviting staff; Zomia role needs AVV review | Contract / legitimate interest / business instruction | Pending invitation expiry; staff membership retention | Staff privacy notice, Business Terms, Privacy Policy | Staff invitation privacy wording and resend/cancel policy |
| QR token flow | Customer id, QR token hash, issue/expiry/revocation times | Customer account / backend | Customer, Staff during scan, Zomia operations | Zomia and/or Business role depends on loyalty controller model | Contract / legitimate interest for secure service flow | Short token lifetime; hash only; audit need undecided | Privacy Policy, Customer Terms | Whether QR events enter audit logs |
| Loyalty actions / points ledger | Customer id, business id, staff id, mission/action details, points, timestamps | Staff registers action | Customer, Staff during service, Owner activity, Zomia operations | Business may be controller for loyalty activity; Zomia may be processor or joint/independent controller | Contract / legitimate interest; consent not assumed | Needs retention period; deletion/anonymization policy | Privacy Policy, Customer Terms, Business Terms, Staff privacy notice | Controller/processor split and action retention |
| Campaign progress | Campaign, mission, points threshold, progress labels, completion state | Backend from actions | Customer, Owner, Zomia operations | Same as loyalty actions | Contract / legitimate interest | Campaign lifetime plus historical retention | Privacy Policy, Customer Terms, Business Terms | Whether completed/expired progress remains visible |
| Reward issue/use | Reward template, generated reward, status, use timestamp, staff action | Backend and Staff | Customer, Staff, Owner, Zomia operations | Business likely responsible for reward offer terms; Zomia role needs review | Contract / legitimate interest | Reward validity plus historical/audit retention | Reward terms inside Business Terms / Customer Terms | Reward dispute, expiry, misuse, cancellation policy |
| Owner recent activity | Staff action summaries, customer display name/status fallback, points, timestamps | Backend from loyalty actions | Owner | Business visibility of staff/customer activity must be disclosed | Legitimate interest / contract | Needs activity retention window | Staff privacy notice, Privacy Policy, Business Terms | How much customer data owner may see |
| Account settings | Password change, email change OTP, account removal request | User | User, Zomia operations | Zomia controller for identity lifecycle | Contract, legal obligation, security legitimate interest | Security event retention and backup retention | Privacy Policy, Account deletion notice | Access-token invalidation hardening and deletion SLA |
| Email OTP / transactional emails | Email address, OTP hash, expiry, delivery metadata, invitation links | User or Owner | Recipient, Zomia, SMTP provider | Zomia controller; SMTP provider processor | Contract / security legitimate interest | OTP expiry and delivery log retention | Privacy Policy | Email deliverability and provider AVV |
| Backups/logs | Database backup, server logs, backup logs, app logs | System | Zomia operations | Zomia controller/processor depending data role | Security/legal obligation/legitimate interest | Backup retention and restore deletion behavior | Privacy Policy, internal security docs | Backup deletion after account removal |
| Future Group Campaign | Group membership, group progress, participant counts, reward eligibility | Customers/Business/backend | Group members?, Owner, Zomia | Higher joint-controller risk | Needs fresh assessment | Needs group retention policy | Updated Terms/Privacy/Business Terms | Whether members see other participants |
| Future Cross-Network Campaign | Customer actions across multiple businesses, partner participation, shared rewards | Multiple businesses/staff/backend | Participating businesses?, Customer, Zomia | Joint controller or processor network model likely | Needs fresh assessment; consent may be considered but not assumed | Cross-business retention and visibility policy | Updated Terms/Privacy/Business Partner terms | Partner visibility, cost sharing, reward liability |

## Consent Vs Contract

Open rule:

- Terms acceptance can support contract formation.
- Privacy notice acknowledgement is not the same as GDPR consent.
- Do not use consent unless the user has a real choice and can withdraw without breaking core service unexpectedly.
- Marketing messages must be separated from transactional OTP, invitation, security, and account emails.

## TDDDG / Cookies / Local Storage

Current web app uses browser storage for session tokens in the MVP web fallback.

Open questions:

- Confirm whether current storage is strictly necessary for login/session operation.
- If analytics, tracking, marketing pixels, or non-essential storage are added later, consent management must be reviewed first.
- Privacy Policy must explain local storage/session token usage in plain language.

## Processor / AVV Needs

Providers and relationships to review:

- Hetzner server hosting.
- Zoho SMTP/email delivery.
- Future managed PostgreSQL provider.
- Future analytics/error monitoring provider, if added.
- Business-to-Zomia relationship if Zomia processes loyalty data on behalf of businesses.

Open decisions:

- Which parties require AVV/DPA agreements.
- Whether Zomia acts as processor for business loyalty data or independent controller.
- Whether Cross-Network Campaigns create joint-controller relationships.

## Data Subject Rights Gap

Implemented product actions do not yet equal full GDPR rights handling.

Needs process:

- Access request.
- Rectification request.
- Erasure request.
- Restriction request.
- Portability request.
- Objection request.
- Complaint authority information.
- Response deadline tracking.

Account removal is implemented for Customers, but policy wording must explain:

- What is deleted immediately.
- What is anonymized.
- What remains in backups temporarily.
- What remains for legal/security/audit reasons.

## Breach Response Gap

Required before stronger production readiness:

- Incident owner.
- Detection and triage process.
- Evidence/log preservation.
- Supervisory authority notification decision.
- User notification decision.
- Timeline tracking.
- Post-incident review.

## Children / Minors Policy Gap

Open decision:

- Either restrict registration to users old enough to consent under applicable law, or define a parental-consent flow.
- Do not silently allow underage registration without a product/legal decision.

## Staff Privacy Notice Gap

Staff must be clearly told:

- The business owner can see Staff activity.
- Staff actions are tied to customer service events.
- Account status can be activated/inactivated by the Owner.
- Invitation email and membership state are stored.

## DPIA / Risk Assessment Gap

MVP Individual Campaigns may be acceptable for private pilot after review, but future features raise risk:

- Cross-Network Campaigns can combine customer behavior across businesses.
- Group Campaigns can introduce group participation visibility.
- Analytics and gamification can create profiling concerns.

Open decision:

- Decide whether a DPIA is required before Group/Cross/Analytics/Gamification.

## Minimum Before Real Customer Pilot

- Replace legal placeholders or explicitly accept private-pilot risk.
- Decide controller/processor model for current MVP.
- Create minimum Privacy Policy.
- Create minimum Customer Terms.
- Create minimum Business Terms.
- Create real Impressum.
- Decide MStV need.
- Document retention policy for accounts, actions, rewards, logs, and backups.
- Document staff privacy notice.
- Confirm AVV/DPA coverage for Hetzner and Zoho.
- Document data subject request process.
- Document breach response process.
