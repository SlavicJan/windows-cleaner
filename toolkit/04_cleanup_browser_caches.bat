@echo off
setlocal
set "HERE=%~dp0"
set "OUTDIR=%HERE%out"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo Close Edge / Yandex / Opera before continuing.
choice /c YN /m "Browsers are closed? (Y/N)" 
if errorlevel 2 goto :eof

python "%HERE%win_maintain.py" --outdir "%OUTDIR%" cleanup --yes --browser-cache

echo.
echo Done.
pause
