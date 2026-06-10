# Flutter F1: Auth And Staff Context

## هدف Sprint

هدف F1 این است که Staff بتواند وارد frontend شود و app بعد از login، Business context او را از backend بگیرد.

این Sprint هنوز Staff Service Panel واقعی، QR workflow و camera scan را پیاده‌سازی نمی‌کند.

## Scope

داخل F1:

- Login screen
- اتصال به `POST /api/v1/auth/login`
- ذخیره JWT در secure storage
- اتصال به `GET /api/v1/staff/me/context`
- Auth state با Riverpod
- نمایش Business انتخاب‌شده
- Business selection برای Staffهایی که چند Business دارند
- Sign out
- تست widget برای حالت signed out و sign in موفق

خارج از F1:

- Branding assets
- QR resolve
- Mission list
- Action registration
- Reward use
- Camera scan

## Language Rule

همه متن‌های قابل مشاهده در Flutter انگلیسی هستند.

نمونه متن‌های F1:

```text
Sign in to Staff Service
Email
Password
Select Business
Staff Service
Sign out
```

## Architecture

```text
features/
  auth/
    data/
    domain/
    presentation/
  staff_context/
    domain/
    presentation/
```

## Backend Contracts

### Login

```text
POST /api/v1/auth/login
```

Request:

```json
{
  "email": "staff@example.com",
  "password": "strong-password"
}
```

Response:

```json
{
  "access_token": "jwt",
  "token_type": "bearer"
}
```

### Staff Context

```text
GET /api/v1/staff/me/context
```

Response:

```json
{
  "staff": {
    "id": "uuid",
    "email": "staff@example.com",
    "full_name": "Staff One",
    "role": "staff",
    "is_active": true
  },
  "businesses": [
    {
      "id": "uuid",
      "name": "Zomia Cafe",
      "slug": "zomia-cafe",
      "status": "active",
      "timezone": "Europe/Berlin",
      "currency_code": "EUR",
      "staff_membership_id": "uuid"
    }
  ]
}
```

## UX Flow

```text
App opens
-> read stored token
-> if no token, show Login
-> if token exists, fetch Staff Context
-> if one business, open Staff Home
-> if multiple businesses, show Business Select
```

## Verification

F1 وقتی بسته می‌شود که:

- `flutter analyze` پاس شود
- `flutter test` پاس شود
- `flutter build web` پاس شود
- Login screen render شود
- sign in موفق Staff Context را نمایش دهد

## Implementation Result

F1 پیاده‌سازی و verify شد.

Verification:

- `flutter analyze` پاس شد
- `flutter test` پاس شد
- `flutter build web` پاس شد
