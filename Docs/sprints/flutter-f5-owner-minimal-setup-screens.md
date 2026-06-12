# Flutter F5: Owner Minimal Setup Screens

## Goal

Owner بتواند برای اجرای demo و تست end-to-end، حداقل داده‌های loyalty را از داخل Flutter آماده کند.

این فاز جایگزین Owner Dashboard کامل نیست. هدف فقط کم کردن وابستگی به API client و seed script است.

## What Will Be Built

Frontend برای نقش Owner بعد از login وارد صفحه `Owner Setup` می‌شود.

در این صفحه Owner می‌تواند:

- Businessهای خودش را ببیند و انتخاب کند
- Mission جدید بسازد
- Missionهای موجود را ببیند
- Campaign جدید با یک یا چند Mission بسازد
- Campaignهای موجود را ببیند
- Gift Reward Template جدید برای Campaign بسازد
- Reward Templateهای موجود را ببیند

## Architecture

```text
Auth Gate
-> Role Router
   -> owner
      -> Owner Setup Screen
         -> Owner Setup Repository
            -> Owner Management API
```

Flutter structure:

```text
frontend/lib/features/owner_setup/
  data/
    owner_setup_repository.dart
  domain/
    owner_setup_models.dart
  presentation/
    owner_setup_screen.dart
```

## Backend API Contracts

F5 فقط از APIهای آماده backend استفاده می‌کند:

```text
GET  /api/v1/owner/businesses
POST /api/v1/owner/missions
GET  /api/v1/owner/missions
POST /api/v1/owner/campaigns
GET  /api/v1/owner/campaigns
POST /api/v1/owner/reward-templates
GET  /api/v1/owner/reward-templates
```

## Database Schema

F5 migration جدید ندارد.

داده‌های زیر از schema موجود استفاده می‌کنند:

- `businesses`
- `missions`
- `campaigns`
- `campaign_missions`
- `reward_templates`

## Product Constraints

- Frontend UI English only.
- Reward Template creation در MVP فقط `gift` را پشتیبانی می‌کند.
- Campaign builder کامل، discount rewards، staff management و analytics خارج از F5 هستند.
- UI/Branding recovery بعد از Owner minimal tools انجام می‌شود.

## Tests

Widget test باید تایید کند:

- Owner بعد از login به صفحه Owner Setup می‌رسد
- Business نمایش داده می‌شود
- Mission/Campaign/Reward Template موجود نمایش داده می‌شوند
- Create controls برای هر سه بخش وجود دارند

## Verification Checklist

- Flutter version bump انجام شده باشد
- `dart format` پاس شود
- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- دستی: Owner بتواند login کند و صفحه setup را ببیند

