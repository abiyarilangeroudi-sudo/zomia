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
- [Flutter MVP Phase](./roadmap/flutter-mvp-phase.md)
- [Sprint 1: Identity Engine](./sprints/sprint-1-identity.md)
- [Sprint 2: Loyalty Foundation](./sprints/sprint-2-loyalty-foundation.md)
- [Sprint 3: Individual Campaign](./sprints/sprint-3-individual-campaign.md)
- [Sprint 4: Reward Engine](./sprints/sprint-4-reward-engine.md)
- [Sprint 5: QR Staff Workflow](./sprints/sprint-5-qr-staff-workflow.md)
- [Sprint 5.5: Staff Panel API Contract](./sprints/sprint-5-5-staff-panel-contract.md)
- [Sprint 5.6: Staff Context Endpoint](./sprints/sprint-5-6-staff-context.md)
- [Flutter F0: Project Setup](./sprints/flutter-f0-project-setup.md)
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

Sprint 5 پیاده‌سازی و با PostgreSQL واقعی smoke test شده است.

Sprint 5:

- Customer QR Token اضافه شد
- QR Token خام در database ذخیره نمی‌شود و فقط `token_hash` ذخیره می‌شود
- Customer می‌تواند QR خودش را issue/rotate کند
- Staff می‌تواند QR را برای Business خودش resolve کند
- Staff Service Summary شامل customer، points، active rewards و recent actions است
- Staff می‌تواند Action را با QR ثبت کند
- Staff می‌تواند Reward را با QR use کند
- Reward Use با QR همچنان Points Ledger را تغییر نمی‌دهد
- Migration روی PostgreSQL واقعی اجرا شد
- تست‌های QR Staff Workflow پاس شدند

Sprint 5.5 پیاده‌سازی شده است.

Sprint 5.5:

- قرارداد API برای Staff Service Panel روشن‌تر شد
- endpoint مخصوص Staff برای دیدن Missionهای قابل ثبت اضافه شد
- `recent_actions` در Staff Service Summary typed شد
- تست‌های Staff Panel API Contract اضافه شد

Sprint 5.6 پیاده‌سازی شده است.

Sprint 5.6:

- endpoint مخصوص Staff Context اضافه شد
- Flutter بعد از login می‌تواند Businessهای Staff را دریافت کند
- response برای چند Business آینده به صورت آرایه طراحی شد
- تست‌های Staff Context اضافه شد

Flutter F0 پیاده‌سازی شده است.

Flutter F0:

- پروژه Flutter در `frontend/` ساخته شد
- dependencyهای پایه اضافه شد
- app shell و theme و router پایه ساخته شد
- API config و Dio client و secure token storage آماده شد
- `flutter analyze`, `flutter test` و `flutter build web` پاس شدند
