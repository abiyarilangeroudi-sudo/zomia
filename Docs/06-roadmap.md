# Roadmap

The previous roadmap moved to Fans Group and Business Club too early. For the MVP, this path is too large and high-risk.

The new roadmap first builds a complete loyalty workflow, and only then moves on to advanced campaigns.

## Sprint 1: Identity and Business

**Goal:**

* Build the foundation for authentication and business ownership.

**Includes:**

* Customer
* Owner
* Staff
* Admin role placeholder
* JWT
* Business Profile
* Staff Membership
* PostgreSQL Migration

**Exit Criteria:**

* Tests pass
* OpenAPI is generated
* Migration runs successfully against a real PostgreSQL database
* Owner can create Staff members

## Sprint 2: Loyalty Foundation

**Goal:**

* Build the minimum loyalty model for tracking real customer progress.

**Includes:**

* Mission
* Action
* Action Item
* Points Ledger
* Idempotency Key
* Basic Audit Events

**Exit Criteria:**

* Staff can register a multi-item Action for a Customer
* Points earned/progress is recorded as append-only data
* Duplicate Action registration is prevented

## Sprint 3: Individual Campaign

**Goal:**

* Evaluate progress for a simple campaign.

**Includes:**

* Campaign Table
* Campaign Type Enum
* Individual Campaign Rules
* Customer Progress Evaluation
* Campaign Completion

**Exit Criteria:**

* An Action can trigger Campaign Evaluation
* The threshold can be reached
* The system records Campaign Completion
* No real Reward is created yet

## Sprint 4: Reward Engine

**Goal:**

* Build and consume Rewards.

**Includes:**

* Reward Template
* Generated Reward
* Gift Reward
* Percentage Discount Reward
* Fixed Discount Reward
* Reward Lifecycle

**Exit Criteria:**

* Campaign Evaluation can generate a Reward
* Staff can mark a Reward as Used
* An expired Reward cannot be used

## Sprint 5: QR Staff Workflow

**Goal:**

* Connect the real service workflow.

**Includes:**

* Customer QR Token
* Scan Resolve Endpoint
* Staff Service Response
* Register Action from Scan Flow
* Use Reward from Scan Flow

**Exit Criteria:**

* Staff can complete the core MVP workflow from QR scan to Reward usage

## Sprint 5.5: Staff Panel API Contract

**Goal:**

* Prepare the API contract for the Staff Service Panel.

**Includes:**

* Staff-specific endpoint for service missions
* Typed Staff Service Summary
* Documentation of Staff Panel requirements

**Exit Criteria:**

* Flutter does not need an owner-scoped endpoint to build the Staff Service Panel

## Sprint 5.6: Staff Context Endpoint

**Goal:**

* Prepare the backend for starting Flutter development.

**Includes:**

* `GET /api/v1/staff/me/context`
* Return the Staff member and their active Businesses
* Design the response to support multiple Businesses in the future

**Exit Criteria:**

* After login, Flutter can retrieve the Business context without hard-coding it

## Phase 6: Flutter MVP

**Goal:**

* Start the Frontend after the core backend is complete.

This phase is divided into smaller sprints.

### F0: Flutter Project Setup

**Includes:**

* Create Flutter project
* Configure linting
* Configure API base URL
* Initial app shell

### F1: Auth and Staff Context

**Includes:**

* Staff Login
* Store JWT
* Retrieve Staff Context
* Select Business if needed

### FB: Branding Integration

**Includes:**

* Apply logo
* App icons
* Color palette
* Typography
* UI tokens/components

This stage is completed after F1 and before F2 so that the Staff Service Panel is built using the final design system.

### F2: Staff Service Panel Without Camera

**Includes:**

* Manual QR token input
* Resolve Customer
* Display customer summary
* Retrieve service missions
* Register Action
* Use Reward

### F3: QR Camera Scan

**Includes:**

* Add camera scanning
* Remove the day-to-day dependency on manual input from the primary UI flow

### F4: Customer QR Minimal Screen

**Includes:**

* Customer login
* Issue/rotate QR
* Display QR
* Display active rewards/basic status
* Do not display `total points` publicly to the Customer

### F5: Owner Minimal Setup Screens

**Includes:**

* Minimal Mission management
* Minimal Campaign management
* Minimal Reward Template management

**Flutter Phase Exit Criteria:**

* A non-developer user can execute the core workflow entirely through the UI

**Frontend Decision:**

* Zomia's main Frontend will be built with Flutter.
* Flutter development will not begin until the core backend is complete, so that we do not build two unstable layers simultaneously.
* Details of the Flutter phase are documented in [Flutter MVP Phase](./roadmap/flutter-mvp-phase.md).

## Post-MVP

These items will be built after the core loop has been validated:

* Fans Group
* Business Club
* Group Campaign
* Cross-Network Campaign
* Analytics
* Gamification
* Marketplace
* Production Observability
* Business suspension for Operations/Admin only, if a real temporary-closure need is validated
* Controlled Business closure and Owner deactivation, after retention and operational policy approval; see [Business And Account Lifecycle Roadmap](./roadmap/business-account-lifecycle-roadmap.md)

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
- حذف وابستگی روزمره به manual input از مسیر اصلی UI

### F4: Customer QR Minimal Screen

شامل:

- Customer login
- issue/rotate QR
- نمایش QR
- نمایش active rewards/status پایه
- عدم نمایش `total points` عمومی به Customer

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
- Business suspension for Operations/Admin only, if a real temporary-closure
  need is validated
- Controlled Business closure and Owner deactivation, after retention and
  operational policy approval; see [Business And Account Lifecycle Roadmap](./roadmap/business-account-lifecycle-roadmap.md)
