# Sprint 5: QR Staff Workflow

## هدف Sprint

هدف Sprint 5 اتصال core backend به workflow واقعی service است.

در پایان این Sprint سیستم باید بتواند:

```text
Customer یک QR قابل ارائه داشته باشد
Staff QR را scan/resolve کند
Staff customer summary ببیند
Staff از همان context برای Customer Action ثبت کند
Staff از همان context Reward فعال را use کند
```

Sprint 5 هنوز UI Flutter نمی‌سازد. این Sprint API backend را برای Staff Service Panel آماده می‌کند.

## تعریف QR در MVP

QR در MVP نباید `customer_id` خام باشد.

QR باید یک token قابل کنترل باشد:

```text
qr_token
```

این token:

- به Customer وصل است
- قابل expire شدن است
- قابل revoke/rotate شدن است
- برای Staff فقط resolve می‌شود، نه اینکه خودش identity/auth باشد

## تصمیم‌های طراحی

### QR Token چیست؟

QR Token یک شناسه تصادفی امن است که به Customer وصل می‌شود.

در MVP:

```text
Customer -> CustomerQrToken -> QR payload
```

QR payload برای اپ/پنل می‌تواند این باشد:

```text
zomia://customer/{token}
```

یا برای API:

```text
token string
```

### آیا QR Token جای JWT است؟

نه.

JWT برای authentication است.

QR Token فقط customer lookup است.

```text
Staff JWT
QR Token
-> Resolve Customer for service
```

### چه کسی می‌تواند QR بسازد؟

در MVP:

- Customer می‌تواند QR active خودش را بگیرد
- اگر token active ندارد، سیستم می‌سازد
- Customer می‌تواند token خودش را rotate کند

Owner و Staff نباید برای Customer دلخواه QR بسازند.

### Staff بعد از Scan چه می‌بیند؟

Staff فقط وقتی summary می‌گیرد که عضو Business داده‌شده باشد.

Summary باید حداقل این‌ها را بدهد:

```text
customer
business_id
points
active_rewards
recent_actions
```

در MVP، active rewards فقط rewardهایی هستند که:

```text
business_id = target business
status = active
not expired
redeem_scope allows target business
```

### آیا Scan خودش Action ثبت می‌کند؟

نه.

Scan فقط customer را resolve می‌کند و summary می‌دهد.

Action Registration جداست، اما در Sprint 5 یک endpoint staff service اضافه می‌کنیم که از `qr_token` استفاده کند تا Staff مجبور نباشد `customer_id` خام بفرستد.

### آیا Reward Use از Scan Flow جداست؟

Reward Use قبلاً در Sprint 4 وجود دارد:

```text
POST /api/v1/staff/rewards/{reward_id}/use
```

در Sprint 5 یک endpoint راحت‌تر برای service context اضافه می‌کنیم:

```text
POST /api/v1/staff/service/rewards/{reward_id}/use
```

این endpoint همان business authorization و redeem rules را استفاده می‌کند، اما برای Staff Service Panel طراحی شده است.

## Architecture

ماژول جدید:

```text
backend/app/modules/qr/
  models.py
  schemas.py
  repository.py
  service.py
  router.py
  dependencies.py
```

چرا ماژول جدا؟

- QR identity concern نیست، چون JWT/auth نیست
- QR loyalty concern هم نیست، چون point/campaign/reward تولید نمی‌کند
- QR یک service entrypoint است که Customer را برای Staff Workflow resolve می‌کند

QR Service می‌تواند از LoyaltyService/Repository برای summary استفاده کند، اما نباید campaign/reward logic را دوباره پیاده کند.

## Database Schema

### customer_qr_tokens

```text
id
customer_id
token_hash
status
expires_at
last_used_at
created_at
revoked_at
```

Notes:

- token خام ذخیره نمی‌شود
- `token_hash` unique است
- status در MVP:

```text
active
revoked
expired
```

- در MVP برای هر Customer فقط یک active token کافی است
- expiration می‌تواند بلندمدت باشد، مثلا ۹۰ روز

## API Contracts

### Customer: Issue My QR Token

```text
POST /api/v1/customers/me/qr-token
```

Response:

```json
{
  "token": "raw-token-visible-once",
  "qr_payload": "zomia://customer/raw-token",
  "expires_at": "2026-09-10T00:00:00Z"
}
```

Rule:

- فقط Customer مجاز است
- token active قبلی revoke شود
- token جدید صادر شود

Implementation note:

برای اینکه token خام ذخیره نشود، endpoint صدور QR هر بار token جدید می‌سازد و token قبلی را revoke می‌کند.

```text
raw token فقط در response همان request دیده می‌شود.
در database فقط token_hash ذخیره می‌شود.
```

### Customer: Rotate My QR Token

```text
POST /api/v1/customers/me/qr-token/rotate
```

Rules:

- alias رفتاری برای issue کردن token جدید است
- token active قبلی revoke شود و token جدید صادر شود

