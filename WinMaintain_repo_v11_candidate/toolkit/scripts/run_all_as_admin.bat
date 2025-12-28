@echo off
set "HERE=%~dp0"
REM Run PowerShell script with ExecutionPolicy bypass
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%run_all.ps1"
pause
