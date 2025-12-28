"""Unified console menu for WinMaintain.

This wrapper mirrors the START_HERE.bat experience but runs purely in
Python so it can be bundled as a standalone WinMaintain.exe via
PyInstaller. It reuses logic from win_maintain.py where possible instead
of spawning extra Python processes.
"""
from __future__ import annotations

import argparse
import ctypes
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

try:  # Prefer the real module for scan/cleanup/backup implementations
    import win_maintain as wm

    WM_IMPORT_ERROR: Optional[str] = None
except Exception as exc:  # pragma: no cover - import errors should not break the menu shell
    wm = None
    WM_IMPORT_ERROR = str(exc)


def get_app_root() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    try:
        return Path(__file__).resolve().parent
    except Exception:
        return Path.cwd().resolve()


APP_ROOT = wm.APP_ROOT if wm else get_app_root()
DEFAULT_OUTDIR = wm.DEFAULT_OUTDIR if wm else APP_ROOT / "out"


def run_powershell(cmd: str) -> tuple[int, str, str]:
    prefix = "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); $ProgressPreference='SilentlyContinue'; "
    proc = subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", prefix + cmd],
        capture_output=True,
        text=True,
        errors="replace",
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def detect_python_version() -> Optional[str]:
    return sys.version.split()[0] if sys.version else None


def detect_is_admin() -> bool:
    if wm and hasattr(wm, "is_admin"):
        return bool(wm.is_admin())
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def detect_tpm_enabled() -> Optional[bool]:
    code, out, _ = run_powershell("try { (Get-Tpm).TpmPresent } catch { '' }")
    if code != 0 or out == "":
        return None
    if out.strip().lower() in {"true", "false"}:
        return out.strip().lower() == "true"
    return None


def detect_secure_boot() -> Optional[bool]:
    code, out, _ = run_powershell("try { Confirm-SecureBootUEFI } catch { '' }")
    if code != 0 or out == "":
        return None
    if out.strip().lower() in {"true", "false"}:
        return out.strip().lower() == "true"
    return None


def detect_free_space_gb() -> Optional[float]:
    try:
        du = shutil.disk_usage("C:\\")
        return round(du.free / (1024 ** 3), 2)
    except Exception:
        return None


def build_env_report() -> tuple[str, Path]:
    py_ver = detect_python_version()
    is_admin = detect_is_admin()
    tpm_enabled = detect_tpm_enabled()
    secure_boot = detect_secure_boot()
    free_space = detect_free_space_gb()

    def _fmt_bool(val: Optional[bool]) -> str:
        if val is True:
            return "Yes"
        if val is False:
            return "No"
        return "Unknown"

    summary = "Python={py} | Admin={adm} | TPM={tpm} | SecureBoot={sb} | FreeC={free}".format(
        py=py_ver or "No",
        adm="Yes" if is_admin else "No",
        tpm=_fmt_bool(tpm_enabled),
        sb=_fmt_bool(secure_boot),
        free=free_space if free_space is not None else "?",
    )

    report = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "python_version": py_ver,
        "is_admin": is_admin,
        "tpm_enabled": tpm_enabled,
        "secure_boot": secure_boot,
        "free_space_gb": free_space,
        "summary": summary,
    }

    outdir = Path(DEFAULT_OUTDIR)
    outdir.mkdir(parents=True, exist_ok=True)
    report_path = outdir / "env_report.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return summary, report_path


def print_header(summary: str) -> None:
    print("\n================================================")
    print("       WinMaintain Environment Summary")
    print(f"   {summary}")
    print("================================================\n")


def pause() -> None:
    input("Press Enter to continue...")


def run_system_info() -> None:
    print("[INFO] Displaying system information...\n")
    subprocess.run(["systeminfo"])


def ensure_python_ready() -> bool:
    if wm:
        return True
    print("Python components unavailable: win_maintain import failed.")
    if WM_IMPORT_ERROR:
        print(f"Details: {WM_IMPORT_ERROR}")
    return False


def run_scan() -> None:
    if not ensure_python_ready():
        return
    args = argparse.Namespace(
        outdir=str(DEFAULT_OUTDIR),
        roots=[],
        depth=6,
        top=25,
        files=30,
    )
    wm.cmd_scan(args)


def run_cleanup(execute: bool) -> None:
    if not ensure_python_ready():
        return
    actions = wm.build_cleanup_actions(include_browser_cache=False, include_nvidia_app=False)
    report = wm.cleanup(actions, yes=execute, outdir=Path(DEFAULT_OUTDIR))
    mode = "EXECUTE" if execute else "DRY RUN"
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"Cleanup mode: {mode}. Reports saved to {DEFAULT_OUTDIR}")


def run_backup() -> None:
    if not ensure_python_ready():
        return
    default_dest = r"D:\\Backups\\Browsers"
    dest = input(f"Destination folder for browser backup [{default_dest}]: ").strip() or default_dest
    report = wm.backup_browsers(dest=dest, kill_browsers=False, best_effort=False)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"Backup complete. Reports saved under {dest}.")


def run_log_collection() -> None:
    if os.name != "nt":
        print("Log collection is only available on Windows.")
        return
    try:
        import win_collect_session as wcs
    except Exception as exc:  # pragma: no cover
        print(f"Failed to load win_collect_session: {exc}")
        return

    # Reuse its CLI defaults without spawning new processes
    saved = sys.argv[:]
    sys.argv = ["win_collect_session"]
    try:
        wcs.main()
    finally:
        sys.argv = saved


def view_env_report(report_path: Path) -> None:
    if not report_path.exists():
        print(f"Report not found: {report_path}")
        return
    print(f"Opening {report_path} ...")
    try:
        os.startfile(str(report_path))  # type: ignore[attr-defined]
    except Exception:
        print(report_path.read_text(encoding="utf-8"))


def main() -> int:
    if os.name != "nt":
        print("WinMaintain.exe menu is intended for Windows.")
        return 1

    summary, report_path = build_env_report()
    has_python = ensure_python_ready()

    while True:
        print_header(summary)
        print("Select an option:")
        print("1) Show system information")
        if has_python:
            print("2) Run disk audit")
            print("3) Quick cleanup (dry-run)")
            print("4) Full cleanup (execute)")
        else:
            print("2) Run disk audit [Python missing]")
            print("3) Quick cleanup [Python missing]")
            print("4) Full cleanup [Python missing]")
        print("5) Backup browser profiles")
        print("6) Collect log files")
        print("9) View environment report")
        print("0) Exit")
        choice = input("Enter your choice: ").strip()
        print()

        if choice == "1":
            run_system_info()
            pause()
        elif choice == "2":
            run_scan()
            pause()
        elif choice == "3":
            run_cleanup(execute=False)
            pause()
        elif choice == "4":
            run_cleanup(execute=True)
            pause()
        elif choice == "5":
            run_backup()
            pause()
        elif choice == "6":
            run_log_collection()
            pause()
        elif choice == "9":
            view_env_report(report_path)
            pause()
        elif choice == "0":
            print("Exiting WinMaintain. Goodbye!")
            break
        else:
            print("Invalid choice. Please try again.\n")
            continue
    return 0


if __name__ == "__main__":
    sys.exit(main())
