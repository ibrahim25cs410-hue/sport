#Requires -Version 5.1
# بناء وتشغيل تطبيق Windows — يعمل مع Visual Studio 2026/2022
param([switch]$BuildOnly)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "mobile"
$buildDir = Join-Path $mobile "build\windows\x64"
$exe = Join-Path $buildDir "runner\Debug\riyada.exe"

function Find-CMake {
    $paths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\18\Insiders\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $p } }
    return $null
}

function Get-Generator($cmake) {
    $gens = & $cmake --help 2>$null | Select-String "Visual Studio (\d+)"
    if (Test-Path "${env:ProgramFiles}\Microsoft Visual Studio\18") { return "Visual Studio 18 2026" }
    if (Test-Path "${env:ProgramFiles}\Microsoft Visual Studio\2022") { return "Visual Studio 17 2022" }
    return "Visual Studio 17 2022"
}

Write-Host "[رياضة] تجهيز التطبيق..." -ForegroundColor Green
Set-Location $mobile
flutter pub get | Out-Null

$cmake = Find-CMake
if (-not $cmake) {
    Write-Host "خطأ: CMake غير موجود. ثبّت Visual Studio مع C++ Desktop development." -ForegroundColor Red
    exit 1
}

$generator = Get-Generator $cmake
Write-Host "[رياضة] CMake: $generator" -ForegroundColor Cyan

# إعادة التهيئة إذا كان المولّد قديماً (Flutter يضبط VS 2019 أحياناً)
$cache = Join-Path $buildDir "CMakeCache.txt"
if (Test-Path $cache) {
    $content = Get-Content $cache -Raw
    if ($content -match "Visual Studio 16 2019") {
        Write-Host "[رياضة] إصلاح إعدادات البناء..." -ForegroundColor Yellow
        Remove-Item $cache -Force
        Remove-Item (Join-Path $buildDir "CMakeFiles") -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path $cache)) {
    Write-Host "[رياضة] تهيئة مشروع Windows..." -ForegroundColor Green
    & $cmake -S windows -B $buildDir -G $generator -A x64 -DFLUTTER_TARGET_PLATFORM=windows-x64
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "[رياضة] بناء التطبيق (قد يستغرق دقيقة)..." -ForegroundColor Green
& $cmake --build $buildDir --config Debug
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($BuildOnly) {
    Write-Host "[رياضة] تم البناء: $exe" -ForegroundColor Green
    exit 0
}

if (-not (Test-Path $exe)) {
    Write-Host "خطأ: لم يُعثر على $exe" -ForegroundColor Red
    exit 1
}

Write-Host "[رياضة] تشغيل التطبيق..." -ForegroundColor Green
Start-Process $exe
