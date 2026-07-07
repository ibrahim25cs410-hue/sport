# تجهيز كامل للنشر على المتاجر (أيقونات + splash + بناء AAB)
Set-Location $PSScriptRoot\..

Write-Host "==> 1/4 التحقق من الأيقونة"
if (-not (Test-Path "assets\images\app_icon.png")) {
    Write-Error "assets\images\app_icon.png مفقود"
}

Write-Host "==> 2/4 Firebase (اختياري)"
if (-not (Test-Path "android\app\google-services.json")) {
    Write-Host "تحذير: android\app\google-services.json غير موجود."
    Write-Host "  شغّل: dart pub global activate flutterfire_cli && flutterfire configure"
}

Write-Host "==> 3/4 أيقونات وشاشة البداية"
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create

Write-Host "==> 4/4 بناء AAB"
& "$PSScriptRoot\build_release_aab.ps1"

Write-Host ""
Write-Host "الخطوات التالية:"
Write-Host "  - Google Play: ارفع app-release.aab"
Write-Host "  - سياسة الخصوصية: https://riyada.iq/privacy"
Write-Host "  - iOS (Mac): flutter build ipa --dart-define-from-file=config/env.prod.json"
