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
- [تصمیم 0001: محدوده MVP](./decisions/0001-mvp-scope.md)
- [تصمیم 0002: تکنولوژی‌های MVP لوکال](./decisions/0002-local-mvp-stack.md)

## وضعیت فعلی

Sprint 1 در حال تکمیل است.

انجام شده:

- اسکلت Backend
- مدل‌های Identity
- مدل Business Profile
- مدل Staff Membership
- JWT Authentication
- APIهای Owner برای مدیریت Business و Staff
- Alembic migration اولیه
- تست‌های API

Sprint 1 به عنوان baseline امن ثبت شده است.

تأیید شده:

- PostgreSQL با Docker Compose اجرا شد
- Alembic migration روی PostgreSQL واقعی اجرا شد
- API با دیتابیس واقعی smoke test شد
- OpenAPI روی backend در حال اجرا بررسی شد
- Git baseline commit ساخته شد
