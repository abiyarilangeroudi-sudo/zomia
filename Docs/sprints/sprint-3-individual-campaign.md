# Sprint 3: Individual Campaign

## هدف Sprint

هدف Sprint 3 ساخت پایه Campaign Evaluation برای Individual Campaign است.

در پایان این Sprint سیستم باید بتواند:

```text
Owner یک Individual Campaign تعریف کند
Campaign به Missionهای مشخص وصل شود
Actionهای جدید بتوانند Campaign Evaluation را trigger کنند
سیستم progress مشتری را از Points Ledger محاسبه کند
اگر threshold کامل شد، Campaign Completion ثبت شود
```

Sprint 3 هنوز Reward واقعی نمی‌سازد. Reward Engine در Sprint 4 می‌آید.

## تعریف Campaign

Campaign یک قانون وفاداری زمان‌دار است که در context یک کسب‌وکار ساخته می‌شود و روی یک محدوده مشارکت مشخص اعمال می‌شود.

Scope کمپین تعیین می‌کند کدام کسب‌وکارها، Missionها، مشتری‌ها، گروه‌ها و Actionها برای progress معتبر هستند.

برای Sprint 3 فقط Individual Campaign پیاده‌سازی می‌شود:

```text
progress_subject = customer
scope_type = single_business
participation_mode = automatic
progress_metric = points
```

## داخل Sprint 3

- Campaign model
- Campaign Mission relation
- Campaign Completion model
- Owner API برای ساخت Campaign
- Owner API برای دیدن Campaignها
- Campaign Evaluation بعد از Action Registration
- Basic Audit Event برای completion
- تست‌های campaign progress و threshold
- Alembic migration

## خارج از Sprint 3

- Reward Generation
- Reward Template
- Reward Usage
- Group Campaign
- Cross-Network Campaign
- Fans Group
- Business Club
- Frontend

## تصمیم‌های طراحی

### Campaign به Missionها چطور وصل می‌شود؟

از طریق جدول واسط:

```text
campaign_missions
- campaign_id
- mission_id
```

Campaign به Missionها وابسته است، نه برعکس.

در Sprint 3 فقط Missionهای همان Business سازنده مجاز هستند. در آینده Cross Campaign می‌تواند Missionهای چند Business participant را از طریق scope معتبر کند.

### Progress مشتری چطور محاسبه می‌شود؟

برای Individual Campaign:

```text
progress = sum(points)
from points_ledger
join loyalty_action_items
join loyalty_actions
where customer_id = target customer
and action_item.mission_id in campaign_missions
and loyalty_action.business_id in eligible campaign businesses
and loyalty_action.occurred_at between starts_at and ends_at
```

در Sprint 3 aggregate table نمی‌سازیم. Progress هنگام evaluation از ledger محاسبه می‌شود.

### اگر مشتری چند بار threshold را کامل کرد چه می‌شود؟

Schema باید آینده repeatable را نبندد، اما Sprint 3 فقط حالت non-repeatable را اجرا می‌کند.

فیلدهای پیشنهادی:

```text
is_repeatable
max_completions_per_customer
```

برای Sprint 3:

```text
is_repeatable = false
max_completions_per_customer = 1
```

اگر Customer قبلاً برای همان Campaign completion داشته باشد، completion جدید ساخته نمی‌شود.

### Campaign بر اساس points باشد یا quantity/action count؟

برای Sprint 3 فقط points.

فیلد:

```text
progress_metric = points
threshold_points
```

در آینده می‌توان `quantity` یا `action_count` اضافه کرد، چون Action Itemها quantity و Points Ledger امتیاز را نگه می‌دارند.

### آیا Campaign زمان شروع و پایان دارد؟

بله.

```text
starts_at
ends_at
```

Rule:

```text
فقط Actionهایی حساب می‌شوند که occurred_at بین starts_at و ends_at باشند.
```

### آیا Customer باید explicit participate کند؟

برای Sprint 3 نه.

```text
participation_mode = automatic
```

هر Action مرتبط با Missionهای Campaign به صورت خودکار برای progress حساب می‌شود.

در آینده:

```text
explicit
group_membership
```

می‌تواند برای Cross یا Group اضافه شود.

### خروجی Sprint 3 چیست؟

خروجی Sprint 3 `Campaign Completion` است، نه Reward.

یعنی سیستم ثبت می‌کند:

```text
Customer X در Campaign Y به threshold رسید
```

Sprint 4 از completionهای بدون reward استفاده می‌کند و Reward واقعی می‌سازد.

## Architecture

ماژول موجود `loyalty` گسترش پیدا می‌کند:

```text
backend/app/modules/loyalty/
  models.py
  schemas.py
  repository.py
  service.py
  router.py
```

قواعد معماری:

- Campaign Evaluation داخل Service انجام می‌شود
- Router فقط contract را نگه می‌دارد
- Campaign Completion در همان transaction ثبت Action ساخته می‌شود
- Reward Engine هنوز وجود ندارد
- Mission مستقل از Campaign می‌ماند

