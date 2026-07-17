# Identity Role Matrix

This document is the MVP reference for account lifecycle behavior by role.

Use it before adding Identity UI, endpoints, or account policies so role behavior stays intentional and does not drift.

## Role Summary

| Role | How account is created | Main product area | Account settings in MVP |
| --- | --- | --- | --- |
| Customer | Self-registration with email OTP | Customer dashboard, QR, rewards, campaign progress | Change password, change email, remove account |
| Owner | Business registration with email OTP | Owner dashboard, business setup, staff tools, loyalty setup | Change password, change email |
| Staff | Invited by Owner, accepted through secure email link | Staff service panel, QR scan, action/reward use | Change password |
| Admin | Future/back-office role | Not implemented in MVP UI | Not implemented |

## Account Actions

| Action | Customer | Owner | Staff | MVP policy |
| --- | --- | --- | --- | --- |
| Sign up | Yes | Yes | Invitation only | Staff is invited by Owner and becomes usable only after accepting the secure email link and setting a password. Admin remains out of MVP. |
| Sign in | Yes | Yes | Yes | Email/password login requires verified email for self-registered accounts. |
| Sign out | Yes | Yes | Yes | Revokes the provided refresh token and clears local session. |
| Refresh session | Yes | Yes | Yes | Uses opaque refresh token rotation. |
| Password recovery | Yes | Yes | Yes | Public OTP flow with neutral response and short-lived reset token. |
| Change password | Yes | Yes | Yes | Requires current password. Revokes existing refresh tokens and returns user to login. |
| Change email | Yes | Yes | No | Requires current password. Sends OTP to new email. Existing email stays active until OTP verification. Staff email change waits for Owner/business membership policy. |
| Remove account | Yes | No | No | Customer removal is soft delete/anonymization. Owner removal is blocked until business ownership policy exists. Staff removal is Owner-managed through Active/Inactive membership. |
| Edit display name | Yes | No | No | Customer can edit display name. Owner/staff profile editing is out of current MVP. |
| Active/Inactive control | No | Owner controls Staff | No self-service | Owner can toggle staff membership active/inactive. |

## Shared Endpoints

These endpoints intentionally serve multiple roles:

| Endpoint | Roles | Notes |
| --- | --- | --- |
| `POST /api/v1/auth/login` | Customer, Owner, Staff | Returns access token and refresh token. |
| `POST /api/v1/auth/refresh` | Customer, Owner, Staff | Rotates refresh token. |
| `POST /api/v1/auth/logout` | Customer, Owner, Staff | Revokes provided refresh token. |
| `GET /api/v1/auth/me` | Customer, Owner, Staff | Current identity for AuthGate. |
| `POST /api/v1/auth/password-recovery/start` | Customer, Owner, Staff | Sends reset OTP without exposing account existence. |
| `POST /api/v1/auth/password-recovery/verify` | Customer, Owner, Staff | Verifies reset OTP and returns short-lived reset token. |
| `POST /api/v1/auth/password-recovery/complete` | Customer, Owner, Staff | Sets new password and revokes refresh tokens. |
| `POST /api/v1/auth/change-password` | Customer, Owner, Staff | Requires current password, revokes refresh tokens. |

## Role-Specific Endpoints

| Endpoint | Role | Notes |
| --- | --- | --- |
| `POST /api/v1/auth/register/customer/start` | Public customer registration | Starts Customer registration and sends OTP. |
| `POST /api/v1/auth/register/customer/verify` | Public customer registration | Creates Customer and returns token pair. |
| `POST /api/v1/auth/register/owner/start` | Public owner/business registration | Starts Owner and Business registration and sends OTP. |
| `POST /api/v1/auth/register/owner/verify` | Public owner/business registration | Creates Owner/Business and returns token pair. |
| `POST /api/v1/auth/change-email/start` | Customer, Owner | Starts verified email change. |
| `POST /api/v1/auth/change-email/verify` | Customer, Owner | Applies verified email change without revoking refresh tokens. |
| `POST /api/v1/auth/remove-account` | Customer | Customer-only account anonymization and deactivation. |
| `PATCH /api/v1/customers/me/profile` | Customer | Updates Customer display name. |
| `POST /api/v1/owner/staff` | Owner | Deprecated; disabled with `410`. |
| `POST /api/v1/owner/staff/invitations` | Owner | Sends secure Staff invitation link. |
| `GET /api/v1/auth/staff-invitations/preview` | Public invite token | Shows locked invitation email/business before password setup. |
| `POST /api/v1/auth/staff-invitations/accept` | Public invite token | Sets Staff password and activates Staff membership. |
| `PATCH /api/v1/owner/staff/{staff_member_id}` | Owner | Toggles Staff active/inactive. |
| `GET /api/v1/staff/me/context` | Staff | Loads Staff business context after login. |

## Intentional MVP Gaps

- Owner account removal is not implemented because it affects business ownership, staff membership, loyalty configuration, rewards, and audit history.
- Staff account removal is not self-service. Owner manages staff availability through Active/Inactive membership.
- Business suspension is not an Owner self-service action in the private-pilot MVP. The retained `BusinessStatus` field is reserved for future operational/Admin policy.
- Staff email change is not self-service until product policy decides whether staff email is a personal account identity or an owner-managed workplace credential.
- Staff invitation resend/cancel controls are not part of F13. Pending, accepted, and inactive states are visible.
- Admin identity is not part of current MVP UI.
- Social login is out of scope until email/password Identity is stable.
- Immediate invalidation of already-issued access tokens after password reset/change remains a production hardening item. Refresh tokens are already revoked.

## Frontend Rule

Frontend must not decide Identity policy.

The UI may show or hide actions according to this matrix, but backend remains the source of truth for:

- allowed roles
- current password verification
- OTP verification
- token revocation
- account anonymization/deactivation
- staff membership state
