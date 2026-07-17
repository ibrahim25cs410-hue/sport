# لوحة إدارة رياضة (Admin)

موقع ويب مكتبي لإدارة منصة حجز الملاعب — مربوط مباشرة بـ API الإنتاج:

`https://sports-x7v7.onrender.com/api`

## التشغيل محلياً

```powershell
cd web-admin
npm install
npm run dev
```

يفتح على `http://localhost:5174` (بدون `/panel` في وضع التطوير — Vite يستخدم `/` محلياً إذا غيّرت base... حالياً base هو `/panel/`).

للتطوير بنفس مسار الإنتاج:

```powershell
# من جذر المستودع — يبني اللوحة ويضعها في public/panel
npm run build
npm start
# ثم افتح http://localhost:3000/panel/
```

## على Render (الإنتاج)

اللوحة تُخدم من نفس خدمة API:

**https://sports-x7v7.onrender.com/panel/**

`npm run build` على Render يبني `web-admin` وينسخ الملفات إلى `public/panel`.

## البناء للإنتاج

```powershell
cd web-admin
npm run build
```

أو من الجذر:

```powershell
npm run build
```

## الدخول

يحتاج حساب بدور `admin` على نفس قاعدة المنصة.

على Render Environment:

```
ADMIN_EMAIL=you@example.com
ADMIN_PASSWORD=strong-password
```

بعد إعادة النشر يُنشأ/يُرقّى الحساب تلقائياً.

## الصلاحيات

- لوحة تحكم وإحصائيات مالية
- إدارة كل الحجوزات (موافقة / رفض / إلغاء / تأكيد دفع نقدي)
- تفعيل/إيقاف وتعديل الملاعب
- الملاك: شحن محفظة، إيقاف/تفعيل، تفاصيل وإيرادات وحركات
- عرض وبحث المستخدمين
