# نشر تطبيق رياضة على المتاجر

## قائمة التحقق السريعة

- [x] Package ID: `iq.riyada.riyada`
- [x] إصدار: `1.0.0+1` في `pubspec.yaml`
- [x] `config/env.prod.json` — رابط API الإنتاج
- [x] أيقونة التطبيق + splash
- [x] سياسة خصوصية: `/privacy` على الويب
- [x] نصوص المتاجر: `store/play/` و `store/ios/`
- [ ] `android/key.properties` + keystore (شغّل `scripts/generate_keystore.ps1`)
- [ ] Firebase: `flutterfire configure`
- [ ] API يعمل على `https://api.riyada.iq/api`

---

## بناء واحد — كل شيء

```powershell
cd d:\sport\mobile
.\scripts\prepare_store_release.ps1
```

ينتج: `build\app\outputs\bundle\release\app-release.aab`

---

## Android (Google Play) — خطوة بخطوة

### 1. مفتاح التوقيع

```powershell
.\scripts\generate_keystore.ps1
# عدّل android\key.properties بكلمات مرور قوية
```

### 2. Firebase

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
# يضيف google-services.json و GoogleService-Info.plist
```

### 3. بناء AAB

```powershell
.\scripts\build_release_aab.ps1
```

### 4. Google Play Console

1. تطبيق جديد → `iq.riyada.riyada`
2. ارفع `app-release.aab` → Internal testing
3. لقطات شاشة (هاتف 6.7")
4. انسخ النصوص من `store/play/listing_ar.md`
5. سياسة الخصوصية: `https://riyada.iq/privacy`
6. Data safety + Content rating

### Fastlane (اختياري)

```bash
cd mobile/android
fastlane build
fastlane beta   # يتطلب حساب Play + JSON key
```

---

## iOS (App Store) — يتطلب Mac

```bash
cd mobile
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/ios/symbols \
  --dart-define-from-file=config/env.prod.json \
  --export-options-plist=ios/ExportOptions.plist
```

1. Xcode → Signing & Capabilities → Team
2. عدّل `ios/ExportOptions.plist` → `teamID`
3. App Store Connect → Bundle `iq.riyada.riyada`
4. انسخ النصوص من `store/ios/listing_ar.md`
5. `cd ios && fastlane beta` للرفع على TestFlight

---

## إعدادات الإنتاج في التطبيق

| الملف | الغرض |
|-------|--------|
| `config/env.prod.json` | API URL + SSL pinning |
| `android/key.properties` | توقيع Play Store |
| `android/app/google-services.json` | Firebase Android |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS |

---

## بعد النشر

- غيّر كلمة مرور المدير `admin@riyada.iq`
- فعّل SSL pinning في `env.prod.json` بعد استقرار الشهادة
- احفظ `build/app/outputs/symbols` لتحليل الأعطال
