param(
  [string]$LogDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs")
)

. (Join-Path $PSScriptRoot "lib\common.ps1")
Ensure-LogDir $LogDir
$transcript = Start-ToolkitTranscript -LogDir $LogDir -Prefix "cleanup_dev_caches"

Write-Section "40 - Dev / tooling caches (best-effort)"
Write-Host ("Free C: before (GB): {0}" -f (Get-FreeGB "C"))

Write-Host "Cleaning SquirrelTemp + CrashDumps..."
Safe-RemoveChildren "$env:LOCALAPPDATA\SquirrelTemp"
Safe-RemoveChildren "$env:LOCALAPPDATA\CrashDumps"

Write-Host "Purging pip cache (if Python available)..."
try { python -m pip cache purge | Out-Host } catch { Write-Host "pip cache purge skipped." }

Write-Host "Cleaning npm cache (if npm exists)..."
try { npm cache clean --force | Out-Host } catch { Write-Host "npm cache clean skipped." }

Write-Host "Cleaning Cargo caches (if present)..."
Safe-RemoveChildren "$env:USERPROFILE\.cargo\registry"
Safe-RemoveChildren "$env:USERPROFILE\.cargo\git"

Write-Host ("Free C: after (GB): {0}" -f (Get-FreeGB "C"))
Write-Host "Transcript saved to: $transcript"
Stop-ToolkitTranscript
