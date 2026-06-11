# Flutter Branding Extraction

## هدف

این سند مشخص می‌کند از Template اضافه‌شده در `frontend/zomia_Branding/` چه چیزهایی برای Flutter MVP لازم است و چه چیزهایی نباید وارد پروژه فعلی شود.

Template یک پروژه کامل قدیمی Flutter است، نه یک بسته تمیز برندینگ. بنابراین فقط دارایی‌ها، tokenهای طراحی و چند الگوی UI از آن استخراج می‌شوند.

## منبع Template

```text
frontend/zomia_Branding/
```

این پوشه فعلاً به‌عنوان reference محلی باقی می‌ماند، اما بخشی از کد اصلی Flutter MVP نیست. برای جلوگیری از تحلیل و commit تصادفی، از analyzer و git پروژه اصلی کنار گذاشته می‌شود.

## چیزهایی که نباید منتقل شوند

این موارد artifact یا معماری قدیمی هستند و نباید وارد پروژه اصلی شوند:

- `.dart_tool/`
- `build/`
- `.idea/`
- `.DS_Store`
- `.flutter-plugins-dependencies`
- `flutter_zomia_ui.iml`
- serviceها، providerها، mockها و مدل‌های قدیمی محصول قبلی
- routing و state management قدیمی Template
- generated localization files
- business logic داخل screen/widgetهای قدیمی

## Assets مورد نیاز

### Logo

Source:

```text
frontend/zomia_Branding/assets/images/ZOMIA-LOGO-clean.svg
```

Target پیشنهادی:

```text
frontend/assets/brand/zomia_logo.svg
```

نیاز Flutter:

- اضافه کردن asset path در `frontend/pubspec.yaml`
- استفاده با `flutter_svg`

### Web/App Icons

Source:

```text
frontend/zomia_Branding/web/favicon.png
frontend/zomia_Branding/web/icons/Icon-192.png
frontend/zomia_Branding/web/icons/Icon-512.png
frontend/zomia_Branding/web/icons/Icon-maskable-192.png
frontend/zomia_Branding/web/icons/Icon-maskable-512.png
```

Target پیشنهادی:

```text
frontend/web/favicon.png
frontend/web/icons/
```

تصمیم MVP:

- `frontend/zomia_Branding/web/favicon.png` به‌روزرسانی شده و به‌عنوان icon اصلی web استفاده می‌شود.
- آیکن‌های 192/512 و maskable به‌روزرسانی شده‌اند و برای web app استفاده می‌شوند.
- جایگزینی کامل app iconهای platform-specific native بعد از دریافت package نهایی برندینگ انجام می‌شود.

## Dependencies مورد نیاز

برای Branding Integration فقط این dependency لازم است:

```yaml
flutter_svg: ^2.0.7
```

`google_fonts` وارد MVP نمی‌شود. فایل رسمی Sofia Sans از brand package به‌صورت local asset در پروژه اصلی ثبت می‌شود.

فعلاً این موارد از Template وارد MVP نمی‌شوند مگر وقتی feature مربوطه برسد:

- `qr_flutter`: برای Customer QR display در فاز بعد
- `font_awesome_flutter`: فقط اگر آیکن‌های Template واقعاً نیاز شوند
- `auto_size_text`: فقط اگر مشکل جدی fit متن داشته باشیم
- `badges`: فقط اگر notification/status badge پیچیده‌تر شود
- map/geolocation/image/payment dependencies: خارج از MVP فعلی

## Brand Colors

رنگ‌های اصلی از logo و theme قدیمی استخراج می‌شوند.

### Primary Tokens

```text
brandOrange: #FFA100
brandOrangeDark: #FFAA00
brandTeal: #18AA99
brandPurple: #827AE1
brandRed: #FF5963
```

### Light Theme

```text
primary: #FFA100
secondary: #18AA99
tertiary: #827AE1
alternate: #FF5963
primaryText: #101213
secondaryText: #57636C
primaryBackground: #F4F6FC
surface: #FFFFFF
line: #DBE2E7
success: #04A24C
warning: #FCDC0C
error: #E21C3D
info: #1C4494
```

### Dark Theme

Dark theme در Template وجود دارد، اما برای MVP فقط tokenهایش آماده می‌ماند. پیاده‌سازی فعال dark mode در MVP انجام نمی‌شود.

```text
primary: #FFAA00
secondary: #18AA99
primaryText: #FFFFFF
secondaryText: #95A1AC
primaryBackground: #262D34
surface: #1A1F24
line: #22282F
```

## Typography

Template از `Sofia Sans` استفاده می‌کند.

تصمیم MVP:

- عدم وابستگی runtime به Google Fonts
- استفاده از فایل local font با font family `Sofia Sans`
- تعریف typography در theme مرکزی پروژه
- نگه داشتن متن‌های قابل مشاهده frontend به زبان انگلیسی

Scale استخراج‌شده:

```text
displayLarge: 57
displayMedium: 45
displaySmall: 32 mobile / 36 tablet-desktop
headlineLarge: 32
headlineMedium: 28
headlineSmall: 24
titleLarge: 22 weight 500
titleMedium: 18 weight 500
titleSmall: 16 weight 500
labelLarge: 14 weight 500
labelMedium: 12 weight 500
labelSmall: 11 weight 500
bodyLarge: 16
bodyMedium: 14
bodySmall: 12
```

