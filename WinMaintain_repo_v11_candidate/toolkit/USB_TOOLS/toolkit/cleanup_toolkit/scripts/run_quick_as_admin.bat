@echo off
setlocal EnableExtensions
set DIR=%~dp0

:: Self-elevate for admin
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Requesting admin rights...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo Running Quick...
echo Toolkit: %DIR%..
echo Logs (today): %DIR%..\logs
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%run_toolkit.ps1" -Mode Quick -OpenLogs
echo.
echo Done. Press any key.
pause >nul
