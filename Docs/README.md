# مستندات Zomia

این پوشه منبع اصلی تصمیم‌ها، محدوده MVP، معماری و برنامه ساخت Zomia است.

Zomia یک پلتفرم وفاداری است که جریان اصلی آن این است:

```text
Customer QR
-> Staff Scan
-> Action Registration
-> Loyalty Engine
-> Point Accumulation
-> Campaign Evaluation
-> Reward Generation
-> Reward Use
```

## فهرست سندها

- [نمای کلی محصول](./01-product-overview.md)
- [محدوده MVP](./02-mvp-scope.md)
- [معماری](./03-architecture.md)
- [واژه‌نامه دامنه](./04-domain-glossary.md)
- [Workflowها](./05-workflows.md)
- [Roadmap](./06-roadmap.md)
- [Local Development](./07-local-development.md)
- [Sprint 1: Identity Engine](./sprints/sprint-1-identity.md)
- [Sprint 2: Loyalty Foundation](./sprints/sprint-2-loyalty-foundation.md)
- [Sprint 3: Individual Campaign](./sprints/sprint-3-individual-campaign.md)
- [Sprint 4: Reward Engine](./sprints/sprint-4-reward-engine.md)
- [تصمیم 0001: محدوده MVP](./decisions/0001-mvp-scope.md)
- [تصمیم 0002: تکنولوژی‌های MVP لوکال](./decisions/0002-local-mvp-stack.md)

## وضعیت فعلی

Sprint 1 کامل شده و به عنوان baseline امن ثبت شده است.

انجام شده:

- اسکلت Backend
- مدل‌های Identity
- مدل Business Profile
- مدل Staff Membership
- JWT Authentication
- APIهای Owner برای مدیریت Business و Staff
- Alembic migration اولیه
- تست‌های API

Sprint 2 پیاده‌سازی و با PostgreSQL واقعی smoke test شده است.

تأیید شده:

- PostgreSQL با Docker Compose اجرا شد
- Alembic migration روی PostgreSQL واقعی اجرا شد
- API با دیتابیس واقعی smoke test شد
- OpenAPI روی backend در حال اجرا بررسی شد
- Git baseline commit ساخته شد

Sprint 2:

- Mission API اضافه شد
- Action چندآیتمی اضافه شد
- Points Ledger اضافه شد
- Idempotency برای Action Registration اضافه شد
- Basic Audit اضافه شد
- Migration روی PostgreSQL واقعی اجرا شد
- API با دیتابیس واقعی smoke test شد

Sprint 3 پیاده‌سازی و با PostgreSQL واقعی smoke test شده است.

Sprint 3:

- Individual Campaign API اضافه شد
- Campaign به Missionها از طریق `campaign_missions` وصل شد
- Campaign Evaluation بعد از Action Registration اضافه شد
- Campaign Completion اضافه شد
- Progress مشتری از Points Ledger محاسبه می‌شود
- Reward در Sprint 3 ساخته نمی‌شود
- Migration روی PostgreSQL واقعی اجرا شد
- تست‌های Campaign و idempotency پاس شدند

Sprint 4 پیاده‌سازی و با PostgreSQL واقعی smoke test شده است.

Sprint 4:

- Reward Template API اضافه شد
- Generated Reward بعد از Campaign Completion ساخته می‌شود
- Customer می‌تواند Rewardهای خودش را ببیند
- Staff می‌تواند Reward فعال را use کند
- Reward Use یک Action از نوع `reward_use` می‌سازد
- Reward Use باعث تغییر Points Ledger نمی‌شود
- Reward برای Cross آینده `issuer_business_id`, `redeem_scope`, `settlement_policy` دارد
- Generated Reward برای Group آینده `source_type`, `source_id`, `customer_id` دارد
- Reward Usage محل مصرف را با `redeemed_business_id` ثبت می‌کند
- Migration روی PostgreSQL واقعی اجرا شد
- تست‌های Reward Engine و idempotency پاس شدند
