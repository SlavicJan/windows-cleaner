@echo off
setlocal
set "HERE=%~dp0"

echo Collecting session (logs, PS history, reports) -> D:\Backups\WinSession
python "%HERE%win_collect_session.py" --dest "D:\Backups\WinSession" --zip

echo.
echo Done.
pause
