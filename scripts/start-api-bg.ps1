# يشغّل الخادم في الخلفية إن وُجد .NET SDK — ولا يوقف تشغيل Flutter إن لم يوجد
$ErrorActionPreference = "SilentlyContinue"
$root = Split-Path -Parent $PSScriptRoot
$apiPath = Join-Path $root "SportsApp\Api"

function Test-DotNetSdk {
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { return $false }
    $sdks = & dotnet --list-sdks 2>$null
    return ($sdks -and $sdks.Count -gt 0)
}

if (-not (Test-DotNetSdk)) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  .NET SDK غير مثبت — الخادم لن يعمل!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "التطبيق سيفتح لكن تسجيل الدخول سيفشل." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "الحل: ثبّت .NET 8 SDK (ليس Runtime فقط):" -ForegroundColor Cyan
    Write-Host "https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "بعد التثبيت: أعد تشغيل Cursor ثم اضغط Run مرة أخرى." -ForegroundColor White
    Write-Host ""
    exit 0
}

$portInUse = Get-NetTCPConnection -LocalPort 61082 -State Listen -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "[رياضة] الخادم يعمل مسبقاً على المنفذ 61082" -ForegroundColor Green
    exit 0
}

Write-Host "[رياضة] تشغيل الخادم على http://localhost:61082 ..." -ForegroundColor Green
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Set-Location '$apiPath'; Write-Host 'Riyada API - http://localhost:61082/swagger' -ForegroundColor Green; dotnet run --urls http://0.0.0.0:61082"
)

for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 1
    $listening = Get-NetTCPConnection -LocalPort 61082 -State Listen -ErrorAction SilentlyContinue
    if ($listening) {
        Write-Host "[رياضة] الخادم جاهز على http://localhost:61082" -ForegroundColor Green
        exit 0
    }
}

Write-Host "[رياضة] تحذير: الخادم لم يبدأ بعد 45 ثانية — تحقق من نافذة PowerShell" -ForegroundColor Yellow
exit 0
