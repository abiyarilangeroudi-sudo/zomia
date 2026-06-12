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
  zomia_app_bar.dart
  zomia_badge.dart
  zomia_banner.dart
  zomia_button.dart
  zomia_card.dart
  zomia_confirm_dialog.dart
  zomia_empty_state.dart
  zomia_progress_card.dart
  zomia_scaffold.dart
  zomia_text_field.dart
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
| `ZomiaScaffold` | ساختار صفحه، padding، background، safe area | `scroll`, `fixed` |
| `ZomiaAppBar` | title/action/sign out/back | `main`, `modal`, `service` |

### Surface

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `ZomiaCard` | container اصلی برای بخش‌های صفحه | `default`, `highlight`, `compact` |
| `ZomiaSectionHeader` | عنوان و action کوچک برای section | `default` |

### Forms

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `ZomiaTextField` | همه inputهای متنی | `password`, `number`, `email`, `multiline` |
| `ZomiaPrimaryButton` | action اصلی هر section | `loading`, `icon` |
| `ZomiaSecondaryButton` | action فرعی | `icon` |

### Feedback

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `ZomiaBanner` | success/error/info/warning پیام‌های inline | `success`, `error`, `info`, `warning` |
| `ZomiaEmptyState` | حالت خالی قابل تکرار | `small`, `large` |
| `ZomiaConfirmDialog` | confirmation برای actionهای حساس | `destructive`, `standard` |
| `ZomiaBadge` | وضعیت‌های کوچک | `success`, `warning`, `error`, `info`, `neutral` |

### Loyalty Specific

| Component | Purpose | Variants allowed |
| --- | --- | --- |
| `ZomiaQrCard` | نمایش QR و token fallback | `customer`, `staff-scan` |
| `ZomiaProgressCard` | campaign progress مشتری | `active`, `completed` |
| `ZomiaRewardCard` | نمایش reward فعال | `customer`, `staff-action` |
| `ZomiaMissionRow` | mission/action row | `selectable`, `quantity` |

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
- Campaign Progress با `ZomiaProgressCard`
- Active Rewards با `ZomiaRewardCard`
- Empty state تمیز برای نبود progress/reward

### Staff Service Panel

نیازها:

- شکستن فایل بزرگ به section/componentهای کوچک
- scan/resolve flow واضح‌تر
- customer summary بالاتر از actions
- mission quantity controls استاندارد
- reward use confirmation با `ZomiaConfirmDialog`

### Owner Setup

نیازها:

- تقسیم به setup sections
- فرم‌ها با `ZomiaTextField`
- list rowهای یکدست
- success/error inline با `ZomiaBanner`
- حفظ scope حداقلی: Staff, Mission, Campaign, Reward Template

### Business Select

نیازها:

- card/list یکدست
- empty/error state استاندارد

## Implementation Order

### F7.1 Design System Foundation

- ساخت `frontend/lib/app/ui/`
- ساخت componentهای پایه
- به‌روزرسانی theme/tokens فقط در صورت نیاز
- اضافه کردن doc usage کوتاه

### F7.2 Login Recovery

- استفاده از `ZomiaTextField`
- استفاده از `ZomiaBanner`
- حفظ version label
- password visibility

### F7.3 Customer QR Recovery

- استفاده از `ZomiaQrCard`
- استفاده از `ZomiaProgressCard`
- استفاده از `ZomiaRewardCard`

### F7.4 Staff Service Panel Recovery

- component split
- confirmation dialog استاندارد
- کاهش visual clutter

### F7.5 Owner Setup Recovery

- setup sections استاندارد
- list/form consistency

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

