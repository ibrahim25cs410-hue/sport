# Riyada — دليل التشغيل (لابتوب / أندرويد / آيفون)

## المتطلبات

| الأداة | الرابط |
|--------|--------|
| .NET 8 SDK | https://dotnet.microsoft.com/download |
| Flutter SDK | https://flutter.dev |

```bash
dotnet --version   # 8.x
flutter doctor     # تأكد من Android / iOS / Windows
```

---

## 1. تشغيل الخادم (Backend)

```bash
cd SportsApp/Api
dotnet restore
dotnet run
```

- Swagger: http://localhost:5000/swagger
- حساب تجريبي: `owner@test.com` / `123456`

---

## 2. تشغيل التطبيق Flutter

### لابتوب (Windows)

```bash
cd mobile
flutter pub get
flutter run -d windows
```

### محاكي أندرويد

```bash
flutter run -d android
```

يستخدم تلقائياً: `http://10.0.2.2:5000/api`

### محاكي آيفون (Mac)

```bash
flutter run -d ios
```

يستخدم: `http://localhost:5000/api`

### هاتف حقيقي (نفس شبكة الواي فاي)

اعرف IP الكمبيوتر (`ipconfig`) ثم:

```bash
flutter run --dart-define=API_HOST=192.168.1.10
```

---

## 3. هيكل المشروع

```
SportsApp/
├── Domain/          كيانات C#
├── Application/     DTOs + قواعد مالية
├── Infrastructure/  EF Core + BookingService
└── Api/             Minimal API + JWT

mobile/              Flutter
└── lib/
    ├── config/      عنوان API حسب المنصة
    ├── models/
    ├── services/    Dio + JWT
    ├── providers/
    └── screens/
```

---

## 4. الميزات

- تسجيل مستخدم / صاحب ملعب
- JWT آمن (flutter_secure_storage)
- قائمة الملاعب + جدول أسبوع
- حجز مع منع الحجز المزدوج
- لوحة صاحب الملعب + موافقة/رفض
- عمولة **10%** من (سعر الساعة × عدد الساعات) لكل حجز مؤكد

---

## 5. استكشاف الأخطاء

| المشكلة | الحل |
|---------|------|
| Network error على الهاتف | استخدم `--dart-define=API_HOST=IP-الكمبيوتر` |
| 401 Unauthorized | سجّل دخول من جديد |
| dotnet غير موجود | ثبّت .NET 8 SDK |
| لا يوجد جهاز | `flutter devices` |
