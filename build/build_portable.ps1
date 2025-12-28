$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root "dist"
if (!(Test-Path $dist)) { New-Item -ItemType Directory $dist | Out-Null }

$tag = $env:GITHUB_REF_NAME
if (-not $tag) { $tag = "dev" }

$zip = Join-Path $dist ("WinMaintain_portable_{0}.zip" -f $tag)
if (Test-Path $zip) { Remove-Item $zip -Force }

$src = Join-Path $root "toolkit"
Compress-Archive -Path (Join-Path $src "*") -DestinationPath $zip -Force
Write-Host "portable zip -> $zip"
