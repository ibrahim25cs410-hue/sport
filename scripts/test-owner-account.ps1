$login = Invoke-RestMethod -Uri 'http://localhost:61082/api/login' -Method Post -ContentType 'application/json' -Body (Get-Content 'd:\sport\tmp_login.json' -Raw)
$uri = "http://localhost:61082/api/payments/owner/$($login.user.id)/account"
try {
    $acc = Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Bearer $($login.token)" }
    $acc | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
}
