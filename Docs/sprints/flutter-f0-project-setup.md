# Flutter F0: Project Setup

## هدف Sprint

هدف F0 ساخت پایه Flutter بدون ورود به featureهای واقعی است.

این Sprint فقط app shell، dependencyهای پایه، config و verification اولیه را آماده می‌کند تا F1 بتواند با Auth و Staff Context شروع شود.

## Scope

داخل F0:

- ساخت پروژه Flutter در `frontend/`
- تنظیم پلتفرم‌های `android`, `ios`, `web`, `macos`
- اضافه کردن dependencyهای پایه
- ساخت app shell
- ساخت theme پایه
- ساخت router پایه
- ساخت API config
- ساخت Dio client provider
- ساخت secure token storage wrapper
- widget test پایه

خارج از F0:

- Login واقعی
- Staff Context واقعی
- QR workflow
- Owner/Customer UI
- camera scan

## Language Rule

تمام متن‌های قابل مشاهده در Flutter باید انگلیسی باشند.

در F0 متن‌های app shell انگلیسی هستند:

```text
Zomia
Staff Service
Service workspace
Sign in
```

## Dependencies

```text
flutter_riverpod
go_router
dio
flutter_secure_storage
cupertino_icons
flutter_lints
```

## Folder Structure

```text
frontend/
  lib/
    main.dart
    app/
      router.dart
      theme.dart
      zomia_app.dart
    core/
      config/
      errors/
      http/
      storage/
    features/
      app_shell/
        presentation/
```

## Configuration

API base URL از `--dart-define` خوانده می‌شود:

```text
API_BASE_URL
```

default:

```text
http://localhost:8000/api/v1
```

نمونه اجرا:

```text
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## Verification

F0 وقتی بسته می‌شود که:

- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- app shell بدون counter demo ساخته شده باشد

## Implementation Result

F0 پیاده‌سازی و verify شد.

Verification:

- `flutter analyze` پاس شد
- `flutter test` پاس شد
- `flutter build web` پاس شد
