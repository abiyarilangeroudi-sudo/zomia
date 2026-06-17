# Sprint 4: Reward Engine

## هدف Sprint

هدف Sprint 4 ساخت Reward Engine ساده اما آینده‌نگر است.

در پایان این Sprint سیستم باید بتواند:

```text
Owner بتواند Reward Template مستقل تعریف کند و Campaign هنگام ساخت یک Template انتخاب کند
Campaign Completion بتواند Generated Reward بسازد
Customer بتواند Rewardهای خودش را ببیند
Staff بتواند Reward فعال را use کند
Reward status از active به used یا expired تغییر کند
```

Reward Engine هیچ Wallet یا Credit Economy نمی‌سازد.

Points در Zomia فقط progress/earned points هستند. Reward Use باعث کم شدن Point نمی‌شود.

## تعریف Reward

Reward نتیجه قابل استفاده‌ای است که بعد از کامل شدن یک Campaign برای یک Customer صادر می‌شود.

Reward خودش lifecycle دارد و مستقل از Points Ledger مدیریت می‌شود.

```text
Campaign Completion
-> Reward Template
-> Generated Reward
-> Reward Usage
```

## مفاهیم اصلی

### Reward Template

Reward Template تعریف پاداش توسط Owner است.

مثال:

```text
Reward Template: 1 free coffee
```

یا:

```text
Reward Template: 10% discount
```

Template توسط یک Business تعریف/صادر می‌شود و مستقل از Campaign می‌ماند.

Campaign بعداً از طریق `campaign_reward_templates` یک Template را انتخاب می‌کند. در MVP برای هر Campaign فقط یک Template مجاز است.

برای جلوگیری از ابهام در Cross Campaign، Reward Template سه مفهوم را از هم جدا می‌کند:

```text
issuer_business_id
redeem_scope
settlement_policy
```

در Sprint 4 همه این‌ها به ساده‌ترین حالت تنظیم می‌شوند:

```text
issuer_business_id = business_id
redeem_scope = issuer_business_only
settlement_policy = issuer_pays
```

اما همین مرزبندی باعث می‌شود در آینده بتوانیم Reward مشترک چند Business را بدون شکستن مدل اضافه کنیم.

### Generated Reward

Generated Reward پاداش واقعی صادر شده برای یک Customer است.

مثال:

```text
Ali completed Campaign X
System generated Reward Y for Ali
```

Generated Reward باید به یک generation source وصل باشد تا صدور پاداش idempotent باشد.

در Sprint 4:

```text
source_type = individual_campaign_completion
source_id = campaign_completion_id
```

برای آینده Group Campaign:

```text
source_type = group_campaign_completion
source_id = group_completion_id
```

Generated Reward همیشه برای یک Customer صادر می‌شود، اما یک source گروهی می‌تواند برای چند Customer پاداش بسازد.

### Reward Usage

Reward Usage ثبت مصرف یک Generated Reward است.

Reward Usage:

- به Staff و Business محل مصرف وصل است
- زمان مصرف را نگه می‌دارد
- می‌تواند داخل یک Action ثبت شود یا به Action لینک شود
- Point کم نمی‌کند
- Points Ledger entry نمی‌سازد

در Cross Campaign، Business محل مصرف ممکن است با Business صادرکننده Reward فرق داشته باشد. به همین دلیل در Reward Usage از عبارت `redeemed_business_id` استفاده می‌کنیم، نه فقط `business_id`.

## Cross Campaign Concerns

برای Cross Campaign سه ابهام اصلی وجود دارد:

```text
1. کدام Staff اجازه دارد Reward را use کند؟
2. کدام Reward Template بین چند Business قابل استفاده است؟
3. هزینه Reward بین Businessها چطور محاسبه و تسویه می‌شود؟
```

پاسخ معماری این است که Reward نباید فقط یک `business_id` مبهم داشته باشد.

### Issuer

Issuer کسب‌وکاری است که Reward Template را تعریف یا صادر کرده است.

در MVP:

```text
issuer_business_id = business_id
```

در Cross Campaign آینده، issuer می‌تواند:

- Business سازنده Campaign باشد
- Business Club باشد
- یا یک participant مشخص که هزینه Reward را می‌پذیرد

### Redeem Scope

Redeem Scope تعیین می‌کند Reward کجا قابل مصرف است.

حالت‌ها:

```text
issuer_business_only
campaign_participants
selected_businesses
```

در MVP:

```text
redeem_scope = issuer_business_only
```

