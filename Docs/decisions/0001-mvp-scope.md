# Decision 0001: MVP Scope

## وضعیت

پروژه Zomia ایده‌های زیادی دارد: Identity، Loyalty، Campaignهای فردی و گروهی، Cross-Network، Gamification، Analytics و Marketplace.

اگر همه این موارد از ابتدا ساخته شوند، MVP بزرگ و شکننده می‌شود.

## تصمیم

MVP فقط یک workflow کامل و واقعی وفاداری را می‌سازد:

```text
Owner -> Business -> Staff
Customer QR -> Staff Scan -> Action
Action -> Points -> Individual Campaign -> Reward
Reward -> Used
```

Group Campaign، Cross-Network Campaign، Fans Group و Business Club بعد از MVP ساخته می‌شوند.

## دلیل

- MVP باید کوچک و قابل اتمام باشد.
- core loop باید قبل از ویژگی‌های شبکه‌ای ثابت شود.
- معماری باید برای آینده آماده باشد، اما implementation آینده نباید از روز اول تحمیل شود.

## پیامدها

- Sprint 2 به جای Fans Group و Business Club، روی Loyalty Foundation تمرکز می‌کند.
- Campaign model از ابتدا باید `campaign_type` داشته باشد.
- در MVP فقط `individual` فعال می‌شود.
- Points Ledger از ابتدا append-only طراحی می‌شود.
- Action Registration از ابتدا idempotent طراحی می‌شود.

