# Flutter MVP Phase

## هدف فاز

هدف فاز Flutter این است که core backend ساخته‌شده را به یک تجربه قابل استفاده برای MVP وصل کند.

در شروع این فاز قرار نبود همه نقش‌ها و همه داشبوردها کامل شوند. تمرکز اول روی اجرای workflow واقعی و قابل تست بود:

```text
Staff Login
-> Staff Context
-> Scan QR
-> Customer Summary
-> انتخاب Missionها
-> ثبت Action
-> دیدن Reward فعال
-> Use Reward
```

وضعیت فعلی فراتر از Staff-first شده و شامل Customer Registration، Customer Dashboard، Staff Dashboard و Owner Dashboard حداقلی است.

## تصمیم محصولی

Flutter MVP باید از Staff Service Panel شروع شود.

دلیل:

- core backend برای Staff workflow کامل‌تر و verify شده است
- Staff workflow همان حلقه اصلی ارزش محصول را تست می‌کند
- Owner dashboard و Customer app برای MVP لازم هستند، اما می‌توانند بعد از اثبات Staff loop کامل‌تر شوند
- شروع با یک اپ بزرگ چندنقشی ریسک دوباره‌کاری را بالا می‌برد

## Language Rule

Frontend UI باید به زبان انگلیسی باشد.

این قانون شامل همه متن‌های قابل مشاهده در Flutter است:

- screen titles
- buttons
- labels
- validation messages
- empty states
- loading states
- error messages
- snackbars/dialogs

Docs داخلی پروژه می‌توانند فارسی بمانند، اما محصول نهایی در frontend انگلیسی است.

## Version Rule

از این نقطه به بعد، هر تغییر در Flutter باید نسخه frontend را افزایش دهد تا تست دستی بتواند نسخه جدید را از صفحه Login تشخیص دهد.

نسخه در دو جا نگه داشته می‌شود:

```text
frontend/pubspec.yaml
frontend/lib/app/app_version.dart
```

صفحه Login به جای متن توضیحی، شماره نسخه را نمایش می‌دهد.

## محدوده Flutter MVP

### داخل فاز اول Flutter

- Flutter project setup
- تنظیم environment برای API base URL
- Login با JWT
- ذخیره امن token
- Staff Context بعد از login
- انتخاب Business اگر Staff چند Business داشت
- Staff Service Panel
- QR camera scan
- Customer QR display
- Customer QR rotate
- Customer Summary
- لیست Missionهای قابل ثبت
- ثبت Action با چند Mission و quantity
- نمایش Active Rewards
- Use Reward
- error/loading/empty states پایه
- Manual end-to-end QA برای Staff/Customer loop
- Customer self-registration
- Owner minimal setup برای Staff, Mission, Campaign و Reward Template
- UI/Branding recovery و component registry

### خارج از فاز اول Flutter

- Campaign builder کامل
- Reward Template management کامل
- Admin panel
- Analytics
- Gamification
- Group/Cross Campaign UI
- Offline-first behavior
- Push notification
- Advanced production polish

## Flutter App Shape

در MVP، یک اپ Flutter چند نقش را پشتیبانی می‌کند. شروع عملی Staff-first بود، اما وضعیت فعلی سه dashboard اصلی دارد.

پیشنهاد navigation:

```text
App Start
-> Auth Gate
   -> Login
   -> Customer Register
   -> Role Router
      -> Staff Dashboard
         -> Business Select
         -> Service Panel
      -> Customer Dashboard
      -> Owner Dashboard
```

صفحه‌های فعلی:

```text
Customer -> customer_screen.dart
Staff -> staff_panel.dart
Owner -> owner_screen.dart
```

## Backend Contracts مورد نیاز

### آماده و قابل استفاده

```text
POST /api/v1/auth/login
GET  /api/v1/auth/me
GET  /api/v1/staff/me/context
GET  /api/v1/staff/service/missions
POST /api/v1/staff/qr/resolve
POST /api/v1/staff/service/actions
POST /api/v1/staff/service/rewards/{reward_id}/use
```

### برای Customer QR Display آماده است

```text
POST /api/v1/customers/me/qr-token
POST /api/v1/customers/me/qr-token/rotate
GET  /api/v1/customers/me/points
GET  /api/v1/customers/me/rewards
GET  /api/v1/customers/me/status
GET  /api/v1/customers/me/campaigns/progress
```

نکته محصولی: `GET /customers/me/status` برای Flutter MVP فقط active rewards را پشتیبانی می‌کند. نمایش `total points` برای Customer انجام نمی‌شود. Customer Campaign Progress از endpoint جداگانه و campaign-based خوانده می‌شود.

