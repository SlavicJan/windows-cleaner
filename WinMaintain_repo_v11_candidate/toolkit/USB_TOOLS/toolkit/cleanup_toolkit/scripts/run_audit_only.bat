@echo off
setlocal EnableExtensions
set DIR=%~dp0

echo Running AuditOnly...
echo Toolkit: %DIR%..
echo Logs (today): %DIR%..\logs
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%run_toolkit.ps1" -Mode AuditOnly -OpenLogs
echo.
echo Done. Press any key.
pause >nul
