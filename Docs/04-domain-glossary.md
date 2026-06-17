# واژه‌نامه دامنه

## Identity

### User

رکورد حساب کاربری برای authentication. همه نقش‌ها مثل Customer، Owner، Staff و Admin در اصل User هستند.

### Customer

مشتری نهایی که QR نمایش می‌دهد، Action برایش ثبت می‌شود، Point می‌گیرد و Reward دریافت می‌کند.

### Owner

مالک کسب‌وکار که Business، Staff، Mission، Campaign و Rewardها را مدیریت می‌کند.

### Staff

کارمند کسب‌وکار که QR مشتری را scan می‌کند، Action ثبت می‌کند و Reward را Use می‌کند.

### Admin

مدیر پلتفرم. در MVP فقط role آن وجود دارد.

## Business

### Business

کسب‌وکار یا merchant که برنامه وفاداری اجرا می‌کند.

### Staff Membership

رابطه بین یک Staff User و یک Business.

### Business Partner Club

جامعه‌ای از کسب‌وکارها برای Cross-Network Campaign. خارج از MVP.

## Loyalty

### Mission

رفتار تعریف‌شده‌ای که می‌تواند Point تولید کند؛ مثل خرید، مراجعه، check-in، معرفی دوست یا ثبت نظر.

### Action

ثبت یک عملیات واقعی برای یک Customer. یک Action می‌تواند چند Mission را همزمان ثبت کند.

مثال:

```text
Ali bought 2 coffees and 1 cake
```

این یک Action است، اما چند Action Item دارد.

در آینده Action می‌تواند Reward Usage هم داشته باشد. Reward Usage مصرف پاداش را ثبت می‌کند و Point ایجاد یا کم نمی‌کند.

### Action Item

یک ردیف داخل Action که به یک Mission وصل است.

مثال:

```text
Buy Coffee x 2
Buy Cake x 1
```

### Reward Usage

ثبت مصرف یک Reward داخل یک Action. Reward Usage به Mission وصل نیست و Points Ledger entry نمی‌سازد.

### Point

واحد پیشرفت مشتری. Point باید در Points Ledger ذخیره شود.

### Points Ledger

دفتر append-only برای امتیازهای کسب‌شده. این ledger کیف پول یا credit economy نیست و Reward Use باعث کم شدن Point نمی‌شود.

### Campaign

مجموعه‌ای از قوانین که progress مشتری را بررسی می‌کند و تصمیم می‌گیرد Reward صادر شود یا نه.

Campaign همیشه بازه زمانی `starts_at` و `ends_at` دارد. Actionهای خارج از این بازه برای progress همان Campaign حساب نمی‌شوند.

وضعیت زمانی Campaign و متن قابل نمایش progress برای Customer توسط Backend محاسبه می‌شود، نه Frontend.

### Individual Campaign

Campaignی که هر Customer به صورت مستقل در آن پیشرفت می‌کند.

مثال:

```text
10 purchases -> 1 free coffee
```

### Repeatable Campaign Cycle

چرخه‌ای که در آن یک Individual Campaign می‌تواند بعد از هر بار رسیدن Customer به threshold، یک Campaign Completion و در نتیجه یک Reward جدید بسازد.

در MVP، `max_completions_per_customer = null` یعنی تعداد چرخه‌ها در بازه زمانی Campaign نامحدود است. اگر عدد مثبت باشد، همان عدد سقف تعداد completion برای هر Customer است.

مثال:

```text
threshold = 10 points
20 points -> 2 completed cycles -> 2 rewards
23 points -> current cycle progress is 3/10
```

### Group Campaign

Campaign آینده که اعضای یک Fans Group برای هدف مشترک همکاری می‌کنند. خارج از MVP.

### Cross-Network Campaign

Campaign آینده که بین چند Business اجرا می‌شود. خارج از MVP.

## Rewards

### Reward Template

تعریف Owner از نوع، مقدار، مدت اعتبار، صادرکننده، محدوده مصرف و سیاست هزینه پاداش.

Reward Template مستقل از Campaign است. Campaign از طریق رابطه `campaign_reward_templates` یک Template را برای صدور Reward انتخاب می‌کند.

در MVP هر Campaign دقیقاً یک Reward Template دارد. این محدودیت برای ساده نگه داشتن MVP است و بعداً برای multi-reward Campaign قابل گسترش است.

### Generated Reward

Reward واقعی که برای یک Customer بعد از Campaign Completion صادر شده است. این رکورد snapshot اطلاعات Template را نگه می‌دارد تا تغییر Template در آینده پاداش‌های قدیمی را خراب نکند.

### Reward Generation Source

منبعی که باعث صدور Generated Reward شده است.

در MVP:

```text
individual_campaign_completion
```

در آینده:

```text
group_campaign_completion
```

Generated Reward همیشه برای یک Customer صادر می‌شود، اما source می‌تواند فردی یا گروهی باشد.

برای جلوگیری از صدور تکراری:

```text
source_type + source_id + customer_id
```

باید unique باشد.

### Reward Recipient Policy

قانونی که در Group Campaign مشخص می‌کند بعد از کامل شدن هدف گروهی چه کسانی Generated Reward می‌گیرند.

گزینه‌های آینده:

```text
all_group_members
contributors_only
contributors_above_minimum
selected_members
```

### Reward Issuer

کسب‌وکاری که Reward را صادر می‌کند و در MVP مسئول هزینه آن است.

### Redeem Scope

قانونی که مشخص می‌کند Reward در کدام Businessها قابل مصرف است.

در MVP:

```text
issuer_business_only
```

در آینده:

```text
campaign_participants
selected_businesses
```

### Settlement Policy

قانونی که مشخص می‌کند هزینه Reward بعد از مصرف بر عهده چه کسی است.

در MVP:

```text
issuer_pays
```

### Reward Status

وضعیت lifecycle یک Generated Reward.

در MVP:

```text
active
used
expired
```

### Gift

دریافت یک محصول یا خدمت مشخص به عنوان جایزه.

### Percentage Discount

تخفیف درصدی برای خرید بعدی.

### Fixed Discount

تخفیف مبلغ ثابت برای خرید بعدی.

### Reward Lifecycle

جریان وضعیت Reward:

```text
active -> used
active -> expired
```

در آینده ممکن است `pending` هم اضافه شود، مخصوصاً برای Group Campaign و Settlement.

### Reward Engine

بخش دامنه‌ای که از Campaign Completion و Reward Template، Generated Reward می‌سازد و مصرف Reward را مدیریت می‌کند.

Reward Engine به Points Ledger امتیاز منفی اضافه نمی‌کند و Wallet/Credit Economy نیست.

## Operations

### QR Scan

عملیات staff برای resolve کردن token مشتری و باز کردن صفحه service.

### Customer QR Token

توکن تصادفی و قابل rotate/revoke که Customer آن را به صورت QR نمایش می‌دهد.

QR Token جای JWT نیست و فقط برای resolve کردن Customer در Staff Workflow استفاده می‌شود.

در database فقط `token_hash` ذخیره می‌شود، نه token خام.

### Action Registration

ثبت یک عملیات برای Customer. این عملیات می‌تواند یک یا چند Mission را شامل شود.

### Idempotency

مکانیزمی برای جلوگیری از ثبت دوباره یک Action وقتی request تکرار می‌شود.