## Demo Readiness Rule

بعد از F2.9، قبل از اضافه کردن feature جدید باید یکی از این تصمیم‌ها گرفته شود:

- UI/Branding recovery phase
- Customer Campaign Progress design
- Owner minimal tools

تا قبل از این تصمیم، از افزودن dashboardهای نصفه یا metricهای بدون ارزش مستقیم برای Customer خودداری می‌کنیم.

تصمیم گرفته شد:

```text
1. Owner minimal tools
2. Customer Campaign Progress design
3. UI/Branding recovery
```

دلیل: قبل از طراحی Progress مشتری، Owner باید بتواند Mission/Campaign/Reward Template را بدون دخالت مستقیم backend آماده کند.

وضعیت:

- Owner minimal tools انجام شد.
- Customer Campaign Progress با rule بدون `total points` تعریف و پیاده‌سازی شد.
- UI/Branding recovery به عنوان F7 تعریف شد.

## UI Component Registry Rule

از F7 به بعد، UI باید registry رسمی داشته باشد:

```text
frontend/lib/app/ui/
```

هر pattern تکرارشونده فقط یک implementation اصلی دارد. اگر component جدید لازم شد، باید قبل از ساخت مشخص شود variant یک component موجود است یا واقعاً component جدید.

سند مرجع:

```text
Docs/sprints/flutter-f7-ui-branding-recovery.md
```

F7 naming:

```text
F7.1 Design System Foundation
F7.2 Login Recovery
F7.3 Customer Dashboard Recovery
F7.4 Staff Dashboard Recovery
F7.5 Owner Dashboard Recovery
```

Register direction:

- Customer self-register لازم است.
- Owner register صفحه جداگانه خواهد داشت.
- Staff از داخل Owner Dashboard ساخته می‌شود.

### برای Owner Management آماده اما اولویت دوم

```text
GET  /api/v1/owner/businesses
POST /api/v1/owner/businesses
POST /api/v1/owner/staff
GET  /api/v1/owner/staff
POST /api/v1/owner/missions
GET  /api/v1/owner/missions
POST /api/v1/owner/campaigns
GET  /api/v1/owner/campaigns
POST /api/v1/owner/reward-templates
GET  /api/v1/owner/reward-templates
```

## UI Screens

### 1. Login

کاربر Staff با email/password وارد می‌شود.

نیازها:

- form validation پایه
- loading state
- نمایش خطای login
- ذخیره JWT بعد از موفقیت

### 2. Staff Context / Business Select

بعد از login:

```text
GET /staff/me/context
```

اگر `businesses.length == 1`:

```text
go to Service Panel
```

اگر چند Business وجود داشت:

```text
show Business Select
```

### 3. Service Panel

این صفحه مرکز MVP Flutter است.

بخش‌ها:

- QR input area
- Customer Summary
- Mission selector
- Action cart
- Active rewards
- Recent actions

### 4. QR Resolve

در F2 ابتدا با manual token input شروع شد.

در F2.5 camera scan اضافه شد. وضعیت فعلی محصول:

- QR camera scan اضافه شد
- manual token fallback از UI اصلی حذف شده است
- Staff باید QR payload کامل مثل `zomia://customer/{token}` را scan کند
- frontend payload را normalize می‌کند و فقط token را به backend می‌فرستد

### 5. Register Action

Staff باید بتواند:

- یک یا چند Mission انتخاب کند
- quantity هر Mission را تغییر دهد
- Action را ثبت کند
- summary به‌روز را ببیند

### 6. Use Reward

Staff باید بتواند:

- Reward فعال را ببیند
- Reward را use کند
- summary به‌روز را ببیند

## State Management

برای MVP، پیشنهاد:

```text
flutter_riverpod
```

دلیل:

- سبک و قابل تست است
- برای stateهای login/context/service panel مناسب است
- با رشد اپ قابل نگهداری می‌ماند

Stateهای اصلی:

```text
AuthState
StaffContextState
SelectedBusinessState
ServiceSessionState
MissionCatalogState
```

## Networking

پیشنهاد:

```text
dio
```

نیازها:

- base URL configurable
- Authorization interceptor
- error mapping
- timeout پایه

## Secure Storage

پیشنهاد:

```text
flutter_secure_storage
```

برای:

- JWT access token

در MVP refresh token نداریم، پس logout یعنی حذف access token.

## QR Scanning

