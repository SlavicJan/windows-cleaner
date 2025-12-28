param(
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

if (-not (Test-Path $logDir)) {
  Write-Host "No log directory for today: $logDir"
  exit 1
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
