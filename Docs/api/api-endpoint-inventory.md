# API Endpoint Inventory

This document is the human-facing API reference for the MVP.

OpenAPI remains the executable source for exact request and response schemas:

```text
http://127.0.0.1:8000/docs
```

Use this file before adding, changing, or removing endpoints so the project does not grow duplicate API paths.

## Endpoint Lifecycle Policy

Before adding a new endpoint:

- Check the FastAPI routers and OpenAPI docs first.
- Reuse an existing endpoint when the role, permission boundary, and product meaning are the same.
- Add a new endpoint only when the audience, authorization rule, or domain meaning is different.
- Add or update tests for every protected endpoint.
- Add the endpoint to this inventory in the same change.

Endpoint status meanings:

- `active`: Used by MVP product flows or ready for active use.
- `internal`: Supports current implementation details and should not be treated as a stable public contract.
- `deprecated`: Kept temporarily for compatibility; no new UI should depend on it.
- `candidate for removal`: No known consumer; remove after verification.

Unused endpoint policy:

- New internal endpoints can be removed once no frontend/backend consumer exists.
- Public or mobile-facing endpoints should be marked `deprecated` before removal.
- Response fields can remain temporarily for compatibility, but the inventory must document the current consumer.

## Identity Endpoints

| Method | Path | Role | Consumer | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| POST | `/auth/register/customer` | public | legacy clients | deprecated | Disabled with `410`; use OTP start/verify flow. |
| POST | `/auth/register/customer/start` | public | Flutter customer register | active | Starts customer registration and sends email OTP. |
| POST | `/auth/register/customer/verify` | public | Flutter customer register | active | Verifies OTP, creates customer, returns token pair. |
| POST | `/auth/register/owner` | public/admin-seed style | legacy clients | deprecated | Disabled with `410`; use OTP start/verify flow. |
| POST | `/auth/register/owner/start` | public | Flutter business register | active | Starts owner/business registration and sends email OTP. |
| POST | `/auth/register/owner/verify` | public | Flutter business register | active | Verifies OTP, creates owner/business, returns token pair. |
| POST | `/auth/login` | public | Flutter login | active | Returns access token and refresh token. |
| POST | `/auth/password-recovery/start` | public | Flutter forgot password | active | Sends password reset OTP with neutral response. |
| POST | `/auth/password-recovery/verify` | public | Flutter forgot password | active | Verifies reset OTP and returns short-lived reset token. |
| POST | `/auth/password-recovery/complete` | public/reset-token | Flutter forgot password | active | Sets new password and revokes existing refresh tokens. |
| POST | `/auth/change-password` | authenticated | Customer settings | active | Verifies current password, sets new password, revokes existing refresh tokens. |
| POST | `/auth/refresh` | public/token-held | Flutter session refresh | active | Rotates refresh token and returns a new token pair. |
| POST | `/auth/logout` | public/token-held | Flutter sign out | active | Revokes the provided refresh token. |
| GET | `/auth/me` | authenticated | Auth gate | active | Current user identity. |
| PATCH | `/customers/me/profile` | customer | Customer profile | active | Customer can update display name. |
| GET | `/staff/me/context` | staff | Staff login context | active | Returns staff business context after login. |
| POST | `/owner/businesses` | owner | Owner setup | active | Create owner business. |
| GET | `/owner/businesses` | owner | Owner setup | active | List owner businesses. |
| POST | `/owner/staff` | owner | Owner staff tools | active | Create staff user/membership. |
| PATCH | `/owner/staff/{staff_member_id}` | owner | Owner staff tools | active | Toggle staff active/inactive. |
| GET | `/owner/staff` | owner | Owner staff tools | active | List staff memberships. |

## Loyalty Endpoints

| Method | Path | Role | Consumer | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| POST | `/owner/missions` | owner | Owner setup | active | Create mission. |
| GET | `/owner/missions` | owner | Owner setup | active | List missions by business. |
| POST | `/owner/campaigns` | owner | Owner setup | active | Create campaign with date range and repeatable rules. |
| GET | `/owner/campaigns` | owner | Owner setup | active | List campaigns by business. |
| POST | `/owner/reward-templates` | owner | Owner setup | active | Create reward template. |
| GET | `/owner/reward-templates` | owner | Owner setup | active | List reward templates by business. |
| GET | `/owner/activity/recent` | owner | Owner recent actions dialog | active | Business-wide staff activity for the owner. |
| POST | `/staff/actions` | staff | API/dev and non-QR staff flow | active | Registers action by explicit customer id. Flutter staff panel uses QR endpoint instead. |
| GET | `/customers/me/points` | customer | API/dev | internal | Customer total points are not shown in MVP UI. |
| GET | `/customers/me/status` | customer | Customer rewards/profile | active | Customer reward/status summary. |
| GET | `/customers/me/campaigns/progress` | customer | Customer campaign tab | active | Backend owns campaign progress state and labels. |
| GET | `/customers/me/campaigns/{campaign_id}/progress` | customer | API/dev | internal | Single-campaign progress lookup. |
| GET | `/customers/me/rewards` | customer | Customer reward tab | active | Returns active/used reward records for customer UI. |
| POST | `/staff/rewards/{reward_id}/use` | staff | API/dev and non-QR staff flow | active | Uses reward by explicit reward id and business id. Flutter staff panel uses QR endpoint instead. |

## QR And Staff Service Endpoints

| Method | Path | Role | Consumer | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| POST | `/customers/me/qr-token` | customer | Customer QR dialog | active | Issues a current QR token and revokes previous active token. |
| POST | `/customers/me/qr-token/rotate` | customer | Customer QR dialog | active | Manual QR refresh. |
| POST | `/staff/qr/resolve` | staff | Staff QR scan flow | active | Resolves QR into customer service summary. |
| GET | `/staff/service/missions` | staff | Staff service panel | active | Lists missions staff can register for the selected business. |
| GET | `/staff/service/recent-actions` | staff | Staff recent actions tab | active | Staff-owned recent actions, filtered by `staff_id` and business membership. Returns display-ready `summary`, `customer_name`, and `points_granted`. |
| POST | `/staff/service/actions` | staff | Staff service panel | active | Registers mission action using QR token. |
| POST | `/staff/service/rewards/{reward_id}/use` | staff | Staff service panel | active | Uses reward using QR token and resolved customer. |

## Current Duplicate-Risk Notes

`/owner/activity/recent` and `/staff/service/recent-actions` are intentionally separate:

- Owner activity is business-wide and owner-scoped.
- Staff recent actions is staff-owned and staff-scoped.
- They have different permission boundaries and product meanings.

`StaffServiceSummary.recent_actions` still exists in QR responses for compatibility with the current service summary shape, but the Staff `Recent Actions` tab must use:

```text
GET /staff/service/recent-actions
```

If no future flow needs `StaffServiceSummary.recent_actions`, mark that response field as `candidate for removal` before changing the schema.
