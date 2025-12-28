#requires -Version 5.1
Write-Host "[3/5] App caches (browsers/JetBrains/etc)" -ForegroundColor Cyan

# Close browsers first for best result
$paths = @(
  "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Cache",
  "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Code Cache",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
  "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache",
  "$env:LOCALAPPDATA\SquirrelTemp",
  "$env:LOCALAPPDATA\CrashDumps"
)
foreach ($p in $paths) {
  try {
    if (Test-Path $p) {
      Write-Host "Removing: $p" -ForegroundColor DarkCyan
      Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue
    }
  } catch {}
}

# JetBrains (пример для IdeaIC2024.3 — можно поменять)
$jb = "$env:LOCALAPPDATA\JetBrains\IdeaIC2024.3"
foreach ($sub in @('caches','log')) {
  $p = Join-Path $jb $sub
  try { if (Test-Path $p) { Write-Host "Removing: $p" -ForegroundColor DarkCyan; Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue } } catch {}
}

# pip cache
try {
  if (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host "pip cache purge" -ForegroundColor DarkCyan
    pip cache purge | Out-Null
  }
} catch {}
