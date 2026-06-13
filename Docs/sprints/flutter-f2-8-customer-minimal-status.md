# Flutter F2.8: Customer Minimal Status

## هدف

هدف F2.8 این است که Customer بعد از login فقط QR نبیند؛ بلکه active rewardهای قابل استفاده خودش را هم ببیند.

این مرحله Customer dashboard کامل نیست. فقط وضعیت پایه لازم برای MVP را اضافه می‌کند.

## Scope

داخل F2.8:

- endpoint جدید `GET /customers/me/status`
- نمایش تعداد active rewards
- نمایش status به تفکیک Business
- نمایش active rewards هر Business
- refresh دستی status بعد از انجام عملیات Staff
- افزایش نسخه Flutter برای تشخیص build جدید

خارج از F2.8:

- طراحی کامل Customer dashboard
- campaign progress visual کامل
- progress points برای campaign
- نمایش total points به customer
- history کامل rewardهای used/expired
- notification یا realtime update
- redesign کامل UI/branding

## Backend Contract

```text
GET /api/v1/customers/me/status
```

خروجی شامل:

- `customer_id`
- `active_rewards_count`
- `businesses[]`
- active rewards هر business

## UX Notes

- Frontend UI remains English.
- QR همچنان بخش اصلی صفحه Customer است.
- status با refresh دستی به‌روزرسانی می‌شود.
- این طراحی realtime نیست؛ برای MVP کافی است Customer بعد از Staff action دکمه refresh را بزند.
- نمایش `total points` برای Customer فعلاً حذف شد، چون بدون Campaign Progress ارزش محصولی واضح ندارد و می‌تواند گمراه‌کننده باشد.
- در زمان F2.8، Customer Campaign Progress باید جداگانه طراحی می‌شد. این مسیر بعداً در F6 تعریف و پیاده‌سازی شد.

## Verification

F2.8 کامل است وقتی:

- backend tests پاس شوند
- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- Customer صفحه `My Status` را ببیند
- Customer بتواند active rewards را بعد از Staff action با refresh ببیند
