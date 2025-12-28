#requires -Version 5.1
Write-Host "[2/5] Windows Update cache + Temp" -ForegroundColor Cyan

function Test-Admin {
  $id=[Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) { Write-Warning "Run PowerShell as Administrator for full effect." }

# Windows Update download cache
$sd = "$env:SystemRoot\SoftwareDistribution\Download"
try {
  Write-Host "Stopping services (wuauserv, bits)..." -ForegroundColor DarkCyan
  Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
  Stop-Service bits -Force -ErrorAction SilentlyContinue
} catch {}
try {
  if (Test-Path $sd) {
    Write-Host "Deleting: $sd" -ForegroundColor DarkCyan
    Remove-Item -Recurse -Force "$sd\*" -ErrorAction SilentlyContinue
  }
} catch {}
try {
  Write-Host "Starting services..." -ForegroundColor DarkCyan
  Start-Service bits -ErrorAction SilentlyContinue
  Start-Service wuauserv -ErrorAction SilentlyContinue
} catch {}

# Temp folders
$temps = @($env:TEMP, "$env:SystemRoot\Temp")
foreach ($t in $temps) {
  try {
    if (Test-Path $t) {
      Write-Host "Clearing: $t" -ForegroundColor DarkCyan
      Remove-Item -Recurse -Force "$t\*" -ErrorAction SilentlyContinue
    }
  } catch {}
}

# Recycle bin
try {
  Write-Host "Emptying recycle bin..." -ForegroundColor DarkCyan
  Clear-RecycleBin -Force -ErrorAction SilentlyContinue
} catch {}
