# Windows Cleanup Toolkit (portable) - v5

New in v5:
- After running, it **opens the log folder** automatically.
- Logs are stored in `logs\YYYY-MM-DD\` next to the toolkit.
- Added `scripts\zip_today_logs.bat` to pack today's logs into a ZIP.

## Run
- Audit: `scripts\run_audit_only.bat` (no admin needed)
- Quick: `scripts\run_quick_as_admin.bat` (asks for admin)
- Full: `scripts\run_full_as_admin.bat` (asks for admin)

## Logs
Default location: `toolkit_root\logs\YYYY-MM-DD\`

You can override log root:
`powershell -File scripts\run_toolkit.ps1 -Mode Full -LogRoot "D:\logs_windows_toolkit" -OpenLogs`

## Export logs
Run: `scripts\zip_today_logs.bat`
