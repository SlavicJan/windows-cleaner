$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$toolkit = Join-Path $root "toolkit"
$dist = Join-Path $root "dist"
if (!(Test-Path $dist)) { New-Item -ItemType Directory $dist | Out-Null }

# Create payload.zip from toolkit folder
$payload = Join-Path $dist "payload.zip"
if (Test-Path $payload) { Remove-Item $payload -Force }

Compress-Archive -Path (Join-Path $toolkit "*") -DestinationPath $payload -Force
Write-Host "payload.zip -> $payload"
