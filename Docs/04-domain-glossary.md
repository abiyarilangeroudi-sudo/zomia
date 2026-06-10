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

ثبت انجام یک Mission برای یک Customer. در MVP، Staff بعد از scan کردن QR مشتری Action را ثبت می‌کند.

### Point

واحد پیشرفت مشتری. Point باید در Points Ledger ذخیره شود.

### Points Ledger

دفتر append-only برای تغییرات امتیاز. برای audit، analytics و اصلاحات آینده ضروری است.

### Campaign

مجموعه‌ای از قوانین که progress مشتری را بررسی می‌کند و تصمیم می‌گیرد Reward صادر شود یا نه.

### Individual Campaign

Campaignی که هر Customer به صورت مستقل در آن پیشرفت می‌کند.

مثال:

```text
10 purchases -> 1 free coffee
```

### Group Campaign

Campaign آینده که اعضای یک Fans Group برای هدف مشترک همکاری می‌کنند. خارج از MVP.

### Cross-Network Campaign

Campaign آینده که بین چند Business اجرا می‌شود. خارج از MVP.

## Rewards

### Reward Template

تعریف Owner از نوع و مقدار پاداش.

### Generated Reward

Reward واقعی که برای یک Customer صادر شده است.

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

## Operations

### QR Scan

عملیات staff برای resolve کردن token مشتری و باز کردن صفحه service.

### Action Registration

ثبت اینکه مشتری یک Mission را انجام داده است.

### Idempotency

مکانیزمی برای جلوگیری از ثبت دوباره یک Action وقتی request تکرار می‌شود.

