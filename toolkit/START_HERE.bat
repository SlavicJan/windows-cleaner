@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

rem where outputs live (repo-root/out + repo-root/logs)
if not exist "..\out"  mkdir "..\out"
if not exist "..\logs" mkdir "..\logs"

set "OUT=..\out"
set "LOGS=..\logs"

:menu
cls
echo ============================================
echo            WinMaintain - START HERE
echo ============================================
echo.
echo  1) System info (read-only)
echo  2) Audit only  (read-only)
echo  3) Quick cleanup (admin)
echo  4) Full cleanup  (admin)
echo  5) Backup browsers (close browsers first)
echo  6) Collect session ZIP (logs)
echo  7) Open OUT folder
echo  8) Open LOGS folder
echo  0) Exit
echo.

set /p CH=Select: 

if "%CH%"=="1" goto do_sysinfo
if "%CH%"=="2" goto do_audit
if "%CH%"=="3" goto do_quick
if "%CH%"=="4" goto do_full
if "%CH%"=="5" goto do_backup
if "%CH%"=="6" goto do_zip
if "%CH%"=="7" goto do_open_out
if "%CH%"=="8" goto do_open_logs
if "%CH%"=="0" goto done

echo.
echo Wrong choice: %CH%
timeout /t 2 >nul
goto menu

:do_sysinfo
call "10_sysinfo.bat"
start "" explorer "%OUT%"
pause
goto menu

:do_audit
call "08_ps_audit_only.bat"
start "" explorer "%LOGS%"
pause
goto menu

:do_quick
call "ps_toolkit\02_quick_cleanup_admin.bat"
start "" explorer "%LOGS%"
pause
goto menu

:do_full
call "ps_toolkit\03_full_cleanup_admin.bat"
start "" explorer "%LOGS%"
pause
goto menu

:do_backup
call "06_backup_browsers.bat"
start "" explorer "%OUT%"
pause
goto menu

:do_zip
call "07_collect_session_zip.bat"
start "" explorer "%OUT%"
pause
goto menu

:do_open_out
start "" explorer "%OUT%"
goto menu

:do_open_logs
start "" explorer "%LOGS%"
goto menu

:done
endlocal
exit /b 0
