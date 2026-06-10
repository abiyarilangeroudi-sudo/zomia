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

## Sprint 6: Minimal UI

هدف:

- شروع Frontend بعد از تکمیل core backend.

شامل:

- Flutter project setup
- Owner Login
- Staff Login
- Customer QR Display
- Staff Scan/Service Panel
- Basic Mission and Campaign Management

معیار خروج:

- یک کاربر غیرتوسعه‌دهنده بتواند workflow اصلی را اجرا کند

تصمیم Frontend:

- Frontend اصلی Zomia با Flutter ساخته می‌شود.
- قبل از تکمیل core backend، Flutter را شروع نمی‌کنیم تا همزمان دو سطح ناپایدار نسازیم.

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