### Staff: Resolve QR

```text
POST /api/v1/staff/qr/resolve
```

Request:

```json
{
  "business_id": "uuid",
  "token": "raw-token-from-qr"
}
```

Response:

```json
{
  "business_id": "uuid",
  "customer": {
    "id": "uuid",
    "full_name": "Ali",
    "email": "ali@example.com"
  },
  "points": 12,
  "active_rewards": [],
  "recent_actions": []
}
```

Rules:

- فقط Staff مجاز است
- Staff باید عضو Business باشد
- token باید active و not expired باشد
- `last_used_at` آپدیت شود

### Staff Service: Register Action By QR

```text
POST /api/v1/staff/service/actions
```

Request:

```json
{
  "business_id": "uuid",
  "qr_token": "raw-token-from-qr",
  "idempotency_key": "unique-key",
  "items": [
    {
      "mission_id": "uuid",
      "quantity": 1
    }
  ],
  "note": "Checkout"
}
```

Behavior:

```text
Resolve QR -> customer_id
Call existing action registration logic
Return updated service summary
```

### Staff Service: Use Reward

```text
POST /api/v1/staff/service/rewards/{reward_id}/use
```

Request:

```json
{
  "business_id": "uuid",
  "qr_token": "raw-token-from-qr",
  "idempotency_key": "unique-key",
  "note": "Used at checkout"
}
```

Behavior:

```text
Resolve QR -> customer_id
Verify reward belongs to resolved customer
Call existing reward use logic
Return updated service summary
```

## Service Flow

### QR Resolve

```text
Staff authenticated
-> Verify staff membership in business
-> Hash QR token
-> Load active token
-> Verify not expired
-> Load customer
-> Load points and active rewards for business
-> Return staff service summary
```

### Register Action By QR

```text
Resolve QR
-> Existing LoyaltyService.register_action
-> Campaign evaluation
-> Reward generation
-> Return updated service summary
```

### Use Reward By QR

```text
Resolve QR
-> Verify reward.customer_id == resolved customer_id
-> Existing LoyaltyService.use_reward
-> Return updated service summary
```

## Security Notes

- QR token must be random and high entropy
- Store only token hash
- Staff JWT is always required
- QR token alone cannot mutate state
- QR resolve is scoped by `business_id` and staff membership
- Rotate/revoke must invalidate old token

## Tests

Sprint 5 باید تست داشته باشد برای:

- Customer can issue QR token
- Customer can rotate QR token
- Old QR token stops working after rotate
- Staff can resolve valid QR for own business
- Staff cannot resolve QR for business where they are not member
- Expired/revoked QR cannot be resolved
- Staff can register action using QR token
- Register action by QR generates points/campaign/reward as existing flow
- Staff can use reward using QR service endpoint
- Staff cannot use reward by QR if reward belongs to another customer

## Migration Requirements

Migration باید بسازد:

- `customer_qr_tokens`

Migration باید اضافه کند:

- Enum `customer_qr_token_status`
- Unique constraint روی `token_hash`
- Index روی `customer_id`
- Index روی `status`
- Index روی `expires_at`

## Exit Criteria

Sprint 5 وقتی بسته می‌شود که:

- Customer بتواند QR token بگیرد
- Staff بتواند QR را resolve کند
- Staff service summary برگردد
- Staff بتواند Action را با QR ثبت کند
- Staff بتواند Reward را با QR use کند
- تست‌ها پاس شوند
- Migration روی PostgreSQL واقعی اجرا شود
- OpenAPI endpointهای Sprint 5 را نشان دهد

## Implementation Result

Sprint 5 پیاده‌سازی و verify شد.

پیاده‌سازی انجام‌شده:

- ماژول `backend/app/modules/qr/` اضافه شد
- مدل `customer_qr_tokens` اضافه شد
- Migration `0006_qr_tokens` اضافه و روی PostgreSQL واقعی اجرا شد
- endpointهای Customer برای issue/rotate کردن QR اضافه شد
- endpointهای Staff برای resolve، action registration و reward use با QR اضافه شد
- QR token خام فقط در response صدور token دیده می‌شود
- database فقط `token_hash` را نگه می‌دارد
- Staff authorization بر اساس Staff Membership در Business انجام می‌شود
- Reward Use با QR بررسی می‌کند reward متعلق به Customer resolved شده باشد

Verification:

- `35` تست backend پاس شد
- `ruff check` پاس شد
- Alembic روی revision `0006_qr_tokens (head)` قرار گرفت
- smoke test واقعی با PostgreSQL انجام شد:
  - Owner/Staff/Customer ساخته شد
  - Customer QR صادر شد
  - Staff QR را resolve کرد
  - Staff با QR Action ثبت کرد
  - Campaign completion باعث Generated Reward شد
  - Staff با QR Reward را use کرد
  - Points Ledger بعد از Reward Use تغییر نکرد
