# Auth Recovery and Email Verification Contract

Date: 2026-06-13

This document defines the contract for password recovery, email verification, and account email changes.

F10.4 created the initial design checkpoint. Later F10 work implemented the core email/password account flows while keeping this document as the product/security contract reference.

## Scope

Included:

- Forgot Password contract
- Reset Password contract
- Email Verification request contract
- Email Verification confirm contract
- Change Email contract
- Remove Account contract
- Candidate database tables
- Flutter UX flow
- Delivery strategy hold rule

Not included:

- Real email provider integration
- Production mail templates
- Social Auth / OAuth2
- Refresh token implementation
- Admin account recovery

## Security Rules

Use OWASP Forgot Password guidance as the baseline:

- Do not reveal whether an email exists.
- Return a consistent response for existing and non-existing accounts.
- Use cryptographically secure random tokens or codes.
- Store only token/code hashes.
- Tokens/codes must be single-use.
- Tokens/codes must expire.
- Do not change the account until a valid token/code is presented.
- After password reset, require normal sign-in again.

## Password Recovery Flow

### 1. Request Password Reset

```text
POST /api/v1/auth/password-recovery/start
```

Request:

```json
{
  "email": "customer@example.com"
}
```

Response:

```json
{
  "message": "If an account exists, password reset instructions will be sent."
}
```

Rules:

- Response is always the same.
- If user exists, create one reset token/code.
- If user does not exist, do not reveal that.
- Rate limiting is required before production.
- Email delivery uses the configured SMTP provider in local MVP.

### 2. Reset Password

```text
POST /api/v1/auth/password-recovery/complete
```

Request:

```json
{
  "token": "raw-reset-token-or-code",
  "new_password": "strong-password",
  "confirm_password": "strong-password"
}
```

Response:

```json
{
  "message": "Password has been reset. Please sign in."
}
```

Rules:

- Token/code must be valid, unused, and unexpired.
- Password and confirm password must match.
- Store the new password using the existing password hashing strategy.
- Mark the reset token/code as used.
- Do not automatically sign the user in.
- Existing JWT access tokens are stateless today, so full session invalidation needs a future token/session strategy.

## Email Verification Flow

### 1. Request Verification

```text
POST /api/v1/auth/register/customer/start
POST /api/v1/auth/register/owner/start
```

Request:

```json
{
  "email": "customer@example.com"
}
```

Response:

```json
{
  "message": "If verification is required, instructions will be sent."
}
```

Rules:

- Response should not expose account existence.
- If user exists and email is not verified, create verification token/code.
- If already verified, keep response generic.
- Email delivery uses the configured SMTP provider in local MVP.

### 2. Confirm Verification

```text
POST /api/v1/auth/register/customer/verify
POST /api/v1/auth/register/owner/verify
```

Request:

```json
{
  "token": "raw-verification-token-or-code"
}
```

Response:

```json
{
  "message": "Email verified."
}
```

Rules:

- Token/code must be valid, unused, and unexpired.
- Mark user email as verified.
- Mark token/code as used.

## Change Email Flow

### 1. Start Change Email

```text
POST /api/v1/auth/change-email/start
```

Request:

```json
{
  "new_email": "new-customer@example.com",
  "current_password": "strong-password"
}
```

Rules:

- User must be authenticated.
- MVP implementation supports Customer and Owner first.
- Current password must be verified before sending OTP.
- OTP is sent to the new email address.
- Existing email remains active until OTP verification succeeds.
- New email must not already exist in `users.email`.
- New email is temporarily reserved while an unexpired `email_change` OTP exists.
- Reservation expires with the OTP window so an email cannot be blocked permanently.

### 2. Verify Change Email

```text
POST /api/v1/auth/change-email/verify
```

Request:

```json
{
  "new_email": "new-customer@example.com",
  "code": "123456"
}
```

Rules:

- OTP must be valid, unused, and unexpired.
- OTP payload must belong to the authenticated user.
- On success, update `users.email` and `email_verified_at`.
- Do not revoke existing refresh tokens after a successful email change.
- Staff email change remains a future extension of the same Identity flow.

## Remove Account Flow

### Remove Customer Account

```text
POST /api/v1/auth/remove-account
```

Request:

```json
{
  "current_password": "strong-password"
}
```

Rules:

- User must be authenticated.
- MVP implementation is Customer-only.
- Current password must be verified.
- Account removal is a soft delete with anonymization, not a hard delete.
- Set `users.is_active = false`.
- Remove direct personal identifiers from the account record:
  - replace real email with an internal deleted-account email
  - clear phone
  - replace name with `Deleted customer`
  - clear `email_verified_at`
- Revoke existing refresh tokens.
- Revoke active Customer QR tokens.
- Keep loyalty actions, points ledger, rewards, campaign completions, and audit/history records.
- Owner and Staff removal need separate future contracts because they affect business ownership and staff membership history.

## Implemented Database Direction

### `email_verification_otps`

Purpose:

- One table for registration verification, password reset OTPs, password reset verified tokens, and email change OTPs.

Fields:

```text
id
email
purpose
code_hash
payload_json
expires_at
consumed_at
attempt_count
created_at
```

Purpose enum:

```text
customer_registration
owner_registration
password_reset
password_reset_verified
email_change
```

Indexes / constraints:

- index on `email`
- index on `purpose`
- only store hash, never raw token/code

### `users.email_verified_at`

Implemented field:

```text
email_verified_at
```

Used for registration verification and email changes.

## Flutter UX Flow

### Forgot Password Screen

Entry:

- Login screen link: `Forgot password?`

Fields:

- Email

Primary action:

- `Send reset link`

Success copy:

```text
If an account exists, password reset instructions will be sent.
```

### Reset Password Screen

Entry:

- Deep link from email in production.
- Manual token/code entry may be acceptable for local MVP.

Fields:

- Token/code or prefilled deep-link token
- New password
- Confirm password

Primary action:

- `Reset password`

Success copy:

```text
Password has been reset. Please sign in.
```

### Email Verification Notice

Possible locations:

- After registration
- Customer Profile

Copy:

```text
Please verify your email to keep your account secure.
```

Actions:

- `Send verification`
- `I have verified`

## Delivery Strategy Hold Rule

Do not implement password recovery or email verification with a temporary local/log delivery shortcut.

Reason:

- A log-only reset flow is useful for local QA but not useful for the real product.
- It creates later rework when real email delivery, templates, delivery status, and rate limiting are added.
- It can normalize unsafe behavior around raw recovery tokens/codes.

Implementation stays blocked until:

- Email provider is chosen.
- Sender/domain strategy is known.
- Delivery status/error behavior is defined.
- Rate limiting strategy is defined.
- Production and local delivery modes are explicitly separated.

## Open Product Decisions

- Token link vs numeric OTP.
- Token lifetime.
- Whether email verification is mandatory before using Customer QR.
- Whether Owner/Staff accounts require verification before accessing business tools.
- Whether password reset should invalidate existing JWTs after a proper session store exists.

## Recommended Next Step

Before implementing auth recovery:

```text
Keep auth recovery on hold until email delivery is decided.
```

Next product-safe implementation phase:

```text
F10.5 Owner Activity Endpoint
```
