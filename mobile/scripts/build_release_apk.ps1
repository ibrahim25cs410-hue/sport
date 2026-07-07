# بناء APK إنتاج (اختبار محلي — Play Store يتطلب AAB)
Set-Location $PSScriptRoot\..

if (-not (Test-Path "config\env.prod.json")) {
    Write-Error "انسخ config\env.prod.json.example إلى config\env.prod.json"
}

flutter pub get

flutter build apk --release `
  --obfuscate `
  --split-debug-info=build/app/outputs/symbols `
  --dart-define-from-file=config/env.prod.json

Write-Host "APK: build/app/outputs/flutter-apk/app-release.apk"
Write-Host "Symbols (احفظها لتحليل الأعطال): build/app/outputs/symbols"
