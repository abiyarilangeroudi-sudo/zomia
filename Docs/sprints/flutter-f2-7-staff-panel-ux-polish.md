# Flutter F2.7: Staff Panel UX Polish

## هدف

هدف F2.7 بهتر کردن تجربه عملی Staff Panel بعد از پاس شدن F2.6 manual end-to-end QA است.

این مرحله معماری یا workflow جدید اضافه نمی‌کند. تمرکز روی کاهش خطای انسانی و خواناتر شدن وضعیت صفحه است.

## Scope

داخل F2.7:

- confirmation قبل از `Use Reward`
- پیام واضح‌تر بعد از ثبت Action وقتی reward جدید صادر نمی‌شود
- نمایش واضح‌تر customer loaded
- نمایش summary کوچک از points، active rewards و recent actions
- بهتر شدن چیدمان Mission row روی عرض کم
- افزایش نسخه Flutter برای تشخیص build جدید

خارج از F2.7:

- redesign کامل Staff Panel
- Owner dashboard
- Customer dashboard کامل
- offline scan queue
- analytics

## UX Notes

- Frontend UI remains English.
- Reward use یک عملیات irreversible برای MVP فرض می‌شود، پس قبل از آن confirmation لازم است.
- اگر Action ثبت شود اما reward جدید صادر نشود، UI این را صریح می‌گوید تا کاربر آن را با خطا اشتباه نگیرد.
- این پیام عمداً دلیل قطعی نمی‌دهد، چون ممکن است علت threshold ناکافی، campaign تکمیل‌شده قبلی، یا non-repeatable بودن campaign باشد.

## Verification

F2.7 کامل است وقتی:

- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- Staff قبل از use کردن reward dialog تأیید ببیند
- بعد از action بدون reward جدید، پیام مناسب نمایش داده شود
- Login نسخه جدید Flutter را نشان دهد

## Manual QA Data

اگر reward فعالی برای تست دستی وجود نداشت، از local dev seed زیر استفاده می‌کنیم:

```bash
cd backend
.venv/bin/python -m app.devtools.seed_reward_use_demo
```

این script فقط برای local development است و یک Staff، Customer، Business، QR token و active reward تازه برای تست `Use Reward` می‌سازد.
