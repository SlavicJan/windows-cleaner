param(
  [string]$LogDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs")
)

. (Join-Path $PSScriptRoot "lib\common.ps1")
Ensure-LogDir $LogDir
$transcript = Start-ToolkitTranscript -LogDir $LogDir -Prefix "cleanup_updates_temp"

Write-Section "20 - Windows Update downloads + Recycle Bin + TEMP"
Write-Host ("Free C: before (GB): {0}" -f (Get-FreeGB "C"))

Write-Host "Stopping wuauserv + bits..."
Stop-ServiceSafe "wuauserv"
Stop-ServiceSafe "bits"

$dl = Join-Path $env:windir "SoftwareDistribution\Download"
Write-Host "Clearing: $dl\*"
Safe-RemoveChildren $dl

Write-Host "Starting bits + wuauserv..."
Start-ServiceSafe "bits"
Start-ServiceSafe "wuauserv"

Write-Host "Clearing Recycle Bin..."
try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch { }

Write-Host "Clearing TEMP..."
try {
  Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
} catch { }

Write-Host ("Free C: after (GB): {0}" -f (Get-FreeGB "C"))
Write-Host "Transcript saved to: $transcript"
Stop-ToolkitTranscript
