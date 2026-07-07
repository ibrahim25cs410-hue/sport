#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $root "mobile")
Write-Host "[رياضة] تشغيل على Chrome..." -ForegroundColor Green
flutter pub get
flutter run -d chrome
