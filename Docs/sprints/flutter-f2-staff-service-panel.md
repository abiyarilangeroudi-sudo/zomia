# Flutter F2: Staff Service Panel MVP

## هدف Sprint

هدف F2 این است که Staff بعد از login بتواند workflow اصلی MVP را از داخل Flutter اجرا کند:

```text
Camera QR Scan / Manual QR Token
-> Resolve Customer
-> Customer Summary
-> Select Missions
-> Register Action
-> See Active Rewards
-> Use Reward
-> See Recent Actions
```

F2 ابتدا با manual token input ساخته شد. در F2.5 camera scan اضافه شد و manual token input به‌عنوان fallback باقی ماند.

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
- camera QR scan در ادامه F2.5 اضافه شد
- manual token fallback برای تست و شرایط بدون camera باقی می‌ماند

خارج از F2:

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
- Staff can scan the Customer QR with camera where browser permissions allow it.
- Manual QR token input remains available as fallback.
- F2.5 adds first-pass UX polish, but deeper production UI/UX polish is still expected later.
- If a campaign is not repeatable, registering the same qualifying action again will not generate another reward for the same customer.

## Verification

F2 is complete when:

- `flutter analyze` passes
- `flutter test` passes
- `flutter build web` passes
- Staff Home renders the Staff Service Panel
- Mission list loads through the repository
- Action and reward flows use backend contracts
