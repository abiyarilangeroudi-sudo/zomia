# Flutter F7: UI / Branding Recovery

## Goal

هدف F7 این است که UI فعلی از حالت پراکنده و چندسبکی خارج شود و به یک سیستم کوچک، قابل نگهداری و هماهنگ با برند Zomia تبدیل شود.

این فاز redesign کامل محصول نیست. اولویت با یکدست‌سازی، کاهش chaos و ساخت foundation برای توسعه بعدی است.

## Core Rule

از این فاز به بعد، هر نوع UI pattern باید یک منبع حقیقت داشته باشد.

```text
One component type -> one canonical implementation
```

مثال:

- فقط یک مدل Card اصلی داشته باشیم.
- فقط یک مدل status/error/success banner داشته باشیم.
- فقط یک مدل confirmation dialog داشته باشیم.
- فقط یک مدل app bar داشته باشیم.

اگر صفحه‌ای نیاز متفاوتی دارد، اول باید مشخص شود:

```text
variant است یا component جدید؟
```

بدون این تصمیم، component جدید ساخته نمی‌شود.

## Reference Template Use

Template در مسیر زیر فقط reference است:

```text
frontend/zomia_Branding/
```

از template کپی خام نمی‌کنیم، چون شامل FlutterFlow، mock service، navigation قدیمی و screenهای خارج از MVP است.

از template فقط این الگوها استخراج می‌شوند:

- AppBar visual language
- Text field style
- Empty state style
- Status badge style
- QR presentation style
- Campaign progress visual style
- General spacing/radius/shadow rhythm

## Do Not Import

این موارد نباید وارد app اصلی شوند:

- FlutterFlow theme کامل
- Google Fonts runtime loading
- mock services/providers
- old navigation/drawer system
- old business/customer flows
- generated build folders
- duplicate screen implementations

## Target Folder Structure

کامپوننت‌های UI مشترک باید در مسیر زیر قرار بگیرند:

```text
frontend/lib/app/ui/
  shared layout components
  shared surface components
  shared form components
  shared feedback components
  MVP workflow components
```

Design tokenها در مسیر فعلی باقی می‌مانند:

```text
frontend/lib/app/brand/
  brand_assets.dart
  brand_colors.dart
  brand_spacing.dart
```

اگر token جدید لازم شد، اول همین فایل‌ها گسترش پیدا می‌کنند. ساخت token پراکنده داخل screenها ممنوع است.

## Component Registry

### Layout

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `AppScaffold` | ساختار صفحه، padding، background، safe area | `scroll`, `fixed` |
| `AppTopBar` | title/action/sign out/back | `main`, `modal`, `service`, `business` |
| `BottomNavBar` | navigation پایین dashboardها | selected item |

### Surface

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `AppCard` | container اصلی برای بخش‌های صفحه | `default`, `highlight`, `compact` |
| `SectionHeader` | عنوان و action کوچک برای section | `default` |
| `AppListRow` | ردیف لیست برای Business/Staff/Mission/Campaign/Reward Template | `tap`, `static` |
| `MetricPill` | badge عددی/وضعیتی کوچک | color token |

### Forms

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `AppTextField` | همه inputهای متنی | `password`, `number`, `email`, `multiline` |
| `SelectField` | dropdown رسمی فرم‌ها | typed options |
| `CheckboxRow` | انتخاب Missionها یا گزینه‌های setup | `checked`, `unchecked` |
| `PrimaryButton` | action اصلی هر section | `loading`, `icon` |
| `SecondaryButton` | action فرعی | `icon` |

### Feedback

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `InlineBanner` | success/error/info/warning پیام‌های inline | `success`, `error`, `info`, `warning` |
| `EmptyStateView` | حالت خالی قابل تکرار | `small`, `large` |
| `LoadingState` | loading استاندارد sectionها | default |
| `ConfirmDialog` | confirmation برای actionهای حساس | `destructive`, `standard` |
| `StatusBadge` | وضعیت‌های کوچک | `success`, `warning`, `error`, `info`, `neutral` |

