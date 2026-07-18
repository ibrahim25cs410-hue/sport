param(
    [switch]$RequireFirebase,
    [switch]$RequireSigning,
    [string]$DartDefineFile
)

$ErrorActionPreference = "Stop"
$mobile = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Require-Match([string]$Path, [string]$Pattern, [string]$Message) {
    if (-not (Select-String -Path $Path -Pattern $Pattern -Quiet)) {
        $failures.Add($Message)
    }
}

function Forbid-Match([string]$Path, [string]$Pattern, [string]$Message) {
    if (Select-String -Path $Path -Pattern $Pattern -Quiet) {
        $failures.Add($Message)
    }
}

$mainManifest = Join-Path $mobile "android/app/src/main/AndroidManifest.xml"
$debugManifest = Join-Path $mobile "android/app/src/debug/AndroidManifest.xml"
$paymentPolicy = Join-Path $mobile "lib/config/payment_policy.dart"
$tokenStorage = Join-Path $mobile "lib/services/token_storage.dart"
$gradle = Join-Path $mobile "android/app/build.gradle.kts"

Require-Match $mainManifest 'usesCleartextTraffic="false"' "Release manifest must disable cleartext traffic."
Forbid-Match $mainManifest 'networkSecurityConfig' "Release manifest must not reference debug network security config."
Require-Match $debugManifest 'networkSecurityConfig' "Debug manifest must own the cleartext exception."
Require-Match $paymentPolicy 'defaultValue:\s*false' "Electronic payments must default to disabled."
Forbid-Match $tokenStorage 'setString\(_fallbackKey' "JWT plaintext fallback writes are forbidden."
Forbid-Match $gradle 'signingConfigs\.getByName\("debug"\)' "Release must never fall back to debug signing."

if ($RequireSigning -and -not (Test-Path (Join-Path $mobile "android/key.properties"))) {
    $failures.Add("android/key.properties is required for a signed release.")
}

if ($RequireFirebase) {
    if ([string]::IsNullOrWhiteSpace($DartDefineFile) -or -not (Test-Path $DartDefineFile)) {
        $failures.Add("Provide -DartDefineFile pointing to the production --dart-define-from-file JSON.")
    } else {
        $defines = Get-Content $DartDefineFile -Raw | ConvertFrom-Json
        $requiredFirebaseKeys = @(
            "FIREBASE_SENDER_ID",
            "FIREBASE_PROJECT_ID",
            "FIREBASE_STORAGE_BUCKET",
            "FIREBASE_ANDROID_API_KEY",
            "FIREBASE_ANDROID_APP_ID",
            "FIREBASE_IOS_API_KEY",
            "FIREBASE_IOS_APP_ID"
        )
        foreach ($key in $requiredFirebaseKeys) {
            $value = $defines.$key
            if ([string]::IsNullOrWhiteSpace($value) -or $value.StartsWith("YOUR_")) {
                $failures.Add("Firebase production define '$key' is missing or a placeholder.")
            }
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Release configuration checks passed."
