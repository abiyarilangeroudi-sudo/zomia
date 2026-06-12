# Flutter F2.5: Staff And Customer QR UX Polish

## هدف Sprint

هدف F2.5 این است که حلقه واقعی Staff و Customer برای تست لوکال قابل استفاده‌تر شود:

```text
Customer shows QR
-> Staff scans QR with camera
-> Manual token remains fallback
-> Staff resolves customer
-> Staff registers action or uses reward
```

## Scope

داخل F2.5:

- اضافه شدن QR camera scan به Staff Service Panel
- حفظ manual token input به‌عنوان fallback
- polish اولیه کارت Customer QR در Staff Panel
- polish اولیه Customer QR Screen
- نمایش واضح‌تر token fallback در Customer QR
- افزایش نسخه Flutter برای تشخیص build جدید در صفحه Login

خارج از F2.5:

- طراحی production-level کامل Staff Panel
- طراحی production-level کامل Customer app
- Customer points/rewards dashboard
- offline scan queue
- advanced reward confirmation flow

## Architecture

```text
features/
  staff_service/
    presentation/
      staff_service_panel.dart
  customer_qr/
    presentation/
      customer_qr_screen.dart
```

## Dependencies

```text
mobile_scanner
```

در Web، camera permission توسط browser مدیریت می‌شود. اگر camera در دسترس نباشد یا permission داده نشود، Staff همچنان می‌تواند token را دستی وارد کند.

## UX Notes

- Frontend UI remains English.
- Staff flow now starts with `Scan with camera`.
- Manual token entry is explicitly labeled as fallback.
- Customer QR screen tells the customer to show the QR to staff.
- Customer QR still exposes the raw token for local MVP testing.

## Verification

F2.5 کامل است وقتی:

- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- Staff Panel دکمه `Scan with camera` داشته باشد
- Customer QR صفحه `Ready to Scan` و fallback token را نمایش دهد
- Login نسخه جدید Flutter را نشان دهد
