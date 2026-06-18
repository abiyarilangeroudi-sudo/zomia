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
POST /api/v1/auth/password/forgot
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
- Do not implement reset delivery until the email provider and delivery strategy are chosen.

### 2. Reset Password

```text
POST /api/v1/auth/password/reset
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
POST /api/v1/auth/email/verify/request
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
- Do not implement verification delivery until the email provider and delivery strategy are chosen.

### 2. Confirm Verification

```text
POST /api/v1/auth/email/verify/confirm
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
- MVP implementation is Customer-only first.
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

## Candidate Database Schema

### `auth_verification_tokens`

Purpose:

- One table for password reset and email verification tokens/codes.

Fields:

```text
id
user_id
purpose
token_hash
delivery_target
expires_at
used_at
created_at
```

Purpose enum:

```text
password_reset
email_verification
```

Indexes / constraints:

- index on `user_id`
- index on `purpose`
- unique active token hash
- only store hash, never raw token/code

### `users` additions

Potential fields:

```text
email_verified_at
```

Do not add until implementation begins.

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
