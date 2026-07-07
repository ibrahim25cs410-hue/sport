#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $root "mobile")
Write-Host "Building Android APK..." -ForegroundColor Green
flutter pub get
flutter build apk --release
Write-Host "APK: mobile\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
