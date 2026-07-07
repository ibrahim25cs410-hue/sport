# تشغيل الخادم من مجلد mobile
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $root "scripts\run-api.ps1")
