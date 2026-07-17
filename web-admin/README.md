# لوحة إدارة رياضة (Admin)

موقع ويب مكتبي لإدارة منصة حجز الملاعب — مربوط مباشرة بـ API الإنتاج:

`https://sports-x7v7.onrender.com/api`

## التشغيل محلياً

```powershell
cd web-admin
npm install
npm run dev
```

يفتح على `http://localhost:5174` ويوجّه الطلبات عبر بروكسي Vite إلى Render.

## البناء للإنتاج

```powershell
cd web-admin
npm run build
```

الملفات في `dist/` — انشرها على أي استضافة ثابتة (Render Static / Netlify / Nginx).  
ملف `.env.production` يضبط `VITE_API_BASE` على سيرفر Render.

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
