#requires -Version 5.1

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Running all scripts from: $here" -ForegroundColor Cyan

. "$here\04_audit_sizes.ps1"
. "$here\01_cleanup_system.ps1"
. "$here\02_cleanup_updates_temp.ps1"
. "$here\03_cleanup_apps_caches.ps1"
. "$here\05_nvidia_updateframework_safe_rename.ps1"

Write-Host "All done." -ForegroundColor Green
