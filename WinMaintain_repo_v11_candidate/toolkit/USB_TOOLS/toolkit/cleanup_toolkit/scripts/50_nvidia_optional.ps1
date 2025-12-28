param(
  [string]$LogDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs"),
  [ValidateSet("none","remove_caches","rename_updateframework")]
  [string]$Mode = "remove_caches"
)

. (Join-Path $PSScriptRoot "lib\common.ps1")
Ensure-LogDir $LogDir
$transcript = Start-ToolkitTranscript -LogDir $LogDir -Prefix "nvidia_optional"

Write-Section "50 - NVIDIA optional cleanup"
Write-Host ("Mode: {0}" -f $Mode)
Write-Host ("Free C: before (GB): {0}" -f (Get-FreeGB "C"))
Write-Host "If you do not use NVIDIA App features, uninstalling NVIDIA App via Settings->Apps is the cleanest option."

if ($Mode -eq "remove_caches") {
  Write-Host "Removing common NVIDIA caches (safe, may repopulate):"
  Safe-RemoveChildren "C:\ProgramData\NVIDIA Corporation\Downloader"
  Safe-RemoveChildren "C:\ProgramData\NVIDIA Corporation\NV_Cache"
  Safe-Remove "C:\NVIDIA"
}

if ($Mode -eq "rename_updateframework") {
  if (-not (Test-Admin)) { Write-Warning "Admin recommended for stopping services." }
  $src = "C:\ProgramData\NVIDIA Corporation\NVIDIA app\UpdateFramework"
  $bak = "C:\ProgramData\NVIDIA Corporation\NVIDIA app\UpdateFramework.bak"
  if (-not (Test-Path $src)) {
    Write-Host "Not found: $src"
  } elseif (Test-Path $bak) {
    Write-Warning "Backup already exists: $bak (delete/rename it first if you want to proceed)"
  } else {
    Write-Host "Stopping NVIDIA processes/services (best-effort)..."
    try { Stop-Process -Name "NVIDIA*" -Force -ErrorAction SilentlyContinue } catch { }
    try { Stop-Service -Name "NVDisplay.ContainerLocalSystem" -Force -ErrorAction SilentlyContinue } catch { }

    Write-Host "Renaming UpdateFramework -> UpdateFramework.bak (rollback by renaming back)."
    try { Rename-Item $src (Split-Path $bak -Leaf) -ErrorAction Stop } catch { Write-Warning $_ }
    Write-Host "Reboot recommended."
  }
}

Write-Host ("Free C: after (GB): {0}" -f (Get-FreeGB "C"))
Write-Host "Transcript saved to: $transcript"
Stop-ToolkitTranscript
