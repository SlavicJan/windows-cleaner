
# WinMaintain

Windows 10/11 maintenance toolkit: **audit**, **cleanup**, **browser backup**, **session logs**, **Win11 readiness**.

This repo is structured like a product:
- **One nice EXE with UI**: .NET Launcher (single-file, self-contained)
- **Optional second EXE**: Python scanner (PyInstaller *onedir*) for deep disk scans/reports

> ⚠️ Notes
> - “Full cleanup” requests Administrator rights (UAC).
> - System cleanup may free little space if the machine is already clean — the big wins are usually **AppData / OneDrive / IDE caches**.

---

## Quick start (for end users)

1. Run **WinMaintainLauncher.exe**
2. Recommended flow:
   - **Audit → Dry-run → (optional Backup browsers) → Full cleanup → Zip session**
3. Logs and reports:
   - Logs: `%LOCALAPPDATA%\WinMaintain\toolkit\logs\YYYY-MM-DD\`
   - Reports: `%LOCALAPPDATA%\WinMaintain\toolkit\out\`

---

## Repo structure

```
toolkit/        # payload contents (bat/ps1/scripts)
launcher/       # .NET UI launcher (WinForms/WPF)
python_app/     # optional python scanner + report tools
assets/         # icons, cover, prompts, UI references
build/          # build scripts (payload zip, dotnet publish, pyinstaller)
dist/           # build outputs
docs/           # documentation
```

---

## Documentation

- Product overview + terms of reference: `docs/TECH_SPEC_RU.md`
- Explanatory note (why this architecture): `docs/EXPLANATORY_NOTE_RU.md`
- End-user guide: `docs/USER_GUIDE_RU.md`
- Build guide (Launcher + payload): `docs/BUILD_LAUNCHER_RU.md`
- Build guide (Python scanner EXE): `docs/BUILD_PYINSTALLER_RU.md`
- Troubleshooting: `docs/TROUBLESHOOTING_RU.md`
- Prompts + style guide: `assets/PROMPTS.md`, `assets/STYLE_GUIDE.md`

---

## License

MIT — see `LICENSE`.
