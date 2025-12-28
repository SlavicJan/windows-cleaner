param(
  [string]$Version = "dev"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$dist = Join-Path $repoRoot "dist"
$toolkit = Join-Path $repoRoot "toolkit"

if (!(Test-Path $toolkit)) { throw "toolkit/ folder not found at $toolkit" }

New-Item -ItemType Directory -Force -Path $dist | Out-Null

$zipName = "WinMaintain_Portable_{0}.zip" -f $Version
$zipPath = Join-Path $dist $zipName

if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

# Create a clean temp staging folder
$tmp = Join-Path $env:TEMP ("winmaintain_stage_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

Copy-Item -Recurse -Force (Join-Path $toolkit "*") $tmp

# Ensure line endings are okay for BAT/PS1 (best-effort)
# (No conversion here; keep whatever repo has)

Compress-Archive -Path (Join-Path $tmp "*") -DestinationPath $zipPath -Force

Remove-Item -Recurse -Force $tmp

Write-Host "Built: $zipPath"