## Spacing, Radius, Shadow

Source:

```text
frontend/zomia_Branding/lib/constants/spacing.dart
frontend/zomia_Branding/lib/components/ui_constants.dart
```

Tokens پیشنهادی:

```text
screenPadding: 16
cardSpacing: 12
cardPadding: 16
smallPadding: 8
xsPadding: 4
cardRadius: 12
smallRadius: 8
cardShadow: blur 4, y 2, color #000000 with low opacity
```

نکته طراحی:

- برای فرم‌ها و پنل عملیاتی Staff می‌توان radius 12 را نگه داشت.
- برای cardهای پرتکرار داخل پنل، اگر UI سنگین شد، radius می‌تواند به 8 کاهش یابد تا با طراحی MVP کاربردی‌تر شود.

## Component Patterns قابل استخراج

این فایل‌ها مستقیم کپی نمی‌شوند؛ فقط الگوی آن‌ها در architecture فعلی بازنویسی می‌شود.

```text
frontend/zomia_Branding/lib/widgets/new_login_widget.dart
frontend/zomia_Branding/lib/widgets/standard_text_field.dart
frontend/zomia_Branding/lib/widgets/animated_button.dart
frontend/zomia_Branding/lib/widgets/status_badge.dart
frontend/zomia_Branding/lib/components/empty_state_widget.dart
frontend/zomia_Branding/lib/widgets/skeleton_loading.dart
frontend/zomia_Branding/lib/widgets/app_bars.dart
```

### Login Screen

الگوهای قابل استخراج:

- logo در بالا
- عرض مرکزی حداکثر حدود `530`
- padding اصلی `24`
- title/subtitle ساده
- فرم email/password
- password visibility
- loading/error state

مواردی که نباید منتقل شود:

- API service قدیمی
- Auth manager قدیمی
- Token manager قدیمی
- localization قدیمی
- navigation قدیمی

### Standard Text Field

الگوهای قابل استخراج:

- radius `12`
- filled surface
- focus border با رنگ primary
- error border با رنگ error
- padding داخلی حدود `20 x 16`

### Button

الگوهای قابل استخراج:

- loading state
- disabled state
- optional icon
- touch feedback ساده

برای MVP بهتر است این به شکل یک کامپوننت کوچک داخلی بازنویسی شود، نه انتقال مستقیم کلاس قدیمی.

### Badge / Status

الگوهای قابل استخراج:

- background با opacity کم
- border هم‌رنگ status
- font size کوچک

برای statusهای Staff Panel مثل `Active`, `Used`, `Expired`, `Completed` مفید است.

## Mapping به پروژه فعلی

پیشنهاد ساختار:

```text
frontend/
  assets/
    brand/
      zomia_logo.svg
  lib/
    app/
      brand/
        brand_assets.dart
        brand_colors.dart
        brand_spacing.dart
        brand_typography.dart
      theme.dart
    shared/
      widgets/
        zomia_button.dart
        zomia_text_field.dart
        status_badge.dart
```

در صورت کوچک نگه داشتن MVP، می‌توان ابتدا فقط این‌ها را ساخت:

```text
frontend/assets/brand/zomia_logo.svg
frontend/lib/app/brand/brand_colors.dart
frontend/lib/app/brand/brand_spacing.dart
frontend/lib/app/theme.dart
```

و کامپوننت‌های مشترک را فقط وقتی واقعاً در بیش از یک صفحه استفاده شدند اضافه کرد.

## ترتیب پیاده‌سازی پیشنهادی

1. فقط logo و web icons لازم را به پروژه فعلی منتقل کنیم.
2. `flutter_svg` را اضافه کنیم.
3. color/spacing/typography tokens را در theme فعلی تعریف کنیم.
4. Login screen فعلی F1 را با برند Zomia هماهنگ کنیم.
5. Auth و Staff Context logic فعلی را دست‌نخورده نگه داریم.
6. تست‌های موجود را با متن‌های انگلیسی حفظ کنیم.
7. `flutter analyze`, `flutter test`, `flutter build web` را اجرا کنیم.

## خروجی مورد انتظار Branding Integration

پس از این قدم، frontend باید:

- logo رسمی Zomia را در Login screen نشان دهد
- رنگ‌های اصلی Zomia را در theme داشته باشد
- فونت Sofia Sans را از asset local استفاده کند
- فرم‌ها و buttonها ظاهر consistent داشته باشند
- همچنان فقط متن انگلیسی در UI نشان دهد
- بدون تغییر در backend contract کار کند

## تصمیم‌های نهایی‌شده

- فونت به‌صورت local font از brand package اصلی اضافه شده است؛ Google Fonts وارد MVP نمی‌شود.
- dark mode در MVP فعال نمی‌شود و فقط tokenهایش آماده می‌ماند.
- `favicon.png` و web app iconهای 192/512 به‌روزرسانی شده‌اند و در MVP استفاده می‌شوند.
- Template فعلاً به‌عنوان reference محلی باقی می‌ماند و بعد از production می‌تواند حذف یا ignore شود.
