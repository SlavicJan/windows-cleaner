# win_collect_session.py
# Collect local logs + scripts + outputs into a single folder/zip.
# It does NOT read any ChatGPT history (that's only available via ChatGPT export).
#
# Usage:
#   python win_collect_session.py --dest D:\Backups\WinSession
#   python win_collect_session.py --dest D:\Backups\WinSession --zip
#
# What it grabs:
# - PowerShell history (PSReadLine ConsoleHost_history.txt)
# - Windows version / hardware summary (basic)
# - Recent readiness reports on Desktop (win11_readiness*.json/txt)
# - This tool files (if run from the pack folder)
#
# Optional: you can add your own files into the created session folder before zipping.

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Tuple


def decode_best_effort(b: bytes) -> str:
    if b is None:
        return ""
    for enc in ("utf-8", "utf-8-sig", "cp866", "cp1251", "mbcs"):
        try:
            return b.decode(enc)
        except Exception:
            continue
    return b.decode("utf-8", errors="replace")


def run_cmd(cmd: List[str]) -> Tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True)
    out = decode_best_effort(p.stdout).strip()
    err = decode_best_effort(p.stderr).strip()
    return p.returncode, out, err


def copy_if_exists(src: Path, dst: Path):
    if not src.exists():
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(src, dst, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dst)
    return True


def find_ps_history_candidates() -> List[Path]:
    appdata = Path(os.environ.get("APPDATA", ""))
    return [
        appdata / "Microsoft" / "Windows" / "PowerShell" / "PSReadLine" / "ConsoleHost_history.txt",   # Windows PowerShell
        appdata / "Microsoft" / "PowerShell" / "PSReadLine" / "ConsoleHost_history.txt",              # PowerShell 7+
    ]


def export_installed_programs(out_file: Path):
    ps = r'''
$ErrorActionPreference = "SilentlyContinue"
$k1 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$k2 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$k3 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$apps = @()
foreach ($k in @($k1,$k2,$k3)) {
  Get-ItemProperty $k | ForEach-Object {
    if ($_.DisplayName) {
      $apps += [pscustomobject]@{
        Name = $_.DisplayName
        Version = $_.DisplayVersion
        Publisher = $_.Publisher
        InstallLocation = $_.InstallLocation
        UninstallString = $_.UninstallString
      }
    }
  }
}
$apps | Sort-Object Name -Unique | ConvertTo-Json -Depth 4
'''
    code, out, err = run_cmd(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps])
    out_file.write_text(out if out else json.dumps({"error": err, "code": code}, ensure_ascii=False, indent=2), encoding="utf-8")


def export_system_summary(out_file: Path):
    code, out, err = run_cmd(["cmd", "/c", "systeminfo"])
    out_file.write_text(out if out else f"error: {err}", encoding="utf-8")


def main():
    if os.name != "nt":
        print("This tool is for Windows.")
        sys.exit(1)

    ap = argparse.ArgumentParser("win_collect_session")
    ap.add_argument("--dest", default=r"D:\Backups\WinSession", help="Where to place the session folder.")
    ap.add_argument("--zip", action="store_true", help="Also zip the session folder at the end.")
    args = ap.parse_args()

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest_root = Path(args.dest).expanduser().resolve()
    session_dir = dest_root / f"win_session_{stamp}"
    session_dir.mkdir(parents=True, exist_ok=True)

    # 1) PowerShell history
    hist_dir = session_dir / "powershell_history"
    hist_dir.mkdir(exist_ok=True)
    copied = []
    for cand in find_ps_history_candidates():
        dst = hist_dir / cand.name
        if copy_if_exists(cand, dst):
            copied.append(str(cand))
    (hist_dir / "sources.txt").write_text("\n".join(copied) if copied else "No PSReadLine history found.", encoding="utf-8")

    # 2) System summary
    export_system_summary(session_dir / "systeminfo.txt")

    # 3) Installed programs
    export_installed_programs(session_dir / "installed_programs.json")

    # 4) Grab readiness reports from Desktop
    desktop = Path(os.environ.get("USERPROFILE", "")) / "Desktop"
    rep_dir = session_dir / "reports"
    rep_dir.mkdir(exist_ok=True)
    if desktop.exists():
        for pat in ("win11_readiness*.txt", "win11_readiness*.json", "win11_readiness_v2*.txt", "win11_readiness_v2*.json"):
            for f in desktop.glob(pat):
                copy_if_exists(f, rep_dir / f.name)

    # 5) Copy current folder (pack scripts) into session if present
    cur = Path.cwd()
    pack_dir = session_dir / "pack_files"
    pack_dir.mkdir(exist_ok=True)
    for name in ("win_maintain.py", "win_collect_session.py", "README.md", "CHECKLIST_backup.md", "PROMPT_FOR_NEW_CHAT.txt"):
        src = cur / name
        if src.exists():
            copy_if_exists(src, pack_dir / name)

    # Manifest
    manifest = {
        "created_at": datetime.now().isoformat(timespec="seconds"),
        "session_dir": str(session_dir),
        "notes": [
            "ChatGPT chat history is NOT collected by this script.",
            "If you need ChatGPT logs: export from ChatGPT UI and copy into this session folder.",
        ],
    }
    (session_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    zip_path = None
    if args.zip:
        zip_path = str(dest_root / f"win_session_{stamp}.zip")
        shutil.make_archive(zip_path[:-4], "zip", root_dir=str(session_dir))

    print(f"Session saved to: {session_dir}")
    if zip_path:
        print(f"Zipped to: {zip_path}")


if __name__ == "__main__":
    main()
