@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

:menu
cls
echo ============================================
echo            WinMaintain - START HERE
echo ============================================
echo.
echo  1) System info (sysinfo -> out\sysinfo_*.json)
echo  2) Audit only (no admin)
echo  3) Quick cleanup (admin)
echo  4) Full cleanup (admin)
echo  5) Backup browsers (close browsers first)
echo  6) Collect session ZIP (logs)
echo  0) Exit
echo.
set /p choice="Select: "

if "%choice%"=="1" call "10_sysinfo.bat" & goto menu
if "%choice%"=="2" call "run_audit_only.bat" & goto menu
if "%choice%"=="3" call "run_quick_cleanup_admin.bat" & goto menu
if "%choice%"=="4" call "run_full_cleanup_admin.bat" & goto menu
if "%choice%"=="5" call "run_browser_backup.bat" & goto menu
if "%choice%"=="6" call "run_collect_session_zip.bat" & goto menu
if "%choice%"=="0" exit /b 0

echo Invalid selection.
timeout /t 2 >nul
goto menu
