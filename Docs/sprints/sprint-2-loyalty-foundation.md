# Sprint 2: Loyalty Foundation

## هدف Sprint

هدف Sprint 2 ساخت پایه وفاداری است، نه ساخت Campaign و Reward.

در پایان این Sprint سیستم باید بتواند:

```text
Owner یک Mission تعریف کند
Staff یک Action برای Customer ثبت کند
سیستم duplicate request را با Idempotency کنترل کند
سیستم Pointهای حاصل از itemهای Action را در Points Ledger ثبت کند
سیستم رویدادهای مهم را در Basic Audit ثبت کند
```

## چرا این Sprint مهم است

Campaign و Reward فقط وقتی معنی دارند که سیستم قبلاً بتواند رفتار واقعی مشتری را درست، قابل اعتماد و قابل audit ثبت کند.

اگر Mission، Action، Points Ledger و Idempotency درست طراحی نشوند، Sprintهای بعدی روی داده‌های ناپایدار ساخته می‌شوند.

## داخل Sprint 2

- Mission model
- Action model
- Action Item model
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

Action یعنی ثبت یک عملیات واقعی برای Customer.

یک Action می‌تواند فقط یک Mission داشته باشد، یا چند Mission را همزمان ثبت کند.

مثال:

```text
Staff Sara ثبت کرد که Customer Ali امروز ۲ Coffee و ۱ Cake خرید.
```

در این مثال یک Action داریم، اما چند Action Item:

```text
Action
  item 1: Buy Coffee x 2 -> 2 points
  item 2: Buy Cake x 1 -> 5 points
```

Action یک envelope عملیاتی است. Missionها داخل Action Itemها می‌آیند.

در آینده یک Action می‌تواند از نوع `reward_use` هم باشد؛ یعنی عملیات فقط مصرف Reward را ثبت کند و هیچ Point جدیدی نسازد.

Action باید بعداً قابل audit باشد. در MVP آن را edit نمی‌کنیم؛ اگر correction لازم شد، در آینده با action اصلاحی حل می‌شود.

### Points Ledger

Points Ledger دفتر append-only امتیازهای کسب‌شده است.

به جای اینکه فقط یک عدد مثل `total_points` ذخیره کنیم، هر امتیاز کسب‌شده را جدا ثبت می‌کنیم:

```text
+2 because Buy Coffee x 2 was recorded
+5 because Buy Cake x 1 was recorded
```

Zomia مدل Wallet/Credit Economy ندارد. پس Reward Use باعث کم شدن Point نمی‌شود.

در Sprint 2 و مسیر محصول فعلی، Points Ledger فقط امتیازهای earned/progress را ثبت می‌کند. Reward Use در آینده فقط وضعیت Reward را تغییر می‌دهد و Audit Event ایجاد می‌کند.

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
action_type
idempotency_key
occurred_at
note
created_at
```

Notes:

- `customer_id` به `users.id` وصل است و باید role آن `customer` باشد
- `staff_id` به `users.id` وصل است و باید role آن `staff` باشد
- `action_type` در Sprint 2 مقدار `mission_progress` دارد
- در آینده `action_type` می‌تواند `reward_use` هم باشد
- ترکیب `business_id + idempotency_key` باید unique باشد

### loyalty_action_items

```text
id
action_id
mission_id
quantity
unit_points
total_points
created_at
```

Notes:

- `action_id` به `loyalty_actions.id` وصل است
- `mission_id` به `missions.id` وصل است
- هر item یک Mission انجام‌شده داخل Action است
- `quantity` تعداد انجام Mission را ثبت می‌کند
- `unit_points` snapshot مقدار point هر Mission در زمان ثبت است
- `total_points = quantity * unit_points`
- snapshot لازم است چون ممکن است Owner بعداً `point_value` Mission را تغییر دهد

### points_ledger

```text
id
business_id
customer_id
action_id
action_item_id
points
reason
created_at
```

Notes:

- `points` همیشه مثبت است
- `action_id` به `loyalty_actions.id` وصل است
- `action_item_id` به `loyalty_action_items.id` وصل است
- این جدول append-only است
- این جدول Wallet نیست و deduction ندارد

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
  "idempotency_key": "client-generated-uuid",
  "occurred_at": "2026-06-10T12:00:00Z",
  "note": "Optional staff note",
  "items": [
    {
      "mission_id": "uuid-for-buy-coffee",
      "quantity": 2
    },
    {
      "mission_id": "uuid-for-buy-cake",
      "quantity": 1
    }
  ]
}
```