یعنی فقط Staff همان Business صادرکننده می‌تواند Reward را use کند.

در Cross آینده:

- اگر scope برابر `campaign_participants` باشد، Staff هر Business عضو Campaign می‌تواند Reward را use کند
- اگر scope برابر `selected_businesses` باشد، فقط Staff کسب‌وکارهای مشخص‌شده مجاز است

### Settlement Policy

Settlement Policy تعیین می‌کند هزینه Reward بعد از use شدن بر عهده چه کسی است.

حالت‌های آینده:

```text
issuer_pays
redeemer_pays
shared_pool
platform_settlement
```

در MVP:

```text
settlement_policy = issuer_pays
```

یعنی همان Business صادرکننده Reward مسئول هزینه است.

در Cross آینده، Reward Usage باید داده کافی برای settlement داشته باشد:

```text
issuer_business_id
redeemed_business_id
customer_id
reward_id
reward_type
discount_amount_minor
used_at
settlement_status
```

خود Settlement Engine خارج از MVP است، اما داده پایه باید از الان قابل ثبت باشد.

## Future Group Campaign Reward Issuance

در Group Campaign، completion الزاماً متعلق به یک Customer نیست.

مدل آینده:

```text
Group Campaign Completion
-> Reward Recipient Policy
-> Generated Reward per eligible Customer
```

Generated Reward همچنان برای یک Customer صادر می‌شود، اما source آن می‌تواند گروهی باشد:

```text
source_type = group_campaign_completion
source_id = group_completion_id
customer_id = eligible_customer_id
```

پس یک Group Completion می‌تواند چند Generated Reward بسازد، یکی برای هر Customer واجد شرایط.

### Reward Recipient Policy

Reward Recipient Policy تعیین می‌کند بعد از کامل شدن Group Campaign چه کسانی پاداش می‌گیرند.

گزینه‌های آینده:

```text
all_group_members
contributors_only
contributors_above_minimum
selected_members
```

مثال:

```text
اگر حداقل ۲۰ نفر از اعضای Group Fans
در بازه زمانی مشخص
هرکدام حداقل ۱ امتیاز بگیرند
کمپین کامل می‌شود.
```

بعد باید policy مشخص کند Reward برای چه کسانی صادر شود:

- همه اعضای Group Fans
- فقط همان مشارکت‌کننده‌ها
- فقط کسانی که حداقل شرط مشارکت را کامل کرده‌اند

این بخش در Sprint 4 پیاده‌سازی نمی‌شود، اما schema فعلی با `source_type + source_id + customer_id` آن را قفل نمی‌کند.

## رابطه با Campaign Completion

Sprint 3 خروجی را تا اینجا ساخت:

```text
Customer X در Campaign Y threshold را کامل کرد
```

Sprint 4 روی همین event کار می‌کند:

```text
CampaignCompletion without reward
-> Load Reward Template for Campaign
-> Generate Reward for Customer
-> Mark campaign_completion.reward_generated_at
```

قانون مهم:

برای هر ترکیب زیر فقط یک Generated Reward ساخته می‌شود:

