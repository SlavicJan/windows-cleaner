@echo off
setlocal
set DIR=%~dp0
echo Zipping today's logs...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%zip_logs.ps1"
echo Done. Press any key.
pause >nul
