@echo off
setlocal
set "HERE=%~dp0"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
echo Running PowerShell toolkit AUDIT (no cleanup).
echo Logs go into ps_toolkit\logs\YYYY-MM-DD
echo.
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%HERE%ps_toolkit\scripts\run_toolkit.ps1" -Mode AuditOnly -OpenLogs
echo.
pause
