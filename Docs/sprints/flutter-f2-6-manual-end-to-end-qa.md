# Flutter F2.6: Manual End-to-End QA

## هدف

هدف F2.6 تأیید دستی loop اصلی MVP بعد از اضافه شدن Customer QR، Staff QR scan و Staff Service Panel است.

این مرحله feature جدید اضافه نمی‌کند. خروجی آن ثبت وضعیت قابل اعتماد محصول برای ادامه UX polish است.

## Test Checklist

در تاریخ 2026-06-12 تست دستی انجام شد و همه موارد زیر پاس شدند:

- Customer login
- نمایش Customer QR
- Staff login
- scan کردن QR با camera
- resolve شدن customer
- ثبت `Buy Coffee`
- بررسی points
- بررسی reward generation در شرایط campaign قابل صدور
- use کردن reward
- بررسی recent actions

## نتیجه

F2.6 پاس شد.

نتیجه محصولی:

- core Staff/Customer MVP loop در local environment قابل استفاده است.
- camera scan و manual fallback هر دو در مسیر MVP معتبر هستند.
- قدم بعدی می‌تواند UX polish کوچک و کنترل‌شده باشد، نه تغییر معماری.

## Next

پیشنهاد مرحله بعد:

```text
F2.7: Staff Panel UX Polish
```

تمرکز F2.7:

- confirmation قبل از `Use Reward`
- پیام واضح‌تر وقتی reward جدید صادر نمی‌شود
- state واضح‌تر برای customer loaded
- مرتب‌تر کردن Staff Panel برای استفاده عملی روی mobile/tablet
