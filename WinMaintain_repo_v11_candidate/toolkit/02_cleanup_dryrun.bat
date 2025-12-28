@echo off
setlocal
set "HERE=%~dp0"
set "OUTDIR=%HERE%out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo NOTE: this is DRY-RUN (no deletion). Output -> %OUTDIR%
python "%HERE%win_maintain.py" --outdir "%OUTDIR%" cleanup

echo.
echo Done.
pause
