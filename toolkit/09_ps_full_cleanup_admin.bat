@echo off
setlocal
set "HERE=%~dp0"
echo This will run FULL cleanup (PowerShell toolkit). It will request Administrator rights.
call "%HERE%ps_toolkit\scripts\run_full_as_admin.bat"
