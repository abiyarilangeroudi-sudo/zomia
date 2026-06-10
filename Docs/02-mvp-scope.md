# محدوده MVP

MVP باید کوچک باشد، اما معماری نهایی را خراب نکند.

کوچک یعنی:

- فقط یک workflow کامل وفاداری ساخته شود
- تعداد نقش‌ها و صفحه‌ها حداقلی باشد
- Campaign و Reward با ساده‌ترین حالت شروع شوند
- فقط زیرساخت لازم برای اجرا و verification ساخته شود

آینده‌نگر یعنی:

- مرز دامنه‌ها از ابتدا روشن باشد
- schema جلوی Group و Cross-Network Campaign آینده را نگیرد
- Points به شکل append-only ledger ذخیره شود
- Reward lifecycle داشته باشد
- Actionها قابل audit و idempotent باشند
- منطق تجاری در Service باشد، نه داخل Router

## داخل MVP

### Identity

- ثبت‌نام Customer
- ثبت‌نام Owner
- ساخت Staff توسط Owner
- JWT Authentication
- Role-based access control

### Business

- Business Profile
- Staff Membership
- مدیریت Business توسط Owner

### Loyalty Foundation

- Mission
- Action
- Points Ledger
- Individual Campaign

### Reward Engine

- Reward Template
- Generated Reward
- Reward lifecycle: `active`, `used`, `expired`

### QR Staff Workflow

- Customer QR Token
- Scan Resolve Endpoint
- Register Action Endpoint
- Use Reward Endpoint

### Minimal UI

MVP به کوچک‌ترین UI عملی برای تست workflow واقعی نیاز دارد. اگر Flutter سریع آماده شود، Flutter؛ اگر نه، یک UI ساده‌تر برای validation اولیه قابل قبول است.

## خارج از MVP

- Group Campaign execution
- Cross-Network Campaign execution
- Fans Group management
- Business Club management
- Settlement Engine
- Full Analytics
- Gamification
- Marketplace
- Production CI/CD کامل

## معیار پایان MVP

MVP وقتی کامل است که:

- Owner بتواند Staff بسازد
- Customer با QR شناسایی شود
- Staff بتواند Action ثبت کند
- Points در ledger ثبت شود
- Individual Campaign بتواند Reward تولید کند
- Staff بتواند Reward را Use کند
- APIهای اصلی تست داشته باشند
- Migrationها روی PostgreSQL اجرا شوند
- OpenAPI قابل استفاده باشد

