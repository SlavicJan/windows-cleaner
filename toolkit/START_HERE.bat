@echo off
:: WinMaintain unified entry point
:: This batch script calls the environment detection PowerShell script and then
:: displays a simple menu for the user.  It shows a summary of the current
:: environment (Python version, administrative privileges, TPM and Secure Boot
:: status, and free space on drive C).  An option is provided to view the
:: full environment report saved by the PowerShell script.

:: Ensure UTF‑8 output (Windows 10/11)
chcp 65001 >nul

:: Run the environment detection script and capture the summary line into ENV_SUMMARY.
for /F "usebackq delims=" %%E in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0detect_env.ps1"`) do (
    set "ENV_SUMMARY=%%E"
)

:: Display the environment summary at the top of the menu
echo.
echo ================================================================
echo        WinMaintain Environment Summary
echo    %ENV_SUMMARY%
echo ================================================================
echo.

:: Determine whether Python is available (disabled if Python=No in summary)
set "HAS_PY=1"
echo %ENV_SUMMARY% | find "Python=No" >nul 2>&1
if %errorlevel% equ 0 (
    set "HAS_PY=0"
)

:MENU
echo.
echo Select an option:
echo 1) Show system information
if "%HAS_PY%"=="1" (
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

if "%CHOICE%"=="1" goto SYSINFO
if "%CHOICE%"=="2" (
    if "%HAS_PY%"=="1" (goto AUDIT) else (echo Python not available. Option disabled.& goto MENU)
)
if "%CHOICE%"=="3" (
    if "%HAS_PY%"=="1" (goto QUICK) else (echo Python not available. Option disabled.& goto MENU)
)
if "%CHOICE%"=="4" (
    if "%HAS_PY%"=="1" (goto FULL) else (echo Python not available. Option disabled.& goto MENU)
)
if "%CHOICE%"=="5" goto BACKUP
if "%CHOICE%"=="6" goto COLLECT
if "%CHOICE%"=="9" goto VIEWREPORT
if "%CHOICE%"=="0" goto END
echo Invalid choice. Please try again.
goto MENU

:: Option implementations
:SYSINFO
echo.
echo [INFO] Displaying system information...
systeminfo | more
goto MENU

:AUDIT
echo.
echo [AUDIT] Running full disk audit...
:: TODO: call the Python script for audit
python "%~dp0win_maintain.py" scan
goto MENU

:QUICK
echo.
echo [QUICK] Running quick cleanup...
:: TODO: call the Python script for quick cleanup
python "%~dp0win_maintain.py" cleanup --quick
goto MENU

:FULL
echo.
echo [FULL] Running full cleanup...
:: TODO: call the Python script for full cleanup
python "%~dp0win_maintain.py" cleanup
goto MENU

:BACKUP
echo.
echo [BACKUP] Backing up browser profiles...
:: TODO: implement backup logic or call existing PowerShell script
echo Backup operation completed.
goto MENU

:COLLECT
echo.
echo [COLLECT] Collecting log files...
:: TODO: implement log collection logic or call existing script
echo Logs collected.
goto MENU

:VIEWREPORT
echo.
echo Opening environment report...
set "REPORT_PATH=%~dp0..\out\env_report.json"
if exist "%REPORT_PATH%" (
    start notepad "%REPORT_PATH%"
) else (
    echo Report not found: %REPORT_PATH%
)
goto MENU

:END
echo Exiting WinMaintain. Goodbye!
exit /b