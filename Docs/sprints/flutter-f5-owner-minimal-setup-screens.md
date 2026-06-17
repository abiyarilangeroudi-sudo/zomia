# Flutter F5: Owner Minimal Setup Screens

## Goal

Owner بتواند برای اجرای demo و تست end-to-end، حداقل داده‌های loyalty را از داخل Flutter آماده کند.

این فاز جایگزین Owner Dashboard کامل نیست. هدف فقط کم کردن وابستگی به API client و seed script است.

## What Will Be Built

Frontend برای نقش Owner بعد از login وارد `Owner Dashboard` حداقلی می‌شود.

در این صفحه Owner می‌تواند:

- Businessهای خودش را ببیند و انتخاب کند
- Staff جدید برای Business انتخاب‌شده بسازد
- Staffهای Business انتخاب‌شده را ببیند
- Mission جدید بسازد
- Missionهای موجود را ببیند
- Campaign جدید با یک یا چند Mission و یک Reward Template انتخاب‌شده بسازد
- Campaignهای موجود را ببیند
- Gift Reward Template مستقل بسازد
- Reward Templateهای موجود را ببیند

## Architecture

```text
Auth Gate
-> Role Router
   -> owner
      -> Owner Dashboard
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
    owner_screen.dart
    owner_setup_controller.dart
    owner_loyalty_widgets.dart
    owner_profile_widgets.dart
    owner_setup_shared_widgets.dart
```

Historical note: نام اولیه صفحه `owner_setup_screen.dart` بود. وضعیت فعلی فایل اصلی `owner_screen.dart` است و widgetهای بزرگ به فایل‌های کوچک‌تر تقسیم شده‌اند.

## Backend API Contracts

F5 فقط از APIهای آماده backend استفاده می‌کند:

```text
GET  /api/v1/owner/businesses
POST /api/v1/owner/staff
GET  /api/v1/owner/staff
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
- `users`
- `staff_members`
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
- Staff موجود نمایش داده می‌شود
- Mission/Campaign/Reward Template موجود نمایش داده می‌شوند
- Create controls برای Staff, Mission, Campaign و Reward Template وجود دارند

## Verification Checklist

- Flutter version bump انجام شده باشد
- `dart format` پاس شود
- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- دستی: Owner بتواند login کند و صفحه setup را ببیند
