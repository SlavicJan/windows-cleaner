@echo off
:: WinMaintain unified entry point
:: Shows environment summary and routes to audit/cleanup/backup tools.

chcp 65001 >nul
setlocal EnableDelayedExpansion

set "REPORT_PATH=%~dp0..\out\env_report.json"
set "ENV_SUMMARY=Collecting environment info..."
set "HAS_PY=1"

:: Run environment detection and capture summary
for /F "usebackq delims=" %%E in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0detect_env.ps1"`) do (
    set "ENV_SUMMARY=%%E"
)

:: Prefer summary from the generated JSON if available (more reliable for parsing)
if exist "%REPORT_PATH%" (
    for /F "usebackq delims=" %%E in (`powershell -NoProfile -Command "(Get-Content -Raw '%REPORT_PATH%' | ConvertFrom-Json).summary"`) do (
        set "ENV_SUMMARY=%%E"
    )
)

:: Determine Python availability using the JSON report
if exist "%REPORT_PATH%" (
    for /F "usebackq delims=" %%P in (`powershell -NoProfile -Command "if (Test-Path '%REPORT_PATH%') { $data = Get-Content -Raw '%REPORT_PATH%' | ConvertFrom-Json; if ($data.python_version) { '1' } else { '0' } }"`) do (
        set "HAS_PY=%%P"
    )
) else (
    echo !ENV_SUMMARY! | find "Python=No" >nul 2>&1 && set "HAS_PY=0"
)

:MENU
echo.
echo ================================================================
echo        WinMaintain Environment Summary
echo    !ENV_SUMMARY!
echo ================================================================
echo.
echo Select an option:
echo 1) Show system information
if "!HAS_PY!"=="1" (
    echo 2) Run disk audit (requires Python)
    echo 3) Quick cleanup (requires Python)
    echo 4) Full cleanup (requires Python)
) else (
    echo 2) Run disk audit (requires Python) [Disabled]
    echo 3) Quick cleanup (requires Python) [Disabled]
    echo 4) Full cleanup (requires Python) [Disabled]
)
echo 5) Backup browser profiles
echo 6) Collect log files
echo 9) View environment report
echo 0) Exit
echo.
set /p "CHOICE=Enter your choice: "

echo.
if "%CHOICE%"=="1" goto SYSINFO
if "%CHOICE%"=="2" (
    if "!HAS_PY!"=="1" (goto AUDIT) else (echo Python not available. Option disabled.& goto MENU)
)
if "%CHOICE%"=="3" (
    if "!HAS_PY!"=="1" (goto QUICK) else (echo Python not available. Option disabled.& goto MENU)
)
if "%CHOICE%"=="4" (
    if "!HAS_PY!"=="1" (goto FULL) else (echo Python not available. Option disabled.& goto MENU)
)
if "%CHOICE%"=="5" goto BACKUP
if "%CHOICE%"=="6" goto COLLECT
if "%CHOICE%"=="9" goto VIEWREPORT
if "%CHOICE%"=="0" goto END
echo Invalid choice. Please try again.
goto MENU

:SYSINFO
echo [INFO] Displaying system information...
systeminfo | more
goto MENU

:AUDIT
echo [AUDIT] Running full disk audit...
python "%~dp0win_maintain.py" scan
goto MENU

:QUICK
echo [QUICK] Running quick cleanup...
python "%~dp0win_maintain.py" cleanup --quick
goto MENU

:FULL
echo [FULL] Running full cleanup...
python "%~dp0win_maintain.py" cleanup
goto MENU

:BACKUP
echo [BACKUP] Backing up browser profiles...
python "%~dp0win_maintain.py" backup-browsers
goto MENU

:COLLECT
echo [COLLECT] Collecting log files...
python "%~dp0win_collect_session.py"
goto MENU

:VIEWREPORT
echo Opening environment report...
if exist "%REPORT_PATH%" (
    start notepad "%REPORT_PATH%"
    powershell -NoProfile -Command "try { Get-Content -Raw '%REPORT_PATH%' | Set-Clipboard; Write-Host 'Report copied to clipboard.' } catch { Write-Host 'Clipboard unavailable; report opened in Notepad.' }"
) else (
    echo Report not found: %REPORT_PATH%
)
goto MENU

:END
echo Exiting WinMaintain. Goodbye!
endlocal
exit /b
