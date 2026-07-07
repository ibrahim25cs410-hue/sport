#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $root "mobile")
Write-Host "تشغيل تطبيق رياضة (Chrome)..." -ForegroundColor Green
flutter pub get
flutter run -d chrome
