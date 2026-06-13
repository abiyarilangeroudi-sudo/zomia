# Flutter F2.5: Staff And Customer QR UX Polish

## هدف Sprint

هدف F2.5 این است که حلقه واقعی Staff و Customer برای تست لوکال قابل استفاده‌تر شود:

```text
Customer shows QR
-> Staff scans QR with camera
-> Staff resolves customer
-> Staff registers action or uses reward
```

Historical note: در خود F2.5 manual token fallback هنوز وجود داشت. در وضعیت فعلی محصول، این fallback از UI اصلی حذف شده و camera scan مسیر اصلی است.

## Scope

داخل F2.5:

- اضافه شدن QR camera scan به Staff Service Panel
- حفظ manual token input به‌عنوان fallback در همان مرحله تاریخی F2.5
- normalize کردن QR payload از `zomia://customer/{token}` به `{token}` قبل از ارسال به backend
- polish اولیه کارت Customer QR در Staff Panel
- polish اولیه Customer QR Screen
- نمایش واضح‌تر token fallback در Customer QR در همان مرحله تاریخی
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
      staff_panel.dart
      qr_scanner_sheet.dart
  customer_qr/
    presentation/
      customer_screen.dart
      customer_qr_dialog.dart
```

## Dependencies

```text
mobile_scanner
```

در Web، camera permission توسط browser مدیریت می‌شود. در F2.5 اگر camera در دسترس نبود، Staff می‌توانست token را دستی وارد کند. در UI فعلی این fallback دیگر مسیر اصلی محصول نیست.

## UX Notes

- Frontend UI remains English.
- Staff flow now starts with `Scan with camera`.
- Manual token entry was explicitly labeled as fallback in this historical phase.
- QR normalization accepts the full QR payload and extracts the raw token before backend calls.
- Customer QR screen tells the customer to show the QR to staff.
- Customer QR exposes the QR payload for scan; raw token display is not part of the current polished UI.

## Verification

F2.5 کامل است وقتی:

- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- Staff Panel دکمه `Scan with camera` داشته باشد
- Customer QR صفحه `Ready to Scan` را نمایش دهد
- scan کردن QR با payload کامل باعث resolve شدن همان raw token شود
- Login نسخه جدید Flutter را نشان دهد
