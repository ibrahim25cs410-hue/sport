# رياضة — تطبيق حجز الملاعب في نينوى

تطبيق لحجز الملاعب الرياضية في محافظة نينوى. يدعم **مستخدمين** (حجز ملاعب) و**أصحاب ملاعب** (إدارة الحجوزات والمالية).

## المنصات

| المنصة | الحالة |
|--------|--------|
| Windows (لابتوب) | ✅ |
| Android | ✅ |
| iOS | ✅ (يتطلب Mac) |
| Web | ✅ (تجريبي) |

## التقنيات

- **الواجهة:** Flutter (Dart)
- **الخادم:** ASP.NET Core 8 Minimal API
- **قاعدة البيانات:** SQLite + Entity Framework Core

## المتطلبات

1. [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
2. [Flutter SDK](https://docs.flutter.dev/get-started/install)
3. Android Studio (للمحاكي) أو Xcode (لـ iOS على Mac)

## التشغيل السريع

### 1. تشغيل الخادم

```powershell
cd SportsApp\Api
dotnet restore
dotnet run --urls "http://0.0.0.0:61082"
```

أو:

```powershell
.\scripts\run-api.ps1
```

افتح Swagger: http://localhost:61082/swagger

### 2. تشغيل التطبيق

```powershell
cd mobile
flutter pub get
flutter run -d windows    # لابتوب ويندوز
flutter run -d android    # محاكي أندرويد
flutter run -d ios        # محاكي iOS (Mac)
```

### 3. الهاتف الحقيقي

1. شغّل الخادم على الكمبيوتر (`0.0.0.0:5000`)
2. اعرف IP الكمبيوتر (مثلاً `192.168.1.10`)
3. من إعدادات التطبيق → أدخل IP، أو:

```powershell
flutter run --dart-define=API_HOST=192.168.1.10
```

## حسابات تجريبية

| الدور | البريد | كلمة المرور |
|-------|--------|-------------|
| صاحب ملعب | owner@test.com | 123456 |
| مستخدم | user@test.com | 123456 |

## الميزات

### المستخدم
- تصفح الملاعب في نينوى
- حجز 1–2 ساعة
- إشعارات (موافقة / رفض)
- إلغاء الحجز (قبل 24 ساعة من الموعد)

### صاحب الملعب
- تسجيل ملعب
- موافقة / رفض الحجوزات
- لوحة مالية (إيرادات، عمولة 10% من سعر الساعة، صافي)

## بناء APK

```powershell
.\scripts\build-apk.ps1
```

الملف: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## هيكل المشروع

```
رياضة/
├── SportsApp/          # Backend (.NET)
│   ├── Api/            # نقاط API
│   ├── Domain/         # الكيانات
│   ├── Application/    # DTOs والقواعد
│   └── Infrastructure/ # DB والخدمات
├── mobile/             # تطبيق Flutter
└── scripts/            # سكربتات التشغيل والبناء
```

## ملاحظات

- إذا ظهرت أخطاء قاعدة البيانات، احذف `SportsApp/Api/sports.db` وأعد تشغيل الخادم
- مجلد `web/` تطبيق React قديم — غير مستخدم في النسخة النهائية

## العمولة

عمولة المنصة **10%** من (سعر الساعة × عدد الساعات المحجوزة) لكل حجز مؤكد — تُخصم من إيرادات صاحب الملعب.
