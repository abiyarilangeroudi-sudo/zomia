# Flutter F2.8: Customer Minimal Status

## هدف

هدف F2.8 این است که Customer بعد از login فقط QR نبیند؛ بلکه حداقل وضعیت loyalty خودش را هم ببیند.

این مرحله Customer dashboard کامل نیست. فقط وضعیت پایه لازم برای MVP را اضافه می‌کند.

## Scope

داخل F2.8:

- endpoint جدید `GET /customers/me/status`
- نمایش total points در Customer QR Screen
- نمایش تعداد active rewards
- نمایش status به تفکیک Business
- نمایش active rewards هر Business
- refresh دستی status بعد از انجام عملیات Staff
- افزایش نسخه Flutter برای تشخیص build جدید

خارج از F2.8:

- طراحی کامل Customer dashboard
- campaign progress visual کامل
- history کامل rewardهای used/expired
- notification یا realtime update
- redesign کامل UI/branding

## Backend Contract

```text
GET /api/v1/customers/me/status
```

خروجی شامل:

- `customer_id`
- `total_points`
- `active_rewards_count`
- `businesses[]`
- points و rewards هر business

## UX Notes

- Frontend UI remains English.
- QR همچنان بخش اصلی صفحه Customer است.
- status با refresh دستی به‌روزرسانی می‌شود.
- این طراحی realtime نیست؛ برای MVP کافی است Customer بعد از Staff action دکمه refresh را بزند.

## Verification

F2.8 کامل است وقتی:

- backend tests پاس شوند
- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- Customer صفحه `My Status` را ببیند
- Customer بتواند points و active rewards را بعد از Staff action با refresh ببیند
