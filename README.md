![WinMaintain banner](assets/winmaintain_banner.svg)

# WinMaintain

WinMaintain is a Windows 10/11 maintenance toolkit that focuses on **safe auditing, cleanup, backups, and report collection**. The toolkit ships with a unified entry point so both non-technical and power users can see what is safe to run on their machine.

## What changed in this release
- **Unified entry point** via `toolkit/START_HERE.bat` that detects the environment and hides Python-only actions when Python is missing.
- **Environment autodetection** (Python version, Administrator, TPM/Secure Boot, free C: space) with a JSON report at `out/env_report.json` for support cases.
- **Release automation** now publishes both a portable ZIP and a PyInstaller **WinMaintainScanner** EXE on every tag.
- Fresh branding assets under `assets/` plus updated docs for quick vs. full cleanup guidance.

## Features
- **Audit**: disk usage, top directories, session reports.
- **Cleanup**: quick (safe caches) or full (deeper Windows/installer caches; prompts for elevation).
- **Backups**: browser profile backups before cleanup.
- **Collection**: zip session logs for support.
- **Environment summary**: see Python availability, admin status, TPM/Secure Boot, and free space before you run anything.

## Getting started
### For non-technical users
1. Download the latest **WinMaintain_Portable_{version}.zip** from the Releases page and extract it anywhere (e.g., `D:\WinMaintain`).
2. Double-click `toolkit/START_HERE.bat`.
3. Read the environment line at the top (e.g., `Python=3.11 | Admin=No | TPM=Yes | SecureBoot=Yes | FreeC=12.5 GB`).
4. Choose:
   - **Audit** to see where space is used.
   - **Quick cleanup** to clear safe caches.
   - **Full cleanup** for deeper cleanup (will request Administrator approval).
   - **View environment report** to open/copy `out/env_report.json` for support.

### For technical users
- Run the menu: `toolkit\START_HERE.bat`
- Direct Python calls:
  ```powershell
  python toolkit\win_maintain.py scan
  python toolkit\win_maintain.py cleanup --quick
  python toolkit\win_maintain.py cleanup           # full
  python toolkit\win_maintain.py backup-browsers
  python toolkit\win_collect_session.py
  ```
- Environment detection alone: `powershell -ExecutionPolicy Bypass -File toolkit\detect_env.ps1`

## Release artefacts
- **Portable ZIP**: `WinMaintain_Portable_{tag}.zip` (runs the whole toolkit from any folder).
- **Scanner EXE**: `WinMaintainScanner_{tag}.exe` (PyInstaller one-file build of `toolkit/win_maintain.py`).
- Both assets are attached automatically to GitHub releases on tagged pushes.

## Repository layout
```
toolkit/        batch + PowerShell entry points and Python scanner
assets/         branding (banner, icons, prompts, style guide)
build/          build scripts
.github/        workflows for release automation
docs/           product documentation
```

## Documentation
- End-user guide: `docs/USER_GUIDE_RU.md`
- Troubleshooting: `docs/TROUBLESHOOTING_RU.md`
- Technical specification: `docs/TECH_SPEC_RU.md`
- Build guides: `docs/BUILD_LAUNCHER_RU.md`, `docs/BUILD_PYINSTALLER_RU.md`
- Prompts + style guide: `assets/PROMPTS.md`, `assets/STYLE_GUIDE.md`

## License
MIT — see `LICENSE`.
