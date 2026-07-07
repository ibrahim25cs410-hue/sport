# Allow inbound TCP to the Riyada API on your laptop.
# Run as Administrator:  Right-click PowerShell -> Run as administrator
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\allow-firewall.ps1

param(
    [int]$Port = 61082,
    [string]$RuleName = "Riyada API (local team)"
)

$existing = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Firewall rule already exists: $RuleName"
} else {
    New-NetFirewallRule `
        -DisplayName $RuleName `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort $Port `
        -Profile Private, Domain `
        | Out-Null
    Write-Host "Created inbound rule for TCP port $Port (Private + Domain profiles)."
}

Write-Host ""
Write-Host "Your LAN IPv4 addresses:"
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
    ForEach-Object { Write-Host "  http://$($_.IPAddress):$Port/api" }

Write-Host ""
Write-Host "Teammates on the same Wi-Fi can use one of the URLs above in the Flutter app."
Write-Host "For home access, use Tailscale or ngrok (see LOCAL_SERVER_GUIDE.md)."
