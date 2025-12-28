@echo off
setlocal
set "HERE=%~dp0"
set "OUTDIR=%HERE%out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo Running scan... output -> %OUTDIR%
python "%HERE%win_maintain.py" --outdir "%OUTDIR%" scan

echo.
echo Done.
pause
