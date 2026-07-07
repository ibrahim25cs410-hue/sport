#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $root "SportsApp\Api")

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "خطأ: .NET SDK غير مثبت" -ForegroundColor Red
    exit 1
}

$sdks = & dotnet --list-sdks 2>$null
if (-not $sdks) {
    Write-Host "خطأ: .NET SDK غير مثبت" -ForegroundColor Red
    exit 1
}

Write-Host "تطبيق Migrations على قاعدة البيانات..." -ForegroundColor Green
dotnet ef database update --project ..\Infrastructure\Riyada.Infrastructure.csproj --startup-project .