```text
source_type + source_id + customer_id
```
```

در Individual Campaign این عملاً یعنی هر Customer از هر Individual Completion فقط یک Reward می‌گیرد.

در Group Campaign آینده، یک Group Completion می‌تواند برای چند Customer مختلف Reward بسازد.

این rule جلوی duplicate reward را در retry/idempotency می‌گیرد، بدون اینکه Group Campaign را قفل کند.

## Reward Types

Sprint 4 فقط سه نوع MVP را پشتیبانی می‌کند:

```text
gift
percentage_discount
fixed_discount
```

### Gift

پاداش کالایی یا خدماتی.

مثال:

```text
Free coffee
Free cake
```

### Percentage Discount

تخفیف درصدی.

مثال:

```text
10% off
```

### Fixed Discount

تخفیف مبلغ ثابت.

مثال:

```text
5 EUR off
```

## Reward Lifecycle

برای MVP:

```text
active -> used
active -> expired
```

در آینده ممکن است وضعیت‌های زیر اضافه شود:

```text
pending
cancelled
settled
```

`pending` برای Group Campaign و Cross-Network Campaign مفید است، چون شاید صدور نهایی به settlement یا تایید نیاز داشته باشد.

## تصمیم‌های طراحی

### آیا Reward به Point وابسته است؟

نه.

Point فقط progress را نشان می‌دهد. Reward از Campaign Completion صادر می‌شود.

```text
Points Ledger -> Campaign Progress -> Campaign Completion -> Reward
```

Reward Use هیچ entry منفی در Points Ledger ایجاد نمی‌کند.

### کدام Staff اجازه دارد Reward را use کند؟

برای Sprint 4:

```text
Staff باید عضو issuer_business_id باشد.
```

چون MVP فقط `issuer_business_only` را اجرا می‌کند.

برای Cross Campaign آینده:

```text
Staff باید عضو یکی از Businessهای مجاز در redeem scope باشد.
```

این یعنی authorization مصرف Reward به `redeem_scope` وابسته است، نه صرفاً به Business سازنده Campaign.

### کدام Template در Cross قابل مصرف است؟

فقط Templateهایی که صریحاً redeem scope مناسب دارند:

```text
campaign_participants
selected_businesses
```

یک Template معمولی با `issuer_business_only` حتی اگر Campaign از نوع Cross باشد، فقط در همان Business صادرکننده قابل مصرف است.

### هزینه Reward در Cross چطور مدیریت می‌شود؟

Sprint 4 هزینه را تسویه نمی‌کند، اما model باید داده لازم را نگه دارد.

برای MVP:

```text
settlement_policy = issuer_pays
settlement_status = not_required
```

برای آینده:

```text
Reward Usage
-> Settlement Record
-> Settlement Engine
-> Business payable/receivable report
```

پس Reward Use یک رویداد عملیاتی است و Settlement یک دامنه جداگانه آینده است.

### آیا هر Campaign باید Reward Template داشته باشد؟

برای MVP بله. Campaign هنگام ساخت باید یک Reward Template انتخاب کند.

در Sprint 4:

- Owner می‌تواند Reward Template مستقل بسازد
- Owner هنگام ساخت Campaign یک Reward Template انتخاب می‌کند
- اگر Campaign Completion رخ دهد و Template فعال باشد، Reward ساخته می‌شود

این مدل برای Group و Cross-Network Campaign آینده ابهام کمتری دارد، چون Campaign مسئول orchestration است و Reward Template فقط تعریف پاداش را نگه می‌دارد.

### Reward Generation چه زمانی اتفاق می‌افتد؟

در همان transaction ثبت Action و Campaign Evaluation.

Flow:

```text
Staff registers Action
-> Points Ledger entries are created
-> Campaign Evaluation creates Campaign Completion
-> Reward Engine creates Generated Reward from the Campaign-linked template
```

برای safety، Generated Reward با ترکیب `source_type + source_id + customer_id` unique می‌شود.

### آیا Reward Use باید Action باشد؟

در مدل دامنه، Reward Use یک عملیات واقعی در خدمت‌رسانی Staff است.

برای Sprint 4 دو چیز ثبت می‌شود:

- `reward_usages`
- تغییر status در `generated_rewards`

برای هماهنگی با Action model فعلی، Reward Usage می‌تواند به یک `loyalty_action` از نوع `reward_use` وصل شود.

اما در Sprint 4 این عملیات Point ایجاد نمی‌کند و Action Item ندارد.

### Expiration چطور کار می‌کند؟

برای MVP، هر Reward یک `expires_at` دارد.

در زمان خواندن یا استفاده:

- اگر `expires_at` گذشته باشد، Reward دیگر قابل استفاده نیست
- status می‌تواند به `expired` تغییر کند

Job زمان‌بندی‌شده برای expire کردن batch خارج از Sprint 4 است.

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

قواعد:

- Reward generation در Service انجام می‌شود
- Router فقط API contract را نگه می‌دارد
- Reward Template توسط Owner مدیریت می‌شود
- Generated Reward برای Customer قابل مشاهده است
- Reward Usage توسط Staff انجام می‌شود
- Points Ledger در Reward Use تغییر نمی‌کند

## Database Schema

### reward_templates

```text
id
business_id
issuer_business_id
name
description
reward_type
redeem_scope
settlement_policy
gift_name
discount_percent
discount_amount_minor
currency_code
valid_days
is_active
created_at
updated_at
```

Notes:

- `business_id` مالک مدیریتی Template در Sprint 4 است
- `issuer_business_id` کسب‌وکاری است که Reward را صادر می‌کند
- `redeem_scope` در Sprint 4 فقط `issuer_business_only`
- `settlement_policy` در Sprint 4 فقط `issuer_pays`
- `gift_name` فقط برای `gift`
- `discount_percent` فقط برای `percentage_discount` و به شکل عدد صحیح ۱ تا ۱۰۰ ذخیره می‌شود
- `discount_amount_minor` و `currency_code` فقط برای `fixed_discount`
- `discount_amount_minor` مقدار پول در کوچک‌ترین واحد ارز است؛ مثلا ۵ یورو یعنی `500`
- `valid_days` مدت اعتبار reward بعد از generation است

### campaign_reward_templates

```text
id
campaign_id
reward_template_id
created_at
```

Notes:

- Campaign از این جدول Reward Template خود را انتخاب می‌کند
- در MVP، `campaign_id` unique است؛ یعنی هر Campaign فقط یک Reward Template دارد
- این unique constraint بعداً می‌تواند برای multi-reward Campaign حذف شود

### generated_rewards

```text
id
reward_template_id
campaign_id
campaign_completion_id
source_type
source_id
business_id
issuer_business_id
customer_id
reward_type
redeem_scope
settlement_policy
title
description
status
gift_name
discount_percent
discount_amount_minor
currency_code
issued_at
expires_at
used_at
created_at
updated_at
```

Notes:

- `source_type` در Sprint 4 برابر `individual_campaign_completion` است
- `source_id` در Sprint 4 همان `campaign_completion_id` است
- برای Group Campaign آینده، `campaign_completion_id` می‌تواند null باشد و source به `group_campaign_completion` اشاره کند
- `business_id` در Sprint 4 همان Business مدیریتی/صادرکننده است
- `issuer_business_id` snapshot صادرکننده Reward است
- ترکیب `source_type + source_id + customer_id` باید unique باشد
- status در MVP: `active`, `used`, `expired`
- Snapshot فیلدهای template روی reward ذخیره می‌شود تا تغییر آینده Template پاداش‌های صادرشده قدیمی را خراب نکند

### reward_usages

```text
id
generated_reward_id
redeemed_business_id
issuer_business_id
customer_id
staff_id
action_id
used_at
note
settlement_status
created_at
```

Notes:

- `redeemed_business_id` محل مصرف Reward است
- در MVP، `redeemed_business_id = issuer_business_id`
- `settlement_status` در MVP برابر `not_required` است
- `generated_reward_id` باید unique باشد
- هر Generated Reward فقط یک بار use می‌شود
- `action_id` به `loyalty_actions` از نوع `reward_use` وصل می‌شود

### future_reward_redeemable_businesses

این جدول در Sprint 4 ساخته نمی‌شود مگر برای Cross لازم شود.

```text
id
reward_template_id
business_id
created_at
```

کاربرد آینده:

- وقتی `redeem_scope = selected_businesses`
- مشخص می‌کند Staff کدام Businessها اجازه use دارند

## API Contracts

### Owner: Create Reward Template

```text
POST /api/v1/owner/reward-templates
```

Request for gift:

```json
{
  "business_id": "uuid",
  "campaign_id": "uuid",
  "name": "Free Coffee",
  "description": "One free coffee after completing the campaign",
  "reward_type": "gift",
  "gift_name": "Free coffee",
  "valid_days": 30
}
```

Request for percentage discount:

```json
{
  "business_id": "uuid",
  "campaign_id": "uuid",
  "name": "Ten Percent Off",
  "reward_type": "percentage_discount",
  "discount_percent": 10,
  "valid_days": 14
}
```

Request for fixed discount:

```json
{
  "business_id": "uuid",
  "campaign_id": "uuid",
  "name": "Five Euro Off",
  "reward_type": "fixed_discount",
  "discount_amount_minor": 500,
  "currency_code": "EUR",
  "valid_days": 14
}
```

Rules:

- فقط Owner مجاز است
- Campaign باید متعلق به Business همان Owner باشد
- مقدارهای reward باید با reward_type سازگار باشند

### Owner: List Reward Templates

```text
GET /api/v1/owner/reward-templates?business_id=uuid
```

### Customer: My Rewards

```text
GET /api/v1/customers/me/rewards?business_id=uuid
```

Rules:

- فقط Customer مجاز است
- active/used/expired rewards برگردانده می‌شود

### Staff: Use Reward

```text
POST /api/v1/staff/rewards/{reward_id}/use
```

Request:

```json
{
  "business_id": "uuid",
  "idempotency_key": "use-reward-unique-key",
  "note": "Used at checkout"
}
```

در این request، `business_id` یعنی Business محل مصرف Reward. در Sprint 4 باید با `issuer_business_id` Reward یکی باشد.

Rules:

- فقط Staff مجاز است
- Staff باید عضو Business مجاز برای redeem باشد
- در Sprint 4، Business مجاز همان `issuer_business_id` است
- Reward باید متعلق به Customer باشد
- Reward باید `active` باشد
- Reward نباید expired باشد
- استفاده موفق status را `used` می‌کند
- Points Ledger تغییر نمی‌کند
- اگر همان `idempotency_key` تکرار شود، نتیجه مصرف قبلی برگردانده می‌شود و Reward دوباره use نمی‌شود

## Service Flow

### Reward Generation After Campaign Completion

```text
Campaign Completion created
-> Find active Reward Template for Campaign
-> If no template: stop
-> If reward already exists for completion: stop
-> Create Generated Reward snapshot
-> Set campaign_completion.reward_generated_at
-> Create audit event REWARD_GENERATED
```

### Reward Use

```text
Staff requests reward use
-> Verify staff membership
-> Check reward_use idempotency key
-> Load generated reward
-> Verify redeem scope/customer/status/expiration
-> Create loyalty_action type reward_use
-> Create reward_usage
-> Mark generated reward used
-> Create audit event REWARD_USED
```

## Tests

Sprint 4 تست دارد برای:

- Owner creates gift reward template
- Owner creates percentage discount reward template
- Owner creates fixed discount reward template
- Owner cannot create template for another owner’s campaign
- Action completing campaign generates reward when template exists
- Campaign completion without template does not generate reward
- Idempotency replay does not duplicate reward
- Customer can list own rewards
- Staff can use active reward
- Staff cannot use expired reward
- Staff cannot use reward from another business
- Used reward cannot be used twice
- Reward Use does not create Points Ledger entry
- Reward Usage records `redeemed_business_id`
- Reward Usage records settlement status as `not_required` in MVP

## Migration Requirements

Migration `0004_reward_engine` می‌سازد:

- `reward_templates`
- `generated_rewards`
- `reward_usages`

Migration اضافه می‌کند:

- Enumهای reward type و reward status
- Enumهای redeem scope، settlement policy، settlement status و reward generation source type
- Audit eventهای `reward_template_created`, `reward_generated`, `reward_used`, `reward_expired`
- Foreign keys
- Indexes برای business/customer/status/issuer/redeemed business
- Unique constraint روی `source_type + source_id + customer_id`
- Unique constraint روی `campaign_id` در `reward_templates`
- Unique constraint روی `generated_reward_id` در `reward_usages`

## Implementation Result

Implemented files:

- `backend/app/modules/loyalty/models.py`
- `backend/app/modules/loyalty/schemas.py`
- `backend/app/modules/loyalty/repository.py`
- `backend/app/modules/loyalty/service.py`
- `backend/app/modules/loyalty/router.py`
- `backend/alembic/versions/0004_reward_engine.py`
- `backend/alembic/versions/0005_generalize_reward_generation_source.py`
- `backend/app/tests/test_loyalty.py`

Implemented API endpoints:

- `POST /api/v1/owner/reward-templates`
- `GET /api/v1/owner/reward-templates?business_id=uuid`
- `GET /api/v1/customers/me/rewards?business_id=uuid`
- `POST /api/v1/staff/rewards/{reward_id}/use`

Verification performed:

- `pytest`: 27 tests passed
- `ruff check`: passed
- `alembic upgrade head --sql`: generated successfully
- `alembic upgrade head`: applied on local PostgreSQL
- `alembic current`: `0005_reward_source (head)`
- OpenAPI includes Sprint 4 reward endpoints
- Live PostgreSQL smoke test: passed

Smoke test confirmed:

- Owner can create Reward Template
- Action completing Campaign generates Generated Reward
- Generated Reward stores `source_type` and `source_id`
- Customer can list Generated Reward
- Staff can use active Reward
- Reward Use idempotency replay does not create duplicate usage
- Reward Usage stores `redeemed_business_id`
- Settlement status is `not_required`
- Points Ledger is not changed by Reward Use

## Exit Criteria

Sprint 4 بسته شده است:

- Reward Template توسط Owner ساخته می‌شود
- Campaign Completion می‌تواند Generated Reward بسازد
- Customer می‌تواند Rewardهای خودش را ببیند
- Staff می‌تواند Reward فعال را use کند
- Reward Use باعث تغییر Points Ledger نمی‌شود
- Migration روی PostgreSQL واقعی اجرا شد
- تست‌ها پاس شدند
- OpenAPI endpointهای Sprint 4 را نشان می‌دهد
