@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

echo ==========================================================
echo Windows Maintenance Pack - Launcher (v7)
echo ==========================================================
echo.
echo  [1] Python - Scan disk/system (reports to RUN\reports)
echo  [2] Python - Cleanup (DRY-RUN, no deletions)
echo  [3] Python - Cleanup (EXECUTE, will delete caches/temp)
echo  [4] Python - Backup browsers (kills browser procs, best-effort)
echo  [5] PowerShell - Audit only (safe)
echo  [6] PowerShell - Quick cleanup (safe-ish)
echo  [7] PowerShell - Full cleanup (admin)
echo  [8] Collect session zip (logs + reports + PS history)
echo  [9] Open today's logs
echo  [0] Exit
echo.
set /p CH=Choose: 

if "%CH%"=="1" call "RUN\01_scan.bat" & goto :eof
if "%CH%"=="2" call "RUN\02_cleanup_dryrun.bat" & goto :eof
if "%CH%"=="3" call "RUN\03_cleanup_execute.bat" & goto :eof
if "%CH%"=="4" call "RUN\06_backup_browsers.bat" & goto :eof
if "%CH%"=="5" call "RUN\ps_toolkit\scripts\run_audit_only.bat" & goto :eof
if "%CH%"=="6" call "RUN\ps_toolkit\scripts\run_quick_as_admin.bat" & goto :eof
if "%CH%"=="7" call "RUN\ps_toolkit\scripts\run_full_as_admin.bat" & goto :eof
if "%CH%"=="8" call "RUN\07_collect_session_zip.bat" & goto :eof
if "%CH%"=="9" call "RUN\ps_toolkit\scripts\zip_today_logs.bat" & goto :eof
if "%CH%"=="0" exit /b 0

echo Invalid choice.
pause
