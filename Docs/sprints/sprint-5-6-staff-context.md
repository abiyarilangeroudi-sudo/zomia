# Sprint 5.6: Staff Context Endpoint

## هدف Sprint

هدف Sprint 5.6 آماده کردن backend برای شروع Flutter MVP است.

بعد از login، Staff Panel باید بداند Staff به کدام Business یا Businessها وصل است. بدون این endpoint، Flutter مجبور می‌شود `business_id` را دستی یا hard-coded نگه دارد که برای MVP واقعی مناسب نیست.

این Sprint فقط backend است و Flutter را شروع نمی‌کند.

## مسئله

تا Sprint 5.5، Staff می‌توانست با داشتن `business_id` این کارها را انجام دهد:

```text
Resolve QR
List service missions
Register action by QR
Use reward by QR
```

اما خود Flutter هنوز نمی‌دانست `business_id` را از کجا بگیرد.

## تصمیم طراحی

endpoint جدید در Identity اضافه شد:

```text
GET /api/v1/staff/me/context
```

چرا در Identity؟

- این endpoint درباره session/user context است
- Staff Membership و Business دسترسی بخشی از Identity Engine هستند
- Loyalty یا QR نباید مسئول تشخیص context اولیه Staff بعد از login باشند

## API Contract

### Staff: My Context

```text
GET /api/v1/staff/me/context
```

Headers:

```text
Authorization: Bearer {staff_jwt}
```

Response:

```json
{
  "staff": {
    "id": "uuid",
    "email": "staff@example.com",
    "phone": null,
    "full_name": "Staff One",
    "role": "staff",
    "is_active": true,
    "created_at": "2026-06-10T00:00:00Z"
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

Rules:

- فقط Staff مجاز است
- فقط membershipهای active برگردانده می‌شوند
- خروجی `businesses` آرایه است، حتی اگر در MVP فقط یک Business رایج باشد

## Flutter Usage

جریان پیشنهادی Flutter بعد از این Sprint:

```text
Staff Login
-> Store JWT
-> GET /staff/me/context
-> اگر یک Business بود، مستقیم وارد Service Panel شود
-> اگر چند Business بود، Staff یکی را انتخاب کند
-> Service Panel با business_id انتخاب‌شده کار کند
```

## Tests

Sprint 5.6 باید تست داشته باشد برای:

- Staff بتواند context خودش را بگیرد
- Staff با چند Business همه membershipهای active را ببیند
- non-staff نتواند context Staff را بگیرد

## Exit Criteria

Sprint 5.6 وقتی بسته می‌شود که:

- endpoint `GET /api/v1/staff/me/context` وجود داشته باشد
- response برای Flutter کافی باشد
- تست‌ها پاس شوند
- OpenAPI endpoint جدید را نشان دهد
