#requires -Version 5.1
Write-Host "[5/5] NVIDIA app UpdateFramework cache (safe rename)" -ForegroundColor Cyan

$path = "C:\ProgramData\NVIDIA Corporation\NVIDIA app\UpdateFramework"
if (-not (Test-Path $path)) {
  Write-Host "Not found: $path" -ForegroundColor Yellow
  exit 0
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$bak = "$path.bak_$stamp"

Write-Host "Renaming:`n  $path`n  -> $bak" -ForegroundColor DarkCyan
try {
  Rename-Item -Force -Path $path -NewName (Split-Path $bak -Leaf)
  Write-Host "OK. If NVIDIA app needs it, it will recreate the folder." -ForegroundColor Green
} catch {
  Write-Warning $_
  Write-Host "If rename fails, close NVIDIA app and try running as Administrator." -ForegroundColor Yellow
}
