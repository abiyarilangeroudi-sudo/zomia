# Flutter F2.9: MVP Demo Readiness

## هدف

هدف F2.9 آماده کردن پروژه برای demo و ادامه امن است، بدون اضافه کردن feature جدید.

این مرحله برای جلوگیری از chaos انجام می‌شود: مشخص می‌کند چه چیزی demo-ready است، چه چیزی gap است، و اگر data تست خراب شد چگونه دوباره سناریوی قابل تست بسازیم.

## Demo Flow

مسیر رسمی demo فعلی:

```text
Customer Login
-> Customer QR
-> Staff Login
-> Scan Customer QR
-> Resolve Customer
-> Register Action
-> Reward appears in Staff Panel if campaign condition is satisfied
-> Staff uses Reward with confirmation
-> Customer refreshes My Status
-> Customer sees active rewards removed after use
```

## Local Run Checklist

قبل از demo:

- PostgreSQL با Docker روشن باشد
- Alembic روی آخرین head باشد
- Backend روی `http://127.0.0.1:8000` روشن باشد
- Frontend روی `http://127.0.0.1:8080` روشن باشد
- Login صفحه نسخه فعلی Flutter را نشان دهد
- Staff و Customer credentials آماده باشند

Health checks:

```bash
cd backend
.venv/bin/alembic current
```

```bash
curl http://127.0.0.1:8000/health
```

## QA Seed Strategy

اگر reward فعال برای تست دستی وجود نداشت، از seed مخصوص reward use استفاده شود:

```bash
cd backend
.venv/bin/python -m app.devtools.seed_reward_use_demo
```

این seed برای local development است و هر بار یک مجموعه تازه می‌سازد:

- Owner
- Business
- Staff
- Customer
- Mission
- Campaign
- Reward Template
- Active Generated Reward
- Active Customer QR Token

از خروجی command همان Staff email، Customer email و QR token را برای demo استفاده کن.

## Current Demo Credentials

آخرین seed اجراشده در این محیط:

```text
Staff email: staff-reward-qa-20260612103133@example.com
Customer email: customer-reward-qa-20260612103133@example.com
Password: strong-password
Business: Reward QA Cafe 20260612103133
QR token: 9bXh_EkWFvfVmO3n4tN41UohRVXfmXYSRF1LQKwMIz4
QR payload: zomia://customer/9bXh_EkWFvfVmO3n4tN41UohRVXfmXYSRF1LQKwMIz4
Reward: Reward QA Free Coffee
```

اگر این reward استفاده شد، seed را دوباره اجرا کن و از خروجی جدید استفاده کن.

## Known Product Gaps

- Customer Campaign Progress بعد از F2.9 طراحی و پیاده‌سازی شد.
- Customer فقط progress مربوط به Campaign را می‌بیند، نه `total points` عمومی.
- نمایش total points به Customer عمداً حذف شد، چون بدون Campaign Progress ارزش محصولی واضح ندارد.
- Customer status realtime نیست و با refresh دستی به‌روزرسانی می‌شود.
- Reward generation در campaignهای non-repeatable برای یک customer فقط یک بار رخ می‌دهد.
- Owner بعد از F5 UI حداقلی برای ساخت Staff, Mission, Campaign و Reward Template دارد.

## UI / Brand Debt

این موارد فعلاً debt هستند و نباید وسط demo readiness به redesign تبدیل شوند:

- بسیاری از debtهای F2.9 در F7 اصلاح شدند.
- UI/Branding هنوز باید در هر feature جدید با component catalog هماهنگ بماند.
- قبل از ساخت component جدید باید مشخص شود variant کامپوننت موجود است یا نیاز واقعی جدید.

## Verification

F2.9 کامل است وقتی:

- demo flow مستند باشد
- seed strategy مستند باشد
- known gaps مستند باشند
- UI/Brand debt مستند باشد
- هیچ feature جدیدی در این مرحله اضافه نشده باشد
