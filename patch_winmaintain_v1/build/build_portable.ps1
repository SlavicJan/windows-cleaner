param(
  [string]$Version = $env:GITHUB_REF_NAME
)

# Build a portable ZIP where toolkit contents are at the ZIP root
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $repo "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

if (-not $Version -or $Version.Trim() -eq "") {
  $Version = (Get-Date -Format "yyyyMMdd_HHmm")
}

$zip = Join-Path $dist ("WinMaintain_Portable_{0}.zip" -f $Version)

# NOTE: zip CONTENTS of toolkit, not the folder itself
$toolkitGlob = Join-Path $repo "toolkit\*"

if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path $toolkitGlob -DestinationPath $zip -Force

Write-Host ("Built: {0}" -f $zip)