### Loyalty Specific

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `QrCard` | نمایش QR و token fallback | `customer`, `staff-scan` |
| `ScannerSheetFrame` | preview/structure برای camera scan sheet | `compact`, `full` |
| `ProgressCard` | campaign progress مشتری | `active`, `completed` |
| `RewardCard` | نمایش reward فعال | `customer`, `staff-action` |
| `MissionRow` | mission/action row با quantity controls | `quantity` |

## Current Screens To Recover

### Login

نیازها:

- حفظ نسخه روی صفحه
- هماهنگی کامل با logo، typography و field/button style
- error banner استاندارد
- password visibility

### Customer QR

نیازها:

- QR مرکز تجربه بماند
- Campaign Progress با `ProgressCard`
- Active Rewards با `RewardCard`
- Empty state تمیز برای نبود progress/reward

### Staff Service Panel

نیازها:

- شکستن فایل بزرگ به section/componentهای کوچک
- scan/resolve flow واضح‌تر
- customer summary بالاتر از actions
- mission quantity controls استاندارد
- reward use confirmation با `ConfirmDialog`

### Owner Setup

نیازها:

- تقسیم به setup sections
- فرم‌ها با `AppTextField`
- list rowهای یکدست
- success/error inline با `InlineBanner`
- حفظ scope حداقلی: Staff, Mission, Campaign, Reward Template

### Business Select

نیازها:

- card/list یکدست
- empty/error state استاندارد

## Implementation Order

### F7.1 Design System Foundation

- ساخت `frontend/lib/app/ui/`
- ساخت componentهای پایه
- ساخت صفحه موقت `UI Component Catalog`
- لینک موقت catalog از روی version label در Login
- به‌روزرسانی theme/tokens فقط در صورت نیاز
- اضافه کردن doc usage کوتاه

### F7.1.1 MVP Component Coverage

- حذف پیشوند `Zomia` از نام componentهای design system
- پوشش QR, Reward, Mission quantity, List row, Select, Checkbox, Metric, Loading, Scanner preview, Confirm dialog در catalog
- تکمیل `UI Component Catalog` قبل از شروع recovery صفحه‌ها

### F7.2 Login Recovery

- استفاده از `AppTextField`
- استفاده از `InlineBanner`
- حفظ version label
- password visibility
- آماده‌سازی مسیر آینده برای `Customer Register`

### F7.3 Customer Dashboard Recovery

- استفاده از `QrCard`
- استفاده از `ProgressCard`
- استفاده از `RewardCard`
- QR و Campaign Progress به عنوان بخش‌های Customer Dashboard دیده می‌شوند، نه صفحه‌های جدا از هم

### F7.4 Staff Dashboard Recovery

- component split
- confirmation dialog استاندارد
- کاهش visual clutter
- Service Panel و QR Scan بخش‌های Staff Dashboard هستند

### F7.5 Owner Dashboard Recovery

- setup sections استاندارد
- list/form consistency
- Staff/Mission/Campaign/Reward Template بخش‌های Owner Dashboard هستند

## Temporary UI Catalog

برای ارزیابی بصری قبل از پیاده‌سازی recovery، یک صفحه موقت catalog ساخته می‌شود:

```text
/ui-catalog
```

دسترسی موقت:

```text
Login -> click version label
```

این صفحه بعداً می‌تواند حذف شود، اما تا زمان تثبیت design system باید محل مرور همه componentهای رسمی باشد.

## Register Direction

بعد از UI recovery باید مسیر ثبت‌نام روشن شود:

- Customer می‌تواند خودش register کند.
- Owner register صفحه جداگانه دارد.
- Staff از طریق Owner ساخته می‌شود و self-register ندارد.

## Review Checklist

قبل از merge هر تغییر UI:

- آیا component جدید واقعاً لازم است؟
- آیا component مشابه در `frontend/lib/app/ui/` وجود دارد؟
- آیا رنگ/radius/spacing hard-coded شده است؟
- آیا button/text داخل container جا می‌شود؟
- آیا mobile و desktop قابل استفاده‌اند؟
- آیا frontend UI همچنان English است؟
- آیا نسخه Flutter افزایش یافته است؟
- آیا widget tests پاس شده‌اند؟