## Database Schema

### campaigns

```text
id
creator_business_id
name
description
campaign_type
scope_type
participation_mode
progress_metric
threshold_points
is_repeatable
max_completions_per_customer
status
starts_at
ends_at
created_at
updated_at
```

Notes:

- `campaign_type` در Sprint 3 فقط `individual`
- `scope_type` در Sprint 3 فقط `single_business`
- `participation_mode` در Sprint 3 فقط `automatic`
- `progress_metric` در Sprint 3 فقط `points`
- `threshold_points` باید مثبت باشد
- `creator_business_id` کسب‌وکاری است که Campaign را ساخته است

### campaign_missions

```text
id
campaign_id
mission_id
created_at
```

Notes:

- Campaign به Missionها وصل می‌شود
- Mission به Campaign وابسته نیست
- ترکیب `campaign_id + mission_id` باید unique باشد

### campaign_completions

```text
id
campaign_id
customer_id
progress_points
threshold_points
completion_number
completed_at
reward_generated_at
created_at
```

Notes:

- `reward_generated_at` در Sprint 3 همیشه `null` می‌ماند
- Sprint 4 بعداً با Reward Engine آن را استفاده می‌کند
- برای non-repeatable campaign فقط یک completion برای هر `campaign_id + customer_id` ساخته می‌شود

### future_campaign_businesses

این جدول در Sprint 3 ساخته نمی‌شود مگر implementation ساده نگه دارد. این قرارداد مفهومی آینده برای Cross Campaign است.

```text
id
campaign_id
business_id
role
created_at
```

Roles:

```text
creator
participant
```

برای Individual Campaign، scope همان `creator_business_id` است.

## API Contracts

### Owner: Create Campaign

```text
POST /api/v1/owner/campaigns
```

Request:

```json
{
  "creator_business_id": "uuid",
  "name": "Coffee Lover",
  "description": "Earn reward eligibility after 10 coffee points",
  "threshold_points": 10,
  "starts_at": "2026-06-10T00:00:00Z",
  "ends_at": "2026-07-10T00:00:00Z",
  "mission_ids": ["uuid"]
}
```

Rules:

- فقط Owner مجاز است
- Owner فقط برای Business خودش Campaign می‌سازد
- Missionها باید متعلق به همان Business باشند
- `threshold_points` باید مثبت باشد
- `starts_at < ends_at`

### Owner: List Campaigns

```text
GET /api/v1/owner/campaigns?business_id=uuid
```

Rules:

- فقط Owner مجاز است
- فقط Campaignهای Business همان Owner برگردد

### Customer: My Campaign Progress

```text
GET /api/v1/customers/me/campaigns/{campaign_id}/progress
```

Response:

```json
{
  "campaign_id": "uuid",
  "customer_id": "uuid",
  "progress_points": 7,
  "threshold_points": 10,
  "is_completed": false
}
```

Rules:

- فقط Customer مجاز است
- progress از Points Ledger محاسبه شود

## Service Flow

### After Action Registration

در پایان `POST /api/v1/staff/actions`:

```text
Action and Action Items created
-> Points Ledger entries created
-> Load active individual campaigns for business
-> Match campaign missions with action item missions
-> For affected campaigns, calculate customer progress
-> If threshold reached and completion does not exist:
   -> Create Campaign Completion
   -> Create Audit Event CAMPAIGN_COMPLETED
```

## Business Rules

- Campaign must have at least one Mission
- Mission must belong to eligible campaign scope
- Sprint 3 supports only `individual`
- Sprint 3 supports only `single_business`
- Sprint 3 supports only `automatic` participation
- Sprint 3 supports only `points` progress metric
- Sprint 3 creates completion, not reward
- Non-repeatable Campaign creates at most one completion per customer
- Campaign Evaluation only counts Actions inside campaign time window

## Tests

Sprint 3 must include tests for:

- Owner creates individual campaign with mission
- Owner cannot use another owner’s mission
- Action triggers campaign evaluation
- Progress below threshold does not create completion
- Progress reaching threshold creates completion
- Duplicate idempotency replay does not create duplicate completion
- Customer can read campaign progress
- Action outside campaign time window does not count
- Non-repeatable campaign creates only one completion

## Migration Requirements

Migration must create:

- `campaigns`
- `campaign_missions`
- `campaign_completions`

Migration must include:

- Foreign keys
- Indexes for lookup fields
- Unique constraint on `campaign_id + mission_id`
- Unique constraint for non-repeatable MVP completion: `campaign_id + customer_id`

## Exit Criteria

Sprint 3 وقتی بسته می‌شود که:

- Migration روی PostgreSQL واقعی اجرا شود
- تست‌ها پاس شوند
- OpenAPI endpointهای Sprint 3 را نشان دهد
- Owner بتواند Campaign بسازد
- Action بتواند Campaign Evaluation را trigger کند
- Threshold completion ثبت شود
- Reward ساخته نشود

