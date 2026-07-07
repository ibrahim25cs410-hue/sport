# إنشاء مفتاح توقيع Android للنشر على Google Play
# شغّل مرة واحدة فقط — احفظ كلمات المرور في مكان آمن!

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$jks = "android\riyada-release.jks"
$keyProps = "android\key.properties"

if (Test-Path $jks) {
    Write-Host "Keystore موجود: $jks"
    exit 0
}

Write-Host "إنشاء keystore جديد..."
$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Error "keytool غير موجود. ثبّت JDK (Java) وأضفه إلى PATH."
}

$keytoolPath = $keytool.Source
& $keytoolPath -genkey -v `
    -keystore $jks `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -alias riyada `
    -storepass riyada_store_CHANGE_ME `
    -keypass riyada_key_CHANGE_ME `
    -dname "CN=Riyada, OU=Mobile, O=Riyada, L=Mosul, ST=Nineveh, C=IQ"

Copy-Item android\key.properties.example android\key.properties -Force
(Get-Content android\key.properties) `
    -replace 'CHANGE_ME', 'riyada_store_CHANGE_ME' `
    -replace 'keyPassword=riyada_store_CHANGE_ME', 'keyPassword=riyada_key_CHANGE_ME' |
    Set-Content android\key.properties

Write-Host ""
Write-Host "تم! عدّل android\key.properties بكلمات مرور قوية."
Write-Host "احفظ android\riyada-release.jks — بدونه لا يمكن تحديث التطبيق على Play Store."
