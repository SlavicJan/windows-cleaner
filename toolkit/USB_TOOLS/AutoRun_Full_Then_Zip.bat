@echo off
setlocal EnableExtensions
set ROOT=%~dp0
set TOOL=%ROOT%toolkit\cleanup_toolkit
set SCRIPTS=%TOOL%\scripts

:: Self-elevate for admin
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Requesting admin rights...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo Running FULL clean then zipping logs...
call "%SCRIPTS%\run_full_as_admin.bat"
call "%SCRIPTS%\zip_today_logs.bat"
echo Done.
pause
