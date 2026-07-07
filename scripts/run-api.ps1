#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$apiDir = Join-Path $root "SportsApp\Api"
$port = 61082
$healthUrl = "http://localhost:$port/api/health"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "خطأ: .NET SDK غير مثبت!" -ForegroundColor Red
    Write-Host "حمّل .NET 8 SDK من: https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Yellow
    Write-Host "(اختر SDK وليس Runtime فقط)" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "اضغط Enter للإغلاق"
    exit 1
}

$sdks = & dotnet --list-sdks 2>$null
if (-not $sdks) {
    Write-Host ""
    Write-Host "خطأ: dotnet موجود لكن SDK غير مثبت!" -ForegroundColor Red
    Write-Host "حمّل .NET 8 SDK من: https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "اضغط Enter للإغلاق"
    exit 1
}

function Test-ApiHealthy {
    try {
        $r = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 3
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Stop-ApiOnPort {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $conn) { return $false }
    $pid = $conn.OwningProcess
    $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "إيقاف عملية الخادم السابقة ($($proc.ProcessName) #$pid)..." -ForegroundColor Yellow
        Stop-Process -Id $pid -Force
        Start-Sleep -Seconds 2
        return $true
    }
    return $false
}

if (Test-ApiHealthy) {
    Write-Host "الخادم يعمل بالفعل على http://localhost:$port" -ForegroundColor Green
    Write-Host "Swagger: http://localhost:$port/swagger" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "لإعادة التشغيل: أوقف العملية الحالية ثم شغّل السكربت مجدداً." -ForegroundColor Yellow
    exit 0
}

if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
    Write-Host "المنفذ $port مشغول بعملية غير صحية — جاري إيقافها..." -ForegroundColor Yellow
    Stop-ApiOnPort | Out-Null
}

Set-Location $apiDir

$lanIp = $null
try {
    $lanIp = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
        Select-Object -First 1 -ExpandProperty IPAddress
} catch { }

Write-Host "تشغيل الخادم على http://localhost:$port ..." -ForegroundColor Green
Write-Host "Swagger: http://localhost:$port/swagger" -ForegroundColor Cyan
if ($lanIp) {
    Write-Host ""
    Write-Host "للهاتف على نفس شبكة الواي فاي:" -ForegroundColor Yellow
    Write-Host "  http://${lanIp}:$port/api" -ForegroundColor Yellow
    Write-Host "  ضع في إعدادات التطبيق: ${lanIp}:$port" -ForegroundColor Yellow
    Write-Host ""
}

dotnet run --urls "http://0.0.0.0:$port"
