# جاهزية النشر على المتاجر

## ✅ جاهز في المشروع

- Package: `iq.riyada.riyada` | الإصدار: `1.0.0+1`
- أيقونة + splash (Android 12 + iOS)
- توقيع Android (عند وجود `key.properties`)
- `config/env.prod.json` → `https://api.riyada.iq/api`
- إخفاء إعدادات السيرفر في الإنتاج
- HTTPS فقط (Android release)
- iOS 13+ | Podfile | ExportOptions.plist
- سياسة خصوصية: `web` → `/privacy`
- نصوص المتاجر: `store/play/` + `store/ios/`
- Fastlane: `mobile/android/fastlane` + `mobile/ios/fastlane`
- سكربت بناء: `mobile/scripts/prepare_store_release.ps1`

## ⚠️ مطلوب منك قبل الرفع

| الخطوة | الأمر |
|--------|-------|
| مفتاح Android | `mobile\scripts\generate_keystore.ps1` |
| Firebase | `flutterfire configure` |
| API حي | نشر السيرفر على `api.riyada.iq` |
| بناء AAB | `mobile\scripts\build_release_aab.ps1` |
| لقطات شاشة | من جهاز حقيقي |
| iOS | Mac + Apple Developer + `flutter build ipa` |

## بناء سريع

```powershell
cd d:\sport\mobile
.\scripts\prepare_store_release.ps1
```

الملف الناتج: `build\app\outputs\bundle\release\app-release.aab`
