# Create config file
$configPath = "$env:USERPROFILE\.wakatime.cfg"
New-Item -Path $configPath -Force | Out-Null
Set-Content -Path $configPath -Value @"
[settings]
api_url = https://hackatime.hackclub.com/api/hackatime/v1
api_key = $env:HACKATIME_API_KEY
"@

Write-Host "Config file created at $configPath"

# Verify config file exists
if (-not (Test-Path $configPath)) {
  Write-Error "Config file not found"
  exit 1
}

$config = Get-Content $configPath | Where-Object {$_ -match '='} | ForEach-Object {
  $key, $value = $_ -split '=', 2
  [PSCustomObject]@{
    Key = $key.Trim()
    Value = $value.Trim()
  }
}

$apiUrl = ($config | Where-Object Key -eq 'api_url').Value
$apiKey = ($config | Where-Object Key -eq 'api_key').Value

if ([string]::IsNullOrEmpty($apiUrl) -or [string]::IsNullOrEmpty($apiKey)) {
  Write-Error "Could not read api_url or api_key from config"
  exit 1
}

Write-Host "Successfully read config:"
Write-Host "API URL: $apiUrl"
Write-Host "API Key: $($apiKey.Substring(0,8))..."

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
  $statusCode = $_.Exception.Response.StatusCode.Value__
  Write-Error "Error sending heartbeat: $statusCode - $($_.Exception.Message)"
  exit 1
}

Read-Host -Prompt "Press Enter to exit..."
