@echo off
setlocal EnableExtensions
chcp 65001 >nul

REM ==========================================================
REM WinMaintain ONE-CLICK (recommended Admin):
REM   1) PS AUDIT (inventory)
REM   2) Python SCAN (space)
REM   3) PS QUICK cleanup (updates/temp/browsers/dev/NVIDIA caches)
REM   4) Browser profiles BACKUP (Edge/Yandex/Opera)
REM   5) Zip PS logs + collect session ZIP
REM ==========================================================

net session >nul 2>&1
if %errorlevel% NEQ 0 (
  echo [i] Need Administrator rights. Requesting UAC...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

set "HERE=%~dp0"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "OUTDIR=%HERE%out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%" >nul 2>&1

echo.
echo ==========================================================
echo Preconditions (best results)
echo ==========================================================
echo - Close Edge / Yandex / Opera (or script will try to kill them for backup).
echo - Close NVIDIA App if you want its caches removed.
echo - Keep ~20-30 GB free on C: permanently (Windows updates love eating space).
echo ==========================================================
echo.
timeout /t 3 >nul

echo.
echo [1/6] PS AUDIT (inventory only)...
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%HERE%ps_toolkit\scripts\run_toolkit.ps1" -Mode AuditOnly

echo.
echo [2/6] Python SCAN (where space goes) -> %OUTDIR%
python "%HERE%win_maintain.py" --outdir "%OUTDIR%" scan

echo.
echo [3/6] PS QUICK cleanup...
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%HERE%ps_toolkit\scripts\run_toolkit.ps1" -Mode Quick -NvidiaMode remove_caches

echo.
echo [4/6] Browser profiles BACKUP -> D:\Backups\Browsers
python "%HERE%win_maintain.py" backup-browsers --kill-browsers --best-effort --dest "D:\Backups\Browsers"

echo.
echo [5/6] Zip today's PS logs...
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%HERE%ps_toolkit\scripts\zip_logs.ps1"

echo.
echo [6/6] Collect session ZIP (PS history + reports) -> D:\Backups\WinSession
python "%HERE%win_collect_session.py" --dest "D:\Backups\WinSession" --zip

echo.
echo DONE. Opening folders...
start "" "%OUTDIR%" >nul 2>&1
start "" "%HERE%ps_toolkit\logs" >nul 2>&1
start "" "D:\Backups\WinSession" >nul 2>&1

echo.
echo Tip: if browser backup still shows WinError 32 on Cookies, close browsers and rerun 06_backup_browsers.bat.
echo.
pause
