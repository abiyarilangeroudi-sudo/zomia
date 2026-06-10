# نمای کلی محصول

Zomia یک پلتفرم وفاداری برای کسب‌وکارهاست. هدف آن این است که رفتارهای تکرارشونده مشتری مثل خرید، مراجعه، check-in یا معرفی دوست را به امتیاز و پاداش تبدیل کند.

## جریان اصلی محصول

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

## نقش‌ها

### Customer

مشتری نهایی که در برنامه وفاداری شرکت می‌کند، QR خود را نمایش می‌دهد، امتیاز می‌گیرد و پاداش دریافت می‌کند.

### Owner

مالک کسب‌وکار که Business، Staff، Mission، Campaign و Rewardها را مدیریت می‌کند.

### Staff

کارمند یا اپراتور کسب‌وکار که QR مشتری را اسکن می‌کند، Action ثبت می‌کند، Rewardهای فعال را می‌بیند و Reward را مصرف‌شده می‌کند.

### Admin

مدیر سطح پلتفرم. در MVP فقط role آن وجود دارد؛ پنل و عملیات کامل Admin بعداً ساخته می‌شود.

## هدف MVP

MVP نباید همه ایده‌های Zomia را بسازد. MVP باید فقط یک چرخه واقعی وفاداری را end-to-end ثابت کند:

```text
Owner یک Business می‌سازد
Owner یک Staff می‌سازد
Customer قابل شناسایی می‌شود
Staff QR مشتری را اسکن می‌کند
Staff یک Action ثبت می‌کند
سیستم Point ثبت می‌کند
سیستم یک Individual Campaign را بررسی می‌کند
در صورت تکمیل شرط، Reward ساخته می‌شود
Staff می‌تواند Reward را Use کند
```

## خارج از MVP

این موارد برای آینده مهم‌اند، اما در MVP اول ساخته نمی‌شوند:

- Group Campaign
- Cross-Network Campaign
- Fans Group
- Business Partner Club
- Marketplace
- Gamification
- Advanced Analytics
- Full Admin Panel
- OAuth
- Multi-branch operations

