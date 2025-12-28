@echo off
setlocal EnableExtensions
set ROOT=%~dp0
set TOOL=%ROOT%toolkit\cleanup_toolkit
set SCRIPTS=%TOOL%\scripts
chcp 65001 >nul 2>nul
title WinMaintain USB Pack v1.1 (no Python)

:menu
cls
echo ==========================================================
echo  WinMaintain USB Pack v1.1 - portable (NO Python)
echo ==========================================================
echo.
echo Root: %ROOT%
echo Logs: %TOOL%\logs\YYYY-MM-DD
echo.
echo  1) Audit only (no admin)
echo  2) Quick clean (admin)
echo  3) Full clean (admin)
echo  4) Zip logs (today OR latest)  ^(creates ZIP next to toolkit^)
echo  5) Windows 11 readiness check (best-effort)
echo  6) Open logs folder (today OR latest)
echo  7) Open exports folder (win11 readiness output)
echo  0) Exit
echo.
set /p CH=Choose: 

if "%CH%"=="1" goto audit
if "%CH%"=="2" goto quick
if "%CH%"=="3" goto full
if "%CH%"=="4" goto ziplogs
if "%CH%"=="5" goto readiness
if "%CH%"=="6" goto openlogs
if "%CH%"=="7" goto openexports
if "%CH%"=="0" goto end
goto menu

:audit
call "%SCRIPTS%\run_audit_only.bat"
pause
goto menu

:quick
call "%SCRIPTS%\run_quick_as_admin.bat"
pause
goto menu

:full
call "%SCRIPTS%\run_full_as_admin.bat"
pause
goto menu

:ziplogs
call "%SCRIPTS%\zip_today_logs.bat"
pause
goto menu

:readiness
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%check_win11_readiness.ps1"
pause
goto menu

:openlogs
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$root='%TOOL%\logs';" ^
  "$today=Join-Path $root (Get-Date -Format 'yyyy-MM-dd');" ^
  "if(Test-Path $today){Start-Process explorer.exe $today; exit};" ^
  "$d=Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ?{ $_.Name -match '^\d{4}-\d{2}-\d{2}$' } | sort Name -Descending | select -First 1;" ^
  "if($d){Start-Process explorer.exe $d.FullName}else{Start-Process explorer.exe $root}"
pause
goto menu

:openexports
if exist "%ROOT%exports" (start "" explorer "%ROOT%exports") else (echo No exports folder yet. Run option 5 first.& pause)
goto menu

:end
endlocal
exit /b
