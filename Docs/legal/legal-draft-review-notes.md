# Legal Draft Review Notes

Date: 2026-06-27

This document records the basis and remaining review needs for the first non-placeholder legal page drafts under `site/legal/`.

It is not legal advice.

## Drafted Pages

- `site/legal/privacy`
- `site/legal/terms`
- `site/legal/business-terms`
- `site/legal/cookies`
- `site/legal/impressum`

## Reference Sources Checked

- GDPR transparency and privacy notice requirements:
  - Regulation (EU) 2016/679, especially Article 13 and related data-subject rights.
  - https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng
- Cookies and terminal equipment storage:
  - ePrivacy Directive 2002/58/EC, especially Article 5(3).
  - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32002L0058
- Consent interpretation:
  - EDPB Guidelines 05/2020 on consent under Regulation 2016/679.
  - https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-052020-consent-under-regulation-2016679_en
- Price reduction / discount transparency background:
  - Directive (EU) 2019/2161, known as the Omnibus Directive.
  - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32019L2161
- German provider identification / Impressum direction:
  - German Digital Services Act provider-identification requirement should be checked against the current official German text before final publication.
  - https://www.gesetze-im-internet.de/ddg/

## Remaining Must-Review Items

- Final legal provider name.
- Provider postal address.
- Responsible person or legal entity.
- VAT, register, or authority details if applicable.
- Dispute-resolution wording.
- Controller/processor model between Zomia and participating businesses.
- AVV/DPA coverage for Hetzner, Zoho, and any future PostgreSQL/monitoring provider.
- Exact retention periods for accounts, loyalty actions, rewards, logs, and backups.
- Account removal wording for backup retention and historical loyalty/audit records.
- Staff privacy wording, especially owner visibility of Staff actions.
- Marketing/double opt-in policy if campaign reminders, reward reminders, newsletters, or promotional emails are introduced.
- Omnibus/discount wording if percentage or fixed discounts become consumer-facing.

## Current Engineering Decision

- Legal pages stay outside the Flutter web app.
- Flutter links open public static legal pages under `https://zomia.eu/legal/...`.
- Legal copy can be replaced independently from backend, loyalty, QR, campaign, and reward logic.

## 2026-06-27 Privacy Draft Pass 2

The Privacy Policy was updated to better match the current MVP:

- Provider details from Impressum were added.
- Customer, Owner, and Staff roles are described separately.
- QR token hash handling is stated explicitly.
- Loyalty action, points, campaign, reward, and staff activity data are described.
- Transactional emails are separated from marketing.
- Browser storage/localStorage is described as necessary MVP session storage.
- Customer account removal/anonymization is described.
- Owner/Staff removal limitations are described.
- Current private-pilot backup retention is mentioned as `14` days.

Still requiring legal/product review:

- Final controller/processor model between Zomia and businesses.
- Exact retention periods for loyalty history, logs, and backups.
- AVV/DPA coverage for hosting and SMTP providers.
- Staff privacy notice wording.
- Supervisory authority wording.
- Children/minimum-age policy.
