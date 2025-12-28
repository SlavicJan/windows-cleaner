param(
  [string]$LogDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs"),
  [switch]$NoUI
)

. (Join-Path $PSScriptRoot "lib\common.ps1")
Ensure-LogDir $LogDir
$transcript = Start-ToolkitTranscript -LogDir $LogDir -Prefix "cleanup_system"

Write-Section "10 - System cleanup"
Write-Host ("Free C: before (GB): {0}" -f (Get-FreeGB "C"))

Write-Host "Disabling hibernation (powercfg -h off)..."
try { powercfg -h off | Out-Null } catch { Write-Warning $_ }

Write-Host "Running DISM StartComponentCleanup..."
try { DISM /Online /Cleanup-Image /StartComponentCleanup } catch { Write-Warning $_ }

if (-not $NoUI) {
  Write-Host "Launching Disk Cleanup (cleanmgr). Use 'Clean up system files' inside the UI."
  try { Start-Process cleanmgr } catch { Write-Warning $_ }
} else {
  Write-Host "NoUI specified -> skipping cleanmgr UI."
}

Write-Host ("Free C: after (GB): {0}" -f (Get-FreeGB "C"))
Write-Host "Transcript saved to: $transcript"
Stop-ToolkitTranscript
