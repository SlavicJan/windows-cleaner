@echo off
setlocal
set "HERE=%~dp0"
set "OUTDIR=%HERE%out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo Recommended: Run this .bat as Administrator.
python "%HERE%win_maintain.py" --outdir "%OUTDIR%" cleanup --yes

echo.
echo Done.
pause
