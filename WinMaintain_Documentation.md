# WinMaintain Documentation (summary)

## Executables
- **WinMaintain.exe** — one-file build of `toolkit/winmaintain_gui.py` that replicates the START_HERE menu without requiring a local Python install.
- **WinMaintainScanner.exe** — CLI-only PyInstaller build of `toolkit/win_maintain.py` for scripted scans and cleanups.
- **WinMaintain_Portable_{tag}.zip** — the full toolkit with batch/PowerShell wrappers for compatibility.

## Menu actions
The menu offers system info, disk audit, cleanup (dry-run or execute), browser backup, log collection, and opening the environment report. Python-backed actions reuse the functions inside `toolkit/win_maintain.py`; log collection reuses `toolkit/win_collect_session.py` without spawning extra Python processes.

## Environment detection
The GUI gathers Python version, Administrator status, TPM/Secure Boot, and free space, writing the results to `out/env_report.json` next to the executable.

## Report locations
- Python scan/cleanup reports: `out/` (adjacent to the EXE or toolkit folder).
- PowerShell audits: `toolkit/ps_toolkit/logs/YYYY-MM-DD/`.
- Session collections: the destination folder chosen in the log collection prompt (default `D:\Backups\WinSession`).
