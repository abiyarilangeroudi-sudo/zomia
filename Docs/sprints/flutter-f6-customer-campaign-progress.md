# Flutter F6: Customer Campaign Progress

## Goal

Customer باید progress معنی‌دار ببیند: پیشرفت در Campaign مشخص، نه total points عمومی.

این فاز برای جلوگیری از chaos بعد از F2.8 تعریف شد. عددی که به Customer نمایش داده می‌شود فقط وقتی ارزش دارد که جواب دهد:

```text
How close am I to a reward in this campaign?
```

## What Will Be Built

- Backend endpoint برای لیست progressهای Campaign مشتری
- Flutter model و repository برای دریافت campaign progress
- نمایش Campaign Progress در صفحه Customer QR
- حفظ active rewards در همان صفحه
- عدم نمایش total points به Customer

## Product Rule

Customer UI نباید `total points` عمومی نمایش دهد.

نمایش مجاز:

```text
Campaign name
Business name
progress_points / threshold_points
remaining_points
completed/not completed
```

## Backend Contract

```text
GET /api/v1/customers/me/campaigns/progress
```

Response:

```json
[
  {
    "business_id": "uuid",
    "business_name": "Zomia Cafe",
    "campaign_id": "uuid",
    "campaign_name": "Coffee Reward",
    "progress_points": 2,
    "threshold_points": 10,
    "remaining_points": 8,
    "is_completed": false
  }
]
```

## Scope

Inside F6:

- Active individual single-business campaigns only
- Automatic participation only
- Points-based progress only
- Campaigns connected to businesses where Customer already has points or rewards

Outside F6:

- Group Campaign progress
- Cross-Network Campaign progress
- Campaign discovery/marketing
- Repeatable campaign cycles
- Full Customer dashboard redesign
- UI/Branding recovery

## Architecture

```text
Customer QR Screen
-> Customer QR Repository
   -> GET /customers/me/status
   -> GET /customers/me/campaigns/progress
      -> Loyalty Service
         -> Campaign Progress from Points Ledger
```

## Database

F6 migration جدید ندارد.

Progress از جدول‌های موجود محاسبه می‌شود:

- `campaigns`
- `campaign_missions`
- `points_ledger`
- `loyalty_actions`
- `loyalty_action_items`
- `campaign_completions`

## Tests

- Backend test برای endpoint لیستی progress
- Flutter widget test برای نمایش progress در Customer QR screen
- Regression rule: هیچ `total points` عمومی در Customer UI اضافه نشود

