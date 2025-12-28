@echo off
setlocal
set "HERE=%~dp0"
set "OUTDIR=%HERE%out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo Close NVIDIA app before continuing. Recommended to run as Administrator.
choice /c YN /m "NVIDIA app is closed? (Y/N)" 
if errorlevel 2 goto :eof

python "%HERE%win_maintain.py" --outdir "%OUTDIR%" cleanup --yes --nvidia-app-cache

echo.
echo Done.
pause
