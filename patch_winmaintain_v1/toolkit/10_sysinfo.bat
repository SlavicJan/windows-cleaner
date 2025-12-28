@echo off
setlocal
cd /d "%~dp0"

if not exist out mkdir out

echo == Collecting system info to out\sysinfo.json ==
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\sysinfo.ps1" > "out\sysinfo.json"

if %errorlevel% neq 0 (
  echo [ERROR] sysinfo failed. Try running as Administrator.
  pause
  exit /b 1
)

echo [OK] Saved: out\sysinfo.json
pause
