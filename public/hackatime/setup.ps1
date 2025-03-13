# Create config file
New-Item -Path $env:USERPROFILE\.wakatime.cfg -Force
Set-Content -Path $env:USERPROFILE\.wakatime.cfg -Value @"
[settings]
api_url = https://hackatime.hackclub.com/api/hackatime/v1
api_key = $env:HACKATIME_API_KEY
"@

Write-Host "Config file created at $env:USERPROFILE\.wakatime.cfg"

# Read values from config to verify
if (-not (Test-Path $env:USERPROFILE\.wakatime.cfg)) {
  Write-Error "Config file not found"
  exit 1
}

$config = Get-Content $env:USERPROFILE\.wakatime.cfg
$apiUrl = $config | Select-String "api_url" | ForEach-Object { $_.ToString().Split('"')[1] }
$apiKey = $config | Select-String "api_key" | ForEach-Object { $_.ToString().Split('"')[1] }

if (-not $apiUrl -or -not $apiKey) {
  Write-Error "Could not read api_url or api_key from config"
  exit 1
}

Write-Host "Successfully read config:"
Write-Host "API URL: $apiUrl"
Write-Host "API Key: $($apiKey.Substring(0,8)..." # Show only first 8 chars for security

# Send test heartbeat using values from config
Write-Host "Sending test heartbeat..."
$time = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat '%s'))
$heartbeat = @{
  type = 'file'
  time = $time
  entity = 'test.txt'
  language = 'Text'
}
$body = "[$($heartbeat | ConvertTo-Json)]"

try {
  $response = Invoke-WebRequest -Uri "$apiUrl/users/current/heartbeats" `
    -Method Post `
    -Headers @{Authorization="Bearer $apiKey"} `
    -ContentType 'application/json' `
    -Body $body

  Write-Host "Test heartbeat sent successfully"
} catch {
  Write-Error "Error sending heartbeat: $($_.Exception.Response.StatusCode.Value__) $($_.Exception.Message)"
  exit 1
} 