# بناء App Bundle للنشر على Google Play
Set-Location $PSScriptRoot\..

if (-not (Test-Path "config\env.prod.json")) {
    Write-Error "انسخ config\env.prod.json.example إلى config\env.prod.json"
}

if (-not (Test-Path "android\key.properties")) {
    Write-Host "تحذير: android\key.properties غير موجود. شغّل scripts\generate_keystore.ps1"
}

flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create

flutter build appbundle --release `
  --obfuscate `
  --split-debug-info=build/app/outputs/symbols `
  --dart-define-from-file=config/env.prod.json

Write-Host ""
Write-Host "AAB جاهز: build\app\outputs\bundle\release\app-release.aab"
Write-Host "Symbols: build\app\outputs\symbols"
