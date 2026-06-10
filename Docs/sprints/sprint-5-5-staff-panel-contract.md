# Sprint 5.5: Staff Panel API Contract

## هدف Sprint

هدف Sprint 5.5 آماده کردن قرارداد backend برای Staff Service Panel است.

این Sprint هنوز Flutter را شروع نمی‌کند و feature دامنه‌ای جدید مثل Group Campaign نمی‌سازد.

تمرکز فقط روی این است که frontend بعداً بداند برای صفحه service چه endpointهایی دارد و چه responseهایی دریافت می‌کند.

## Staff Service Panel MVP

صفحه Staff Service Panel در MVP باید بتواند:

```text
Scan یا دریافت QR token
-> Resolve Customer
-> نمایش Customer Summary
-> دریافت Missionهای قابل انتخاب
-> ثبت Action با یک یا چند Mission
-> نمایش Active Rewards
-> Use Reward
```

## تصمیم‌های طراحی

### Staff نباید endpointهای Owner را برای UI سرویس استفاده کند

endpoint قبلی:

```text
GET /api/v1/owner/missions
```

برای Owner dashboard مناسب است، اما برای Staff Service Panel مناسب نیست.

برای Staff endpoint جدا تعریف شد:

```text
GET /api/v1/staff/service/missions?business_id={business_id}
```

این endpoint:

- فقط Staff را قبول می‌کند
- Staff Membership در Business را بررسی می‌کند
- Missionهای همان Business را برمی‌گرداند
- چیزی از Campaign یا Reward logic را دوباره پیاده نمی‌کند

### Staff Service Summary باید typed باشد

در Sprint 5، `recent_actions` به صورت dict آزاد برمی‌گشت.

در Sprint 5.5 به schema مشخص تبدیل شد:

```text
id
action_type
occurred_at
created_at
```

این باعث می‌شود Flutter contract روشن‌تری داشته باشد.

## API Contracts

### Staff: List Service Missions

```text
GET /api/v1/staff/service/missions?business_id={uuid}
```

Response:

```json
[
  {
    "id": "uuid",
    "business_id": "uuid",
    "name": "Buy Coffee",
    "description": "Buy Coffee mission",
    "mission_type": "purchase",
    "point_value": 1,
    "is_active": true,
    "created_at": "2026-06-10T00:00:00Z"
  }
]
```

Rules:

- فقط Staff مجاز است
- Staff باید عضو Business باشد
- endpoint فقط read-only است

### Staff Service Summary

Response مشترک `resolve`, `register action by QR` و `use reward by QR`:

```json
{
  "business_id": "uuid",
  "customer": {
    "id": "uuid",
    "email": "ali@example.com",
    "full_name": "Ali",
    "role": "CUSTOMER",
    "is_active": true,
    "created_at": "2026-06-10T00:00:00Z"
  },
  "points": 5,
  "active_rewards": [],
  "recent_actions": [
    {
      "id": "uuid",
      "action_type": "mission_progress",
      "occurred_at": "2026-06-10T00:00:00Z",
      "created_at": "2026-06-10T00:00:00Z"
    }
  ]
}
```

## Tests

Sprint 5.5 باید تست داشته باشد برای:

- Staff بتواند Missionهای Business خودش را ببیند
- Staff نتواند Missionهای Business دیگر را ببیند
- Staff Service Summary بعد از ثبت Action دارای `recent_actions` typed باشد

## Exit Criteria

Sprint 5.5 وقتی بسته می‌شود که:

- endpoint Mission list مخصوص Staff Service Panel وجود داشته باشد
- responseهای Staff Service Summary typed باشند
- تست‌ها پاس شوند
- OpenAPI endpoint جدید را نشان دهد
