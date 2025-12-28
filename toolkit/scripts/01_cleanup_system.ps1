#requires -Version 5.1
# Safe system cleanup helpers (Windows 10/11)

Write-Host "[1/5] System cleanup helpers" -ForegroundColor Cyan

# Hibernation file (hiberfil.sys) can be huge. Disable if you don't use Hibernate.
try {
  Write-Host "Disabling hibernation (if enabled)..." -ForegroundColor DarkCyan
  powercfg -h off | Out-Null
} catch {}

# Component store cleanup
try {
  Write-Host "Running DISM Component Cleanup..." -ForegroundColor DarkCyan
  DISM.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Null
} catch {}

# Optional: open Disk Cleanup GUI
Write-Host "If you want, run Disk Cleanup GUI: cleanmgr" -ForegroundColor Yellow
