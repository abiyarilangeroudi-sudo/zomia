# Flutter F3: Customer QR Display

## هدف Sprint

هدف F3 این است که customer بتواند از همان صفحه login وارد شود و QR خودش را برای Staff Service Panel نمایش دهد.

این Sprint حلقه MVP را کامل‌تر می‌کند:

```text
Customer Login
-> Show Customer QR
-> Staff Login
-> Resolve Customer QR
-> Register Action
-> Reward Generation / Use
```

## Scope

داخل F3:

- تشخیص نقش کاربر بعد از login با `GET /auth/me`
- ادامه مسیر Staff به Staff Service Panel
- مسیر جدید Customer به Customer QR Screen
- اتصال به `POST /customers/me/qr-token`
- اتصال به `POST /customers/me/qr-token/rotate`
- نمایش QR با `qr_flutter`
- نمایش token متنی برای تست دستی و fallback
- sign out برای Customer

خارج از F3:

- camera scan
- Customer points/rewards dashboard کامل
- Customer profile
- Push notification
- Offline behavior

## Architecture

```text
features/
  auth/
    domain/
      current_user.dart
  customer_qr/
    data/
      customer_qr_repository.dart
    domain/
      customer_qr_token.dart
    presentation/
      customer_qr_screen.dart
```

## Backend Contracts

```text
GET  /api/v1/auth/me
POST /api/v1/customers/me/qr-token
POST /api/v1/customers/me/qr-token/rotate
```

## UX Notes

- Frontend UI remains English.
- Customer QR uses the existing Zomia branding foundation.
- The raw token remains visible for local MVP testing and manual Staff input.
- Customer QR screen requires UX polish before production readiness.

## Verification

F3 is complete when:

- `flutter analyze` passes
- `flutter test` passes
- `flutter build web` passes
- Staff login still reaches Staff Service Panel
- Customer login reaches Customer QR Screen
- Customer can rotate QR