Response:

```json
{
  "action_id": "uuid",
  "points_granted": 7,
  "idempotency_replayed": false
}
```

Rules:

- فقط Staff مجاز است
- Staff باید عضو همان Business باشد
- Customer باید role `customer` داشته باشد
- همه Missionهای داخل `items` باید متعلق به همان Business و active باشند
- `items` برای action type فعلی باید حداقل یک item داشته باشد
- `quantity` باید مثبت باشد
- اگر `idempotency_key` قبلاً استفاده شده باشد، Action قبلی برگردد و Point جدید ساخته نشود

### Customer: My Points

```text
GET /api/v1/customers/me/points?business_id=uuid
```

Rules:

- فقط Customer مجاز است
- balance از `sum(points)` محاسبه شود
- در Sprint 2 نیاز به aggregate table نداریم
- این balance فقط earned/progress points است، نه کیف پول قابل خرج کردن

## Service Flow

### Register Action Flow

```text
Start transaction
-> Verify current user is Staff
-> Verify Staff belongs to Business
-> Check idempotency key for Business
   -> If exists: return previous Action result
-> Verify Customer role
-> Verify every Action Item mission belongs to Business and is active
-> Create Action
-> Create Action Items
-> Create one Points Ledger entry per Action Item
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
- Action, Action Items, ledger entries and audit events must be in the same transaction
- Mission is independent from Campaign
- Campaigns depend on Missions, Actions and Points Ledger
- Reward Use does not deduct Points
- Zomia does not have Wallet/Credit Economy

## Future Campaign Compatibility

Sprint 2 کمپین را پیاده‌سازی نمی‌کند، اما داده‌های آن باید برای Campaignهای آینده قابل استفاده باشند.

### Individual Campaign

Campaign می‌تواند progress یک Customer را از روی Action Itemها و Points Ledger بخواند.

مثال:

```text
Buy Coffee x 10 -> Gift
```

### Cross-Network Campaign

در Cross Campaign، Mission همچنان مستقل از Campaign می‌ماند.

Campaign بعداً روی Businessها و Missionهای مجاز rule تعریف می‌کند.

حالت ۱: مشتری باید از چند Business مشخص امتیاز بگیرد:

```text
required_partner_count = 3
minimum_points_per_partner = 1
```

حالت ۲: مشتری می‌تواند از هر کدام از Businessهای partner امتیاز جمع کند:

```text
total_points_required = 10
partner_requirement = none
```

هر دو حالت با `business_id`, `mission_id`, `customer_id` و Points Ledger قابل محاسبه‌اند.

### Group Campaign

در Group Campaign، Campaign بعداً می‌تواند مشارکت اعضای Fans Group را از روی earned points محاسبه کند.

مثال:

```text
در بازه زمانی کمپین، حداقل 20 عضو Fans Group هرکدام حداقل 1 point کسب کنند.
```

این rule با query روی Action Itemها و Points Ledger قابل محاسبه است و نیاز به وابسته کردن Mission به Campaign ندارد.

## Tests

Sprint 2 must include tests for:

- Owner creates mission for own business
- Owner cannot create mission for another owner’s business
- Staff registers action with one item for customer
- Staff registers action with multiple items for customer
- Action creates one Points Ledger entry per item
- Multi-item action returns total points granted
- Duplicate idempotency key returns previous result
- Duplicate idempotency key does not create extra points
- Customer can read own point balance
- Customer cannot register action
- Staff cannot register action for another business
- Inactive Mission cannot be used in Action Item

## Migration Requirements

Migration must create:

- `missions`
- `loyalty_actions`
- `loyalty_action_items`
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
- آیا `action_type = reward_use` را از همین Sprint در enum بگذاریم؟ پیشنهاد فعلی: فقط اگر schema را ساده نگه دارد؛ API مصرف Reward در Sprint 4 می‌آید.

## Exit Criteria

Sprint 2 وقتی بسته می‌شود که:

- Migration روی PostgreSQL واقعی اجرا شود
- تست‌ها پاس شوند
- OpenAPI endpointهای Sprint 2 را نشان دهد
- Staff بتواند Action ثبت کند
- Staff بتواند Action چند آیتمی ثبت کند
- Points Ledger برای هر Action Item ساخته شود
- duplicate request با idempotency کنترل شود
- Audit Eventهای پایه ثبت شوند
