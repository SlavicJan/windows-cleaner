@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

if not exist "scripts\sysinfo.ps1" (
  echo [ERROR] scripts\sysinfo.ps1 not found.
  pause
  exit /b 1
)

if not exist "..\out" mkdir "..\out" >nul 2>&1

for /f "tokens=1-3 delims=/- " %%a in ("%date%") do (
  set yyyy=%%c
  set mm=%%b
  set dd=%%a
)
for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
  set hh=%%a
  set mi=%%b
  set ss=%%c
)
set hh=%hh: =0%
set stamp=%yyyy%-%mm%-%dd%_%hh%-%mi%-%ss%
set outfile=..\out\sysinfo_%computername%_%stamp%.json

powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\sysinfo.ps1" -OutFile "%outfile%"
echo.
echo Output: %outfile%
echo.
pause
