# Flutter F2: Staff Service Panel MVP

## هدف Sprint

هدف F2 این است که Staff بعد از login بتواند workflow اصلی MVP را از داخل Flutter اجرا کند:

```text
Manual QR Token
-> Resolve Customer
-> Customer Summary
-> Select Missions
-> Register Action
-> See Active Rewards
-> Use Reward
-> See Recent Actions
```

Camera scan در این Sprint وارد نمی‌شود. manual token input برای MVP کافی است و بعداً به‌عنوان fallback کنار camera scan باقی می‌ماند.

## Scope

داخل F2:

- Staff Service Panel در صفحه Staff Home
- اتصال به `GET /staff/service/missions`
- اتصال به `POST /staff/qr/resolve`
- اتصال به `POST /staff/service/actions`
- اتصال به `POST /staff/service/rewards/{reward_id}/use`
- نمایش Customer Summary
- انتخاب چند Mission با quantity
- ثبت Action چندآیتمی
- نمایش Active Rewards
- Use Reward
- نمایش Recent Actions
- استفاده از brand colors, spacing, logo/font foundation موجود

خارج از F2:

- camera QR scan
- offline mode
- Owner dashboard
- Customer app
- advanced reward confirmation modal
- analytics

## Architecture

```text
features/
  staff_service/
    data/
      staff_service_repository.dart
    domain/
      staff_service_models.dart
    presentation/
      staff_service_panel.dart
```

## Backend Contracts

```text
GET  /api/v1/staff/service/missions?business_id={business_id}
POST /api/v1/staff/qr/resolve
POST /api/v1/staff/service/actions
POST /api/v1/staff/service/rewards/{reward_id}/use
```

## UX Notes

- Frontend UI remains English.
- Branding is applied first to avoid rework.
- The panel uses local Sofia Sans, Zomia colors, and shared brand spacing.
- Idempotency keys are generated client-side per Staff action submission.
- Manual QR token input is accepted for F2, but Staff camera scan is a required follow-up.
- UI/UX polish is still needed before production readiness.
- If a campaign is not repeatable, registering the same qualifying action again will not generate another reward for the same customer.

## Verification

F2 is complete when:

- `flutter analyze` passes
- `flutter test` passes
- `flutter build web` passes
- Staff Home renders the Staff Service Panel
- Mission list loads through the repository
- Action and reward flows use backend contracts
