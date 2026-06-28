# Legal Compliance Matrix

Date: 2026-06-28

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
| Marketing or points notification emails | Email address, opt-in status, consent timestamp, message history | Customer / Owner | Recipient, Zomia, email provider | Zomia controller; business role may need review for business-triggered campaigns | Consent / double opt-in for marketing; transactional basis for necessary account messages | Consent and unsubscribe retention | Privacy Policy, marketing consent notice | Separate marketing from transactional emails |
| Browser storage / cookies | Session tokens, QR cache, local storage keys, possible future analytics identifiers | Browser/app | User device, Zomia app | Zomia controller for app storage | Strictly necessary storage may not need marketing consent; non-essential storage needs review | Session/account lifetime and browser clearing behavior | Cookie Policy / local storage notice, Privacy Policy | Confirm current storage is strictly necessary |
| Discounts / reward value display | Reward type, discount value, campaign threshold, product/service price context if added | Business / backend | Customer, Staff, Owner | Business may own discount offer; Zomia role needs review | Contract / legitimate interest; consumer transparency rules may apply | Campaign/reward retention | Business Terms, Customer Terms, Omnibus/price transparency note | Price reduction and discount transparency policy |
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
- Privacy Policy and Cookie Policy must explain local storage/session token usage in plain language.

## Double Opt-In / Marketing

Current OTP, password recovery, staff invitation, and security emails are transactional.

Open rules:

- Marketing emails must be separated from transactional emails.
- Campaign promotion, points reminders, reward reminders, and similar messages need a product/legal classification before launch.
- If treated as marketing, use double opt-in, store consent evidence, and provide unsubscribe handling.
- Do not reuse account verification consent as marketing consent.

## Omnibus / Discount Transparency

Zomia does not currently calculate public product prices or price reductions.

Open rules:

- If rewards include percentage or fixed discounts shown to consumers, discount wording must be transparent.
- Businesses should remain responsible for the actual price/discount offer unless a later product contract says otherwise.
- Future UI should avoid misleading discount claims and clarify reward conditions, expiry, and redemption limits.

## AML / KYC Note

Zomia does not currently provide a wallet, cash-out, transferable balance, or money-like credit economy.

Current direction:

- AML/KYC is not treated as an MVP requirement.
- Mentioning this exclusion in internal legal notes can help explain why no identity verification flow exists.
- Revisit if points become transferable, cash-like, redeemable across financial partners, or convertible to money/e-money.

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

- Minimum private-pilot legal draft pages exist for Privacy Policy, Cookie Policy, Customer Terms, Business Terms, and Impressum.
- Explicitly accept that these are private-pilot drafts, not legally reviewed final public-launch documents.
- Decide controller/processor model for current MVP before broader launch.
- Keep MStV out of the MVP legal surface unless editorial/media content is introduced later.
- Decide marketing email and double opt-in policy before promotional messages.
- Decide Omnibus/discount transparency wording before showing consumer-facing discount claims.
- Keep AML/KYC out of MVP scope while points remain non-cash, non-transferable, and not a wallet/credit economy.
- Finalize retention policy for accounts, actions, rewards, logs, and backups before broader launch.
- Finalize staff privacy notice before broader launch.
- Confirm AVV/DPA coverage for Hetzner, Zoho, Storage Box/off-server backup, uptime monitoring, and any future managed database provider.
- Document data subject request process.
- Document breach response process.