پیشنهاد مرحله‌ای:

### Flutter Sprint F1

Manual QR token input.

### Flutter Sprint F2

Camera scan با پکیج:

```text
mobile_scanner
```

دلیل مرحله‌ای بودن:

- اول API flow را validate می‌کنیم
- بعد permission/camera/device complexity را اضافه می‌کنیم

وضعیت فعلی: camera scan مسیر اصلی Staff است و manual fallback در UI اصلی نگه داشته نمی‌شود.

## Folder Structure پیشنهادی

```text
frontend/
  lib/
    main.dart
    app/
      zomia_app.dart
      router.dart
      theme.dart
    core/
      config/
      http/
      storage/
      errors/
    features/
      auth/
        data/
        domain/
        presentation/
      staff_context/
        data/
        domain/
        presentation/
      service_panel/
        data/
        domain/
        presentation/
```

## Flutter Sprint Plan

### F0: Flutter Project Setup

هدف:

- ساخت پروژه Flutter
- تنظیم lint
- تنظیم dependencyهای پایه
- اتصال به backend local

خروجی:

- app اجرا شود
- صفحه placeholder داشته باشد
- config برای API base URL داشته باشد

### F1: Auth And Staff Context

هدف:

- Login
- ذخیره JWT
- خواندن Staff Context
- انتخاب Business

خروجی:

- Staff بعد از login وارد Service Panel شود

### FB: Branding Integration

هدف:

- اعمال design system آماده قبل از گسترش UI.

شامل:

- logo
- app icons
- color palette
- typography
- reusable UI tokens/components
- basic branded empty/loading/error states

خروجی:

- UIهای بعدی از ابتدا با برند نهایی ساخته شوند

### F2: Staff Service Panel Without Camera

هدف:

- manual QR token input
- resolve customer
- نمایش summary
- دریافت service missions
- ثبت Action
- use reward

خروجی:

- core workflow بدون camera کامل اجرا شود

### F3: QR Camera Scan

هدف:

- اضافه کردن camera scan
- حذف وابستگی روزمره به manual token input از مسیر اصلی UI

خروجی:

- Staff بتواند QR واقعی را scan کند

### F4: Customer QR Minimal Screen

هدف:

- Customer login
- issue/rotate QR
- نمایش QR
- نمایش active rewards/status پایه
- عدم نمایش `total points` عمومی به Customer

خروجی:

- workflow واقعی با دو دستگاه یا دو user قابل demo باشد

### F5: Owner Minimal Setup Screens

هدف:

- Owner بتواند حداقل Mission/Campaign/Reward Template بسازد
- برای demo به ابزار backend/manual کمتر وابسته باشیم

خروجی:

- MVP end-to-end از UI قابل آماده‌سازی باشد

## Readiness Check

Backend برای شروع Flutter کافی است اگر:

- `GET /staff/me/context` وجود دارد
- Staff service missions endpoint وجود دارد
- QR resolve endpoint وجود دارد
- action by QR endpoint وجود دارد
- reward use by QR endpoint وجود دارد
- تست‌های backend پاس می‌شوند

وضعیت فعلی:

```text
F0 completed
F1 completed
F2/F3 completed
F5 Owner minimal setup completed
F6 Customer campaign progress completed
F7 UI/Branding recovery completed
F8 Customer registration completed
Ready for MVP readiness flow review
```

## ریسک‌ها

### Camera complexity

برای کاهش ریسک، camera را از F2 جدا می‌کنیم.

### Owner setup complexity

برای کاهش ریسک، ابتدا Staff workflow ساخته می‌شود. Owner setup در F5 می‌آید.

### Token/session ساده

در MVP refresh token نداریم. برای شروع قابل قبول است، اما قبل از production باید session strategy کامل‌تر شود.

### API error UX

Frontend باید خطاهای 401/403/404/409/422 را به پیام‌های قابل فهم تبدیل کند.

## معیار پایان فاز اول Flutter

فاز اول Flutter وقتی موفق است که:

- Staff بتواند login کند
- Staff بتواند Business خودش را ببیند
- Staff بتواند Customer QR را scan کند
- Staff بتواند Customer Summary ببیند
- Staff بتواند Action ثبت کند
- Generated Reward در UI دیده شود
- Staff بتواند Reward را use کند
- Owner بتواند Staff, Mission, Campaign و Reward Template حداقلی بسازد
- Customer بتواند ثبت‌نام کند، login کند و Dashboard خودش را ببیند
- demo بدون دخالت مستقیم API client قابل اجرا باشد
