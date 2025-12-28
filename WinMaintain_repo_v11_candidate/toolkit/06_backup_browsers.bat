@echo off
setlocal
set "HERE=%~dp0"

echo Backing up browser profiles to: D:\Backups\Browsers
echo Close browsers for best results (or this script will try to kill them).

python "%HERE%win_maintain.py" backup-browsers --kill-browsers --best-effort --dest "D:\Backups\Browsers"

echo.
echo Done.
pause
