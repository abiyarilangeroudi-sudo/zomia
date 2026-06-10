# Roadmap

Roadmap قبلی خیلی زود سراغ Fans Group و Business Club می‌رفت. برای MVP این مسیر بزرگ و پرریسک است.

Roadmap جدید اول یک loyalty workflow کامل را می‌سازد، بعد سراغ campaignهای پیشرفته می‌رود.

## Sprint 1: Identity And Business

هدف:

- ساخت پایه authentication و مالکیت کسب‌وکار.

شامل:

- Customer
- Owner
- Staff
- Admin role placeholder
- JWT
- Business Profile
- Staff Membership
- PostgreSQL Migration

معیار خروج:

- تست‌ها پاس شوند
- OpenAPI ساخته شود
- Migration روی PostgreSQL واقعی اجرا شود
- Owner بتواند Staff بسازد

## Sprint 2: Loyalty Foundation

هدف:

- ساخت حداقل مدل وفاداری برای ثبت progress واقعی مشتری.

شامل:

- Mission
- Action
- Action Item
- Points Ledger
- Idempotency Key
- Basic Audit Events

معیار خروج:

- Staff بتواند برای Customer یک Action چندآیتمی ثبت کند
- Points earned/progress به صورت append-only ثبت شود
- ثبت duplicate action جلوگیری شود

## Sprint 3: Individual Campaign

هدف:

- ارزیابی progress برای campaign ساده.

شامل:

- Campaign Table
- Campaign Type Enum
- Individual Campaign Rules
- Customer Progress Evaluation
- Campaign Completion

معیار خروج:

- Action بتواند Campaign Evaluation را trigger کند
- threshold قابل رسیدن باشد
- سیستم Campaign Completion ثبت کند
- Reward واقعی هنوز ساخته نشود

## Sprint 4: Reward Engine

هدف:

- ساخت و مصرف Reward.

شامل:

- Reward Template
- Generated Reward
- Gift Reward
- Percentage Discount Reward
- Fixed Discount Reward
- Reward Lifecycle

معیار خروج:

- Campaign Evaluation بتواند Reward بسازد
- Staff بتواند Reward را Used کند
- Reward منقضی‌شده قابل استفاده نباشد

## Sprint 5: QR Staff Workflow

هدف:

- اتصال workflow واقعی service.

شامل:

- Customer QR Token
- Scan Resolve Endpoint
- Staff Service Response
- Register Action from Scan Flow
- Use Reward from Scan Flow

معیار خروج:

- Staff بتواند workflow اصلی MVP را از QR تا Reward Use کامل کند

## Sprint 5.5: Staff Panel API Contract

هدف:

- آماده‌سازی API contract برای Staff Service Panel.

شامل:

- endpoint مخصوص Staff برای service missions
- typed کردن Staff Service Summary
- مستندسازی نیازهای Staff Panel

معیار خروج:

- Flutter برای ساخت Staff Service Panel نیاز به endpoint owner-scoped نداشته باشد

## Sprint 5.6: Staff Context Endpoint

هدف:

- آماده کردن backend برای شروع Flutter.

شامل:

- `GET /api/v1/staff/me/context`
- برگرداندن Staff و Businessهای فعال او
- طراحی response به شکل چند Business برای آینده

معیار خروج:

- Flutter بعد از login بتواند Business context را بدون hard-code دریافت کند

## Phase 6: Flutter MVP

هدف:

- شروع Frontend بعد از تکمیل core backend.

این فاز خودش به Sprintهای کوچک‌تر تقسیم می‌شود.

### F0: Flutter Project Setup

شامل:

- ساخت پروژه Flutter
- تنظیم lint
- تنظیم config برای API base URL
- app shell اولیه

### F1: Auth And Staff Context

شامل:

- Staff Login
- ذخیره JWT
- دریافت Staff Context
- انتخاب Business اگر لازم بود

### FB: Branding Integration

شامل:

- اعمال logo
- app icons
- color palette
- typography
- UI tokens/components

این مرحله بعد از F1 و قبل از F2 انجام می‌شود تا Staff Service Panel با design system نهایی ساخته شود.

### F2: Staff Service Panel Without Camera

شامل:

- manual QR token input
- resolve customer
- نمایش customer summary
- دریافت service missions
- ثبت Action
- use reward

### F3: QR Camera Scan

شامل:

- اضافه کردن camera scan
- حفظ manual input به عنوان fallback

### F4: Customer QR Minimal Screen

شامل:

- Customer login
- issue/rotate QR
- نمایش QR
- نمایش points/rewards پایه

### F5: Owner Minimal Setup Screens

شامل:

- مدیریت حداقلی Mission
- مدیریت حداقلی Campaign
- مدیریت حداقلی Reward Template

معیار خروج فاز Flutter:

- یک کاربر غیرتوسعه‌دهنده بتواند workflow اصلی را از UI اجرا کند

تصمیم Frontend:

- Frontend اصلی Zomia با Flutter ساخته می‌شود.
- قبل از تکمیل core backend، Flutter را شروع نمی‌کنیم تا همزمان دو سطح ناپایدار نسازیم.
- جزئیات فاز Flutter در [Flutter MVP Phase](./roadmap/flutter-mvp-phase.md) ثبت شده است.

## Post-MVP

این موارد بعد از اثبات core loop ساخته می‌شوند:

- Fans Group
- Business Club
- Group Campaign
- Cross-Network Campaign
- Analytics
- Gamification
- Marketplace
- Production Observability
