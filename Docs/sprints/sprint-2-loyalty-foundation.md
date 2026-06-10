# Sprint 2: Loyalty Foundation

## هدف Sprint

هدف Sprint 2 ساخت پایه وفاداری است، نه ساخت Campaign و Reward.

در پایان این Sprint سیستم باید بتواند:

```text
Owner یک Mission تعریف کند
Staff یک Action برای Customer ثبت کند
سیستم duplicate request را با Idempotency کنترل کند
سیستم Point را در Points Ledger ثبت کند
سیستم رویدادهای مهم را در Basic Audit ثبت کند
```

## چرا این Sprint مهم است

Campaign و Reward فقط وقتی معنی دارند که سیستم قبلاً بتواند رفتار واقعی مشتری را درست، قابل اعتماد و قابل audit ثبت کند.

اگر Mission، Action، Points Ledger و Idempotency درست طراحی نشوند، Sprintهای بعدی روی داده‌های ناپایدار ساخته می‌شوند.

## داخل Sprint 2

- Mission model
- Action model
- Points Ledger model
- Action Idempotency model
- Basic Audit Event model
- Owner API برای ساخت و دیدن Missionها
- Staff API برای ثبت Action
- Customer API برای دیدن point balance
- تست‌های role access، idempotency و ledger
- Alembic migration

## خارج از Sprint 2

- Campaign Evaluation
- Reward Generation
- QR Scan واقعی
- Frontend
- Analytics
- Group Campaign
- Cross-Network Campaign

## تعریف مفاهیم

### Mission

Mission یعنی تعریف رفتاری که Business می‌خواهد به آن امتیاز بدهد.

مثال:

```text
Buy Coffee = 1 point
Visit Store = 1 point
Refer Friend = 5 points
```

Mission خودش رخداد نیست. Mission فقط قانون و تعریف است.

### Action

Action یعنی ثبت اینکه Customer واقعاً یک Mission را انجام داده است.

مثال:

```text
Staff Sara ثبت کرد که Customer Ali امروز Mission Buy Coffee را انجام داده است.
```

Action باید بعداً قابل audit باشد. در MVP آن را edit نمی‌کنیم؛ اگر correction لازم شد، در آینده با action اصلاحی یا ledger entry اصلاحی حل می‌شود.

### Points Ledger

Points Ledger دفتر append-only تغییرات امتیاز است.

به جای اینکه فقط یک عدد مثل `total_points` ذخیره کنیم، هر تغییر امتیاز را جدا ثبت می‌کنیم:

```text
+1 because Buy Coffee action was recorded
+5 because Refer Friend action was recorded
-10 because Reward was used
```

در Sprint 2 فقط pointهای مثبت از Action ثبت می‌شوند. مصرف امتیاز و Reward در Sprintهای بعدی می‌آید.

### Idempotency

Idempotency یعنی یک request تکراری نباید Action و Point تکراری بسازد.

مثال:

```text
Staff دکمه Register Action را می‌زند
ارتباط کند است
اپ همان request را دوباره می‌فرستد
```

اگر `idempotency_key` یکسان باشد، سیستم باید همان Action قبلی را برگرداند و Action جدید نسازد.

### Basic Audit

Audit یعنی ثبت اتفاقات مهم سیستم.

برای Sprint 2 حداقل این eventها لازم‌اند:

- `MISSION_CREATED`
- `ACTION_RECORDED`
- `POINTS_GRANTED`
- `IDEMPOTENCY_REPLAYED`

Audit با Points Ledger فرق دارد:

- Points Ledger حساب امتیاز است
- Audit تاریخچه اتفاقات سیستم است

## Architecture

ماژول جدید:

```text
backend/app/modules/loyalty/
  models.py
  schemas.py
  repository.py
  service.py
  router.py
```

قواعد معماری:

- Router فقط API contract و dependencyها را مدیریت می‌کند
- Service منطق تجاری را اجرا می‌کند
- Repository دسترسی دیتابیس را جدا می‌کند
- Points Ledger فقط append می‌شود
- Idempotency داخل Service enforce می‌شود
- Audit Event در همان transaction ثبت می‌شود

## Database Schema

### missions

```text
id
business_id
name
description
mission_type
point_value
is_active
created_at
updated_at
```

Notes:

- `business_id` به `businesses.id` وصل است
- `mission_type` در MVP می‌تواند ساده باشد: `purchase`, `visit`, `referral`, `custom`
- `point_value` باید مثبت باشد

### loyalty_actions

```text
id
business_id
customer_id
staff_id
mission_id
idempotency_key
occurred_at
note
created_at
```

Notes:

- `customer_id` به `users.id` وصل است و باید role آن `customer` باشد
- `staff_id` به `users.id` وصل است و باید role آن `staff` باشد
- `mission_id` به `missions.id` وصل است
- ترکیب `business_id + idempotency_key` باید unique باشد

### points_ledger

```text
id
business_id
customer_id
action_id
points_delta
reason
created_at
```

Notes:

- در Sprint 2 فقط `points_delta > 0` داریم
- `action_id` به `loyalty_actions.id` وصل است
- این جدول append-only است

### audit_events

```text
id
event_type
actor_user_id
business_id
entity_type
entity_id
metadata
created_at
```

Notes:

- `metadata` بهتر است JSONB باشد
- Audit نباید جایگزین domain tables شود

## API Contracts

### Owner: Create Mission

```text
POST /api/v1/owner/missions
```

Request:

```json
{
  "business_id": "uuid",
  "name": "Buy Coffee",
  "description": "Customer buys one coffee",
  "mission_type": "purchase",
  "point_value": 1
}
```

Rules:

- فقط Owner مجاز است
- Owner فقط برای Business خودش Mission می‌سازد
- `point_value` باید مثبت باشد

### Owner: List Missions

```text
GET /api/v1/owner/missions?business_id=uuid
```

Rules:

- فقط Owner مجاز است
- فقط Missionهای Business متعلق به همان Owner برگردد

### Staff: Register Action

```text
POST /api/v1/staff/actions
```

Request:

```json
{
  "business_id": "uuid",
  "customer_id": "uuid",
  "mission_id": "uuid",
  "idempotency_key": "client-generated-uuid",
  "occurred_at": "2026-06-10T12:00:00Z",
  "note": "Optional staff note"
}
```

Response:

```json
{
  "action_id": "uuid",
  "points_granted": 1,
  "idempotency_replayed": false
}
```

Rules:

- فقط Staff مجاز است
- Staff باید عضو همان Business باشد
- Customer باید role `customer` داشته باشد
- Mission باید متعلق به همان Business و active باشد
- اگر `idempotency_key` قبلاً استفاده شده باشد، Action قبلی برگردد و Point جدید ساخته نشود

### Customer: My Points

```text
GET /api/v1/customers/me/points?business_id=uuid
```

Rules:

- فقط Customer مجاز است
- balance از `sum(points_delta)` محاسبه شود
- در Sprint 2 نیاز به aggregate table نداریم

## Service Flow

### Register Action Flow

```text
Start transaction
-> Verify current user is Staff
-> Verify Staff belongs to Business
-> Check idempotency key for Business
   -> If exists: return previous Action result
-> Verify Customer role
-> Verify Mission belongs to Business and is active
-> Create Action
-> Create Points Ledger entry
-> Create Audit Event ACTION_RECORDED
-> Create Audit Event POINTS_GRANTED
-> Commit transaction
```

## Business Rules

- Mission point value must be positive
- Staff cannot register actions for businesses they do not belong to
- Owner cannot manage missions for another owner’s business
- A duplicate `idempotency_key` must not create a second Action
- Points Ledger entries are never updated or deleted in normal flow
- Action registration and ledger entry must be in the same transaction

## Tests

Sprint 2 must include tests for:

- Owner creates mission for own business
- Owner cannot create mission for another owner’s business
- Staff registers action for customer
- Action creates one Points Ledger entry
- Duplicate idempotency key returns previous result
- Duplicate idempotency key does not create extra points
- Customer can read own point balance
- Customer cannot register action
- Staff cannot register action for another business

## Migration Requirements

Migration must create:

- `missions`
- `loyalty_actions`
- `points_ledger`
- `audit_events`

Migration must include:

- Foreign keys
- Indexes for common lookup fields
- Unique constraint on `business_id + idempotency_key`

## Open Questions

Before implementation, confirm:

- آیا `idempotency_key` باید در header باشد یا body؟ پیشنهاد فعلی: body برای سادگی MVP.
- آیا Customer باید قبل از Action عضو Business شود؟ پیشنهاد Sprint 2: نه، فقط Customer role کافی است. Participation در Sprintهای Campaign می‌آید.
- آیا Mission type را enum کنیم؟ پیشنهاد فعلی: enum محدود با `purchase`, `visit`, `referral`, `custom`.

## Exit Criteria

Sprint 2 وقتی بسته می‌شود که:

- Migration روی PostgreSQL واقعی اجرا شود
- تست‌ها پاس شوند
- OpenAPI endpointهای Sprint 2 را نشان دهد
- Staff بتواند Action ثبت کند
- Points Ledger برای Action ساخته شود
- duplicate request با idempotency کنترل شود
- Audit Eventهای پایه ثبت شوند

