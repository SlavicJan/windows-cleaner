@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

rem ---- helpers ----
:check_admin
net session >nul 2>&1
if %errorlevel%==0 (set IS_ADMIN=1) else (set IS_ADMIN=0)
exit /b 0

:elevate_and_run
rem Usage: call :elevate_and_run "relative\script.bat"
set TARGET=%~1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%COMSPEC%' -ArgumentList '/c cd /d \"\"%~dp0\"\" ^&^& \"%TARGET%\"' -Verb RunAs"
exit /b 0

rem ---- start ----
call :check_admin

echo.
echo ==========================================
echo   WinMaintain Portable - START HERE
echo ==========================================
echo Folder: %CD%
echo Admin : %IS_ADMIN%
echo.

echo Tip: close browsers before cache cleanup / browser backup (WinError 32).
echo.

:menu
echo Choose action:
echo   1) Scan (top folders/files)
echo   2) Cleanup DRY-RUN (safe preview)
echo   3) Cleanup FULL (needs Admin)
echo   4) Backup browsers (needs browsers closed)
echo   5) Collect session ZIP (logs + history)
echo   6) System info (JSON)
echo   0) Exit
echo.

set /p CHOICE=Enter number: 

if "%CHOICE%"=="1" call "01_scan.bat" & goto menu
if "%CHOICE%"=="2" call "02_cleanup_dryrun.bat" & goto menu
if "%CHOICE%"=="3" (
  call :check_admin
  if "%IS_ADMIN%"=="1" (
    call "03_cleanup_execute.bat"
  ) else (
    echo [!] Need Admin. UAC prompt will appear...
    call :elevate_and_run "03_cleanup_execute.bat"
  )
  goto menu
)
if "%CHOICE%"=="4" call "06_backup_browsers.bat" & goto menu
if "%CHOICE%"=="5" call "07_collect_session_zip.bat" & goto menu
if "%CHOICE%"=="6" call "10_sysinfo.bat" & goto menu
if "%CHOICE%"=="0" exit /b 0

echo.
echo [!] Unknown option: %CHOICE%
echo.
goto menu
