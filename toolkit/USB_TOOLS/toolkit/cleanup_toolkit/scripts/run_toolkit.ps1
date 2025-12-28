param(
  [ValidateSet("AuditOnly","Quick","Full")]
  [string]$Mode = "Full",
  [switch]$NoUI,
  [ValidateSet("none","remove_caches","rename_updateframework")]
  [string]$NvidiaMode = "remove_caches",
  [string]$LogRoot,
  [switch]$OpenLogs
)

# Toolkit root = parent of scripts folder
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolRoot = Resolve-Path (Join-Path $here "..") | Select-Object -ExpandProperty Path

if (-not $LogRoot -or $LogRoot.Trim().Length -eq 0) {
  $LogRoot = Join-Path $toolRoot "logs"
}

# Date-based folder to keep logs tidy
$day = Get-Date -Format "yyyy-MM-dd"
$logDir = Join-Path $LogRoot $day
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

Write-Host ""
Write-Host "Windows Cleanup Toolkit"
Write-Host ("Mode: {0} | NoUI: {1} | NvidiaMode: {2}" -f $Mode, $NoUI.IsPresent, $NvidiaMode)
Write-Host ("Toolkit -> {0}" -f $toolRoot)
Write-Host ("Logs -> {0}" -f $logDir)
Write-Host ""

function Open-LogsFolder {
  param([string]$PathToOpen)
  try {
    if (Test-Path $PathToOpen) {
      Start-Process explorer.exe $PathToOpen | Out-Null
    }
  } catch {}
}

# Direct invocation keeps SwitchParameters correct (no 'False' strings)
& (Join-Path $here "00_audit.ps1") -LogDir $logDir

if ($Mode -eq "AuditOnly") {
  if ($OpenLogs) { Open-LogsFolder -PathToOpen $logDir }
  exit 0
}

if ($Mode -eq "Quick") {
  & (Join-Path $here "20_cleanup_updates_temp.ps1") -LogDir $logDir
  & (Join-Path $here "30_cleanup_browsers.ps1") -LogDir $logDir
  & (Join-Path $here "40_cleanup_dev_caches.ps1") -LogDir $logDir
  & (Join-Path $here "50_nvidia_optional.ps1") -LogDir $logDir -Mode $NvidiaMode
  & (Join-Path $here "00_audit.ps1") -LogDir $logDir
  if ($OpenLogs) { Open-LogsFolder -PathToOpen $logDir }
  exit 0
}

if ($Mode -eq "Full") {
  if ($NoUI) {
    & (Join-Path $here "10_cleanup_system.ps1") -LogDir $logDir -NoUI
  } else {
    & (Join-Path $here "10_cleanup_system.ps1") -LogDir $logDir
  }
  & (Join-Path $here "20_cleanup_updates_temp.ps1") -LogDir $logDir
  & (Join-Path $here "30_cleanup_browsers.ps1") -LogDir $logDir
  & (Join-Path $here "40_cleanup_dev_caches.ps1") -LogDir $logDir
  & (Join-Path $here "50_nvidia_optional.ps1") -LogDir $logDir -Mode $NvidiaMode
  & (Join-Path $here "00_audit.ps1") -LogDir $logDir
  if ($OpenLogs) { Open-LogsFolder -PathToOpen $logDir }
}
