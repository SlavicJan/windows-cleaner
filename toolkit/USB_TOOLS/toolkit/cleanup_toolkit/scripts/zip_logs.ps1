﻿param(
  [string]$LogRoot,
  [string]$OutFile
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolRoot = Resolve-Path (Join-Path $here "..") | Select-Object -ExpandProperty Path

if (-not $LogRoot -or $LogRoot.Trim().Length -eq 0) {
  $LogRoot = Join-Path $toolRoot "logs"
}

$day = Get-Date -Format "yyyy-MM-dd"
$logDir = Join-Path $LogRoot $day

# If today's folder doesn't exist yet, fall back to the most recent log folder.
if (-not (Test-Path $logDir)) {
  $cand = Get-ChildItem -Path $LogRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' } |
    Sort-Object -Property Name -Descending |
    Select-Object -First 1

  if ($cand) {
    Write-Host "No log directory for today: $logDir"
    $logDir = $cand.FullName
    Write-Host "Using most recent log directory: $logDir"
  } else {
    Write-Host "No log directories found under: $LogRoot"
    Write-Host "Run Audit/Quick/Full first, then try zipping logs again."
    exit 1
  }
}

if (-not $OutFile -or $OutFile.Trim().Length -eq 0) {
  $OutFile = Join-Path $toolRoot ("logs_{0}_{1}.zip" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))
}

Write-Host "Zipping logs from: $logDir"
Write-Host "Into: $OutFile"

if (Test-Path $OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }
Compress-Archive -Path (Join-Path $logDir "*") -DestinationPath $OutFile -Force

Write-Host "Done."
Start-Process explorer.exe (Split-Path -Parent $OutFile) | Out-Null
