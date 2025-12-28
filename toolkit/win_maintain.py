# win_maintain.py (v3)
# Windows 10/11 maintenance helper: scan disk hogs, backup browser profiles, and run safe cleanups.
# No external deps. Python 3.9+ recommended.
#
# Safety:
# - Default cleanup mode is DRY-RUN (shows what would be deleted).
# - Only deletes known cache/temp locations unless you explicitly enable extra flags.
# - Skips symlinks/reparse points while scanning to avoid loops.
#
# Usage examples:
#   python win_maintain.py scan
#   python win_maintain.py cleanup            (dry-run)
#   python win_maintain.py cleanup --yes      (execute)
#   python win_maintain.py cleanup --yes --browser-cache
#   python win_maintain.py cleanup --yes --nvidia-app-cache
#   python win_maintain.py backup-browsers --dest D:\Backups\Browsers
#   python win_maintain.py winupdate-cache --yes
#
# Tip: run PowerShell as Administrator for best results.

from __future__ import annotations

import argparse
import csv
import ctypes
import heapq
import json
import os
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path

def get_app_root() -> Path:
    """Return the directory where reports should live.
    - In source run: folder containing this script.
    - In frozen/EXE run: folder containing the executable.
    """
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    # __file__ exists in source runs (including PyInstaller --onedir).
    try:
        return Path(__file__).resolve().parent
    except Exception:
        return Path.cwd().resolve()

APP_ROOT = get_app_root()
DEFAULT_OUTDIR = APP_ROOT / "out"

from typing import Dict, List, Tuple


REPARSE_POINT_ATTR = 0x0400  # FILE_ATTRIBUTE_REPARSE_POINT


def is_admin() -> bool:
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


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


def run_powershell(ps: str) -> Tuple[int, str, str]:
    prefix = "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); $ProgressPreference='SilentlyContinue'; "
    return run_cmd(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", prefix + ps])


def format_gb(num_bytes: float) -> str:
    return f"{num_bytes / (1024**3):.2f} GB"


def is_reparse_point(path: str) -> bool:
    try:
        st = os.stat(path, follow_symlinks=False)
        attrs = getattr(st, "st_file_attributes", 0)
        return bool(attrs & REPARSE_POINT_ATTR)
    except Exception:
        return False


def list_drives() -> List[str]:
    drives = []
    for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        p = f"{c}:\\"
        if os.path.exists(p):
            drives.append(p)
    return drives


@dataclass
class ScanStats:
    root: str
    depth: int
    files_scanned: int = 0
    dirs_scanned: int = 0
    bytes_total: int = 0
    errors: int = 0
    denied: int = 0
    skipped_reparse: int = 0
    elapsed_sec: float = 0.0


@dataclass
class ScanResult:
    stats: ScanStats
    top_dirs_level1: List[Tuple[str, int]]
    top_dirs_level2: List[Tuple[str, int]]
    top_files: List[Tuple[str, int]]


def scan_root(root: str, depth: int, top_dirs: int, top_files: int) -> ScanResult:
    t0 = time.time()
    root = os.path.abspath(root)
    stats = ScanStats(root=root, depth=depth)

    lvl1: Dict[str, int] = {}
    lvl2: Dict[str, int] = {}
    file_heap: List[Tuple[int, str]] = []

    stack = [root]
    root_parts_len = len(Path(root).parts)

    def add_file(sz: int, p: str):
        if top_files <= 0:
            return
        if len(file_heap) < top_files:
            heapq.heappush(file_heap, (sz, p))
        else:
            if sz > file_heap[0][0]:
                heapq.heapreplace(file_heap, (sz, p))

    while stack:
        cur = stack.pop()
        stats.dirs_scanned += 1
        try:
            with os.scandir(cur) as it:
                for entry in it:
                    try:
                        if entry.is_symlink():
                            continue
                        full = entry.path
                        if is_reparse_point(full):
                            stats.skipped_reparse += 1
                            continue

                        if entry.is_dir(follow_symlinks=False):
                            rel_parts = len(Path(full).parts) - root_parts_len
                            if depth < 0 or rel_parts <= depth:
                                stack.append(full)
                        elif entry.is_file(follow_symlinks=False):
                            st = entry.stat(follow_symlinks=False)
                            sz = int(getattr(st, "st_size", 0))
                            stats.files_scanned += 1
                            stats.bytes_total += sz

                            try:
                                rel = os.path.relpath(full, root)
                            except Exception:
                                rel = full
                            parts = rel.split(os.sep)
                            if len(parts) >= 1:
                                lvl1[parts[0]] = lvl1.get(parts[0], 0) + sz
                            if len(parts) >= 2:
                                k2 = os.path.join(parts[0], parts[1])
                                lvl2[k2] = lvl2.get(k2, 0) + sz

                            add_file(sz, full)
                    except PermissionError:
                        stats.denied += 1
                    except FileNotFoundError:
                        stats.errors += 1
                    except OSError:
                        stats.errors += 1
        except PermissionError:
            stats.denied += 1
        except FileNotFoundError:
            stats.errors += 1
        except OSError:
            stats.errors += 1

    stats.elapsed_sec = round(time.time() - t0, 2)
    top1 = sorted(lvl1.items(), key=lambda x: x[1], reverse=True)[:top_dirs]
    top2 = sorted(lvl2.items(), key=lambda x: x[1], reverse=True)[:top_dirs]
    top_files_list = sorted([(p, sz) for (sz, p) in file_heap], key=lambda x: x[1], reverse=True)
    return ScanResult(stats=stats, top_dirs_level1=top1, top_dirs_level2=top2, top_files=top_files_list)


def print_drive_table() -> List[Dict[str, str]]:
    rows = []
    print("=== Drives ===")
    for d in list_drives():
        try:
            du = shutil.disk_usage(d)
            used = du.total - du.free
            print(f"{d}  Total: {format_gb(du.total)} | Used: {format_gb(used)} | Free: {format_gb(du.free)}")
            rows.append({"drive": d, "total_gb": f"{du.total/(1024**3):.2f}", "free_gb": f"{du.free/(1024**3):.2f}"})
        except Exception as e:
            print(f"{d}  (error reading usage: {e})")
            rows.append({"drive": d, "error": str(e)})
    print()
    return rows


from dataclasses import dataclass

@dataclass
class CleanupAction:
    name: str
    description: str
    targets: List[str]
    needs_admin: bool = False


def expand_globs(patterns: List[str]) -> List[Path]:
    out: List[Path] = []
    for pat in patterns:
        pat2 = os.path.expandvars(pat)
        p = Path(pat2)
        if "*" in pat2 or "?" in pat2:
            parent = p.parent
            if parent.exists():
                out.extend(list(parent.glob(p.name)))
            else:
                out.append(p)
        else:
            out.append(p)
    uniq, seen = [], set()
    for p in out:
        s = str(p).lower()
        if s not in seen:
            uniq.append(p)
            seen.add(s)
    return uniq


def remove_path(p: Path) -> Tuple[bool, str]:
    try:
        if not p.exists():
            return True, "not_found"
        if p.is_symlink():
            return True, "skip_symlink"
        if is_reparse_point(str(p)):
            return True, "skip_reparse_point"
        if p.is_file():
            p.unlink()
            return True, "deleted_file"
        if p.is_dir():
            shutil.rmtree(p, ignore_errors=False)
            return True, "deleted_dir"
        return True, "unknown_type"
    except PermissionError as e:
        return False, f"permission_denied: {e}"
    except Exception as e:
        return False, f"error: {e}"


def cleanup(actions: List[CleanupAction], yes: bool, outdir: Path) -> Dict[str, object]:
    report = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "is_admin": is_admin(),
        "mode": "EXECUTE" if yes else "DRY_RUN",
        "actions": [],
    }

    for act in actions:
        act_entry = {"name": act.name, "description": act.description, "needs_admin": act.needs_admin, "items": []}
        if act.needs_admin and not is_admin():
            act_entry["skipped"] = "needs_admin"
            report["actions"].append(act_entry)
            continue

        paths = expand_globs(act.targets)
        for p in paths:
            item = {"path": str(p), "exists": p.exists()}
            if yes:
                ok, msg = remove_path(p)
                item["result"] = msg
                item["ok"] = ok
            act_entry["items"].append(item)

        report["actions"].append(act_entry)

    if yes:
        code, out, err = run_powershell("try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch { $_.Exception.Message }")
        report["recycle_bin"] = {"code": code, "out": out, "err": err}

    outdir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    (outdir / f"cleanup_report_{ts}.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return report


def winupdate_cache_reset(yes: bool, outdir: Path) -> Dict[str, object]:
    report = {"generated_at": datetime.now().isoformat(timespec="seconds"), "mode": "EXECUTE" if yes else "DRY_RUN"}
    report["target"] = os.path.expandvars(r"%windir%\SoftwareDistribution\Download\*")

    if not yes:
        report["note"] = "Would stop wuauserv/bits, delete Download cache, then start services."
        (outdir / f"winupdate_cache_dryrun_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        return report

    if not is_admin():
        report["error"] = "Run as Administrator for this action."
        (outdir / f"winupdate_cache_error_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        return report

    cmds = [
        ["net", "stop", "wuauserv"],
        ["net", "stop", "bits"],
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
         r"Remove-Item -Recurse -Force \"$env:windir\SoftwareDistribution\Download\*\" -ErrorAction SilentlyContinue"],
        ["net", "start", "bits"],
        ["net", "start", "wuauserv"],
    ]
    results = []
    for c in cmds:
        code, out, err = run_cmd(c)
        results.append({"cmd": " ".join(c), "code": code, "out": out, "err": err})
    report["results"] = results

    (outdir / f"winupdate_cache_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return report


def backup_browsers(dest: str, kill_browsers: bool = False, best_effort: bool = False) -> Dict[str, object]:
    """
    Backup browser profiles (Edge / Yandex / Opera GX) to a folder.
    Notes:
      * For a "perfect" backup (cookies/sessions), CLOSE browsers first or use kill_browsers=True.
      * Saved passwords/cookies are DPAPI-encrypted and usually restore only on the same Windows install/user.
        For cross-install migration prefer browser Sync or password export to CSV.
    """
    import subprocess

    def _tasklist_names() -> set:
        try:
            out = subprocess.check_output(["tasklist", "/FO", "CSV", "/NH"], text=True, errors="ignore")
            names = set()
            for line in out.splitlines():
                line = line.strip()
                if not line:
                    continue
                # "Image Name","PID",...
                if line.startswith('"'):
                    img = line.split('","', 1)[0].strip('"')
                    names.add(img.lower())
            return names
        except Exception:
            return set()

    def _taskkill(img: str) -> None:
        try:
            subprocess.run(["taskkill", "/IM", img, "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    browser_imgs = ["msedge.exe", "browser.exe", "opera.exe"]
    running = [p for p in browser_imgs if p.lower() in _tasklist_names()]
    if running and not kill_browsers:
        # Don't do a half-backup that misses Cookies/Login Data
        return {
            "saved_to": None,
            "items": [],
            "error": f"Browsers are running ({', '.join(running)}). Close them or run with --kill-browsers."
        }

    if kill_browsers:
        for img in browser_imgs:
            _taskkill(img)
        # give processes a moment to release locks
        try:
            import time
            time.sleep(2)
        except Exception:
            pass

    local = Path(os.environ.get("LOCALAPPDATA", ""))
    roaming = Path(os.environ.get("APPDATA", ""))

    # Where to copy from
    profiles = [
        ("Edge_UserData", local / "Microsoft" / "Edge" / "User Data"),
        ("Yandex_UserData", local / "Yandex" / "YandexBrowser" / "User Data"),
        ("Opera_Stable_Roaming", roaming / "Opera Software" / "Opera Stable"),
        ("OperaGX_Stable_Roaming", roaming / "Opera Software" / "Opera GX Stable"),
    ]

    # Exclude obvious cache directories to keep backup smaller (does NOT affect passwords/bookmarks).
    EXCLUDE_DIR_NAMES = {
        "Cache", "Code Cache", "GPUCache", "ShaderCache", "GrShaderCache", "DawnCache",
        "Media Cache", "CacheStorage", "Crashpad", "Crash Reports"
    }

    def _copytree_best_effort(src: Path, dst: Path) -> List[Tuple[str, str, str]]:
        """
        Copy directory tree.
        Returns a list of (src, dst, error) for skipped/failed files (only used in best_effort mode).
        """
        errors: List[Tuple[str, str, str]] = []
        src = src.resolve()
        dst = dst.resolve()
        dst.mkdir(parents=True, exist_ok=True)

        for root, dirs, files in os.walk(src):
            root_p = Path(root)
            rel = root_p.relative_to(src)
            target_dir = dst / rel
            try:
                target_dir.mkdir(parents=True, exist_ok=True)
            except Exception:
                pass

            # filter out cache dirs
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIR_NAMES]

            for fn in files:
                s = root_p / fn
                t = target_dir / fn
                try:
                    t.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(s, t)
                except Exception as e:
                    if best_effort:
                        errors.append((str(s), str(t), repr(e)))
                        continue
                    raise
        return errors

    dest_root = Path(dest).expanduser().resolve()
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    outdir = dest_root / f"browsers_backup_{stamp}"
    outdir.mkdir(parents=True, exist_ok=True)

    report: Dict[str, object] = {"saved_to": str(outdir), "items": []}

    for name, src in profiles:
        if not src.exists():
            report["items"].append({"name": name, "src": str(src), "status": "not_found"})
            continue

        dst = outdir / name
        try:
            errs = _copytree_best_effort(src, dst)
            if errs:
                report["items"].append({"name": name, "src": str(src), "dst": str(dst), "status": "partial", "errors": errs[:50]})
            else:
                report["items"].append({"name": name, "src": str(src), "dst": str(dst), "status": "ok"})
        except Exception as e:
            report["items"].append({"name": name, "src": str(src), "dst": str(dst), "status": f"error: {e!r}"})

    # Save report JSON for audit
    (outdir / "backup_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return report


def optimize_ssd(drive_letter: str) -> Dict[str, object]:
    report = {"generated_at": datetime.now().isoformat(timespec="seconds"), "drive": drive_letter}
    if not is_admin():
        report["error"] = "Run as Administrator for TRIM."
        return report
    ps = f"try {{ Optimize-Volume -DriveLetter {drive_letter} -ReTrim -Verbose }} catch {{ $_.Exception.Message }}"
    code, out, err = run_powershell(ps)
    report.update({"code": code, "out": out, "err": err})
    return report


def cmd_scan(args: argparse.Namespace):
    drives_info = print_drive_table()

    roots = args.roots or []
    if not roots:
        user = os.environ.get("USERPROFILE", "")
        roots = [
            os.path.join(user, "AppData", "Local"),
            os.path.join(user, "AppData", "Roaming"),
            os.path.join(os.environ.get("windir", r"C:\Windows"), "SoftwareDistribution", "Download"),
            os.path.join(os.environ.get("windir", r"C:\Windows"), "Temp"),
        ]

    results: List[ScanResult] = []
    for r in roots:
        if not r:
            continue
        r = os.path.expandvars(r)
        if not os.path.exists(r):
            print(f"[skip] Not found: {r}")
            continue
        print(f"=== Scanning: {r} (depth={args.depth}) ===")
        res = scan_root(r, depth=args.depth, top_dirs=args.top, top_files=args.files)
        results.append(res)

        st = res.stats
        print(f"Scanned dirs={st.dirs_scanned}, files={st.files_scanned}, total={format_gb(st.bytes_total)}, "
              f"denied={st.denied}, errors={st.errors}, skipped_reparse={st.skipped_reparse}, time={st.elapsed_sec}s\n")

        print("--- Top folders (level 1) ---")
        for name, sz in res.top_dirs_level1:
            print(f"{name:<45} {format_gb(sz)}")
        print("\n--- Top folders (level 2) ---")
        for name, sz in res.top_dirs_level2:
            print(f"{name:<45} {format_gb(sz)}")
        print("\n--- Top files ---")
        for p, sz in res.top_files:
            print(f"{format_gb(sz):>10}  {p}")
        print("\n" + "=" * 70 + "\n")

    outdir = Path(args.outdir).resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    base = outdir / f"scan_report_{ts}"

    payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "is_admin": is_admin(),
        "drives": drives_info,
        "results": [
            {"stats": asdict(r.stats), "top_dirs_level1": r.top_dirs_level1, "top_dirs_level2": r.top_dirs_level2, "top_files": r.top_files}
            for r in results
        ],
    }
    (base.with_suffix(".json")).write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    # pathlib.Path.with_suffix expects a *file extension* like ".csv".
    # We want to add a postfix to the filename instead.
    topdirs_csv = base.with_name(base.name + "_topdirs.csv")
    with open(topdirs_csv, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["root", "level", "path", "bytes", "gb"])
        for r in results:
            root = r.stats.root
            for p, sz in r.top_dirs_level1:
                w.writerow([root, 1, p, sz, round(sz / (1024**3), 3)])
            for p, sz in r.top_dirs_level2:
                w.writerow([root, 2, p, sz, round(sz / (1024**3), 3)])

    print(f"Saved:\n- {base.with_suffix('.json')}\n- {topdirs_csv}")


def build_cleanup_actions(include_browser_cache: bool, include_nvidia_app: bool):
    local = r"%LOCALAPPDATA%"
    temp = r"%TEMP%"

    actions = [
        CleanupAction(
            name="Temp (user)",
            description="Clear user TEMP files (safe).",
            targets=[temp + r"\*"],
            needs_admin=False,
        ),
        CleanupAction(
            name="CrashDumps",
            description="Clear Windows Error Reporting crash dumps for user (safe).",
            targets=[local + r"\CrashDumps\*"],
            needs_admin=False,
        ),
        CleanupAction(
            name="SquirrelTemp",
            description="Clear installer temp used by Squirrel-based updaters (safe).",
            targets=[local + r"\SquirrelTemp\*"],
            needs_admin=False,
        ),
        CleanupAction(
            name="NVIDIA cache (ProgramData)",
            description="Clear NVIDIA downloader + NV_Cache (safe).",
            targets=[r"C:\ProgramData\NVIDIA Corporation\Downloader\*", r"C:\ProgramData\NVIDIA Corporation\NV_Cache\*"],
            needs_admin=True,
        ),
    ]

    if include_nvidia_app:
        actions.append(
            CleanupAction(
                name="NVIDIA app UpdateFramework",
                description="Clear NVIDIA app UpdateFramework cache (will re-download if needed).",
                targets=[
                    r"C:\ProgramData\NVIDIA Corporation\NVIDIA app\UpdateFramework\*",
                    r"C:\ProgramData\NVIDIA Corporation\NVIDIA app\Installer\*",
                ],
                needs_admin=True,
            )
        )

    if include_browser_cache:
        actions.extend([
            CleanupAction(
                name="Yandex Browser cache",
                description="Clear Yandex browser caches only (close browser first).",
                targets=[
                    local + r"\Yandex\YandexBrowser\User Data\*\Cache\*",
                    local + r"\Yandex\YandexBrowser\User Data\*\Code Cache\*",
                    local + r"\Yandex\YandexBrowser\User Data\*\GPUCache\*",
                    local + r"\Yandex\YandexBrowser\User Data\*\Service Worker\CacheStorage\*",
                    local + r"\Yandex\YandexBrowser\User Data\*\Service Worker\ScriptCache\*",
                ],
                needs_admin=False,
            ),
            CleanupAction(
                name="Opera cache",
                description="Clear Opera caches only (close browser first).",
                targets=[
                    local + r"\Opera Software\Opera Stable\Cache\*",
                    local + r"\Opera Software\Opera Stable\Code Cache\*",
                    local + r"\Opera Software\Opera Stable\GPUCache\*",
                    local + r"\Opera Software\Opera GX Stable\Cache\*",
                    local + r"\Opera Software\Opera GX Stable\Code Cache\*",
                    local + r"\Opera Software\Opera GX Stable\GPUCache\*",
                ],
                needs_admin=False,
            ),
            CleanupAction(
                name="Edge cache",
                description="Clear Edge caches only (close browser first).",
                targets=[
                    local + r"\Microsoft\Edge\User Data\*\Cache\*",
                    local + r"\Microsoft\Edge\User Data\*\Code Cache\*",
                    local + r"\Microsoft\Edge\User Data\*\GPUCache\*",
                    local + r"\Microsoft\Edge\User Data\*\Service Worker\CacheStorage\*",
                    local + r"\Microsoft\Edge\User Data\*\Service Worker\ScriptCache\*",
                ],
                needs_admin=False,
            ),
        ])

    return actions


def cmd_cleanup(args: argparse.Namespace):
    outdir = Path(args.outdir).resolve()
    actions = build_cleanup_actions(
        include_browser_cache=args.browser_cache,
        include_nvidia_app=args.nvidia_app_cache
    )

    print(f"Mode: {'EXECUTE' if args.yes else 'DRY_RUN'}")
    if args.browser_cache:
        print("Including browser caches: YES (close browsers before executing)")
    if args.nvidia_app_cache:
        print("Including NVIDIA app UpdateFramework cache: YES (admin + NVIDIA app closed recommended)")

    rep = cleanup(actions, yes=args.yes, outdir=outdir)
    print(f"Report saved into: {outdir}")
    if rep.get("mode") == "DRY_RUN":
        print("Dry-run complete. Re-run with --yes to actually delete.")
    else:
        print("Cleanup executed.")


def cmd_backup(args: argparse.Namespace):
    rep = backup_browsers(args.dest, kill_browsers=getattr(args,'kill_browsers', False), best_effort=getattr(args,'best_effort', False))
    print(json.dumps(rep, ensure_ascii=False, indent=2))


def cmd_winupdate_cache(args: argparse.Namespace):
    outdir = Path(args.outdir).resolve()
    rep = winupdate_cache_reset(yes=args.yes, outdir=outdir)
    print(json.dumps(rep, ensure_ascii=False, indent=2))


def cmd_trim(args: argparse.Namespace):
    rep = optimize_ssd(args.drive)
    print(json.dumps(rep, ensure_ascii=False, indent=2))


def main():
    if os.name != "nt":
        print("This tool is for Windows.")
        sys.exit(1)

    ap = argparse.ArgumentParser("win_maintain", description="Scan + safe cleanup + browser backup for Windows 10/11.")
    ap.add_argument(("--outdir", default=str(DEFAULT_OUTDIR)), help="Output dir for reports (default: current).")

    sub = ap.add_subparsers(dest="cmd", required=True)

    sp_scan = sub.add_parser("scan", help="Scan disk hogs under common roots (or provided roots).")

    sp_scan.add_argument("--outdir", default=argparse.SUPPRESS, help="Output dir for reports (default: current).")
    sp_scan.add_argument("--roots", nargs="*", default=[], help="Roots to scan (default: Local/Roaming + Win Update cache + Win Temp).")
    sp_scan.add_argument("--depth", type=int, default=6, help="Relative depth (default 6). Use -1 for unlimited (can be slow).")
    sp_scan.add_argument("--top", type=int, default=25, help="Top N folders (default 25).")
    sp_scan.add_argument("--files", type=int, default=30, help="Top N files (default 30).")
    sp_scan.set_defaults(func=cmd_scan)

    sp_cleanup = sub.add_parser("cleanup", help="Safe cleanup (temp/caches). Default is dry-run.")

    sp_cleanup.add_argument("--outdir", default=argparse.SUPPRESS, help="Output dir for reports (default: current).")
    sp_cleanup.add_argument("--yes", action="store_true", help="Actually delete (otherwise dry-run).")
    sp_cleanup.add_argument("--browser-cache", action="store_true", help="Also clear browser cache folders (profiles untouched).")
    sp_cleanup.add_argument("--nvidia-app-cache", action="store_true", help="Also clear NVIDIA app UpdateFramework/Installer cache (admin recommended).")
    sp_cleanup.set_defaults(func=cmd_cleanup)

    sp_backup = sub.add_parser("backup-browsers", help="Backup browser profiles to a folder.")

    sp_backup.add_argument("--outdir", default=argparse.SUPPRESS, help="Output dir for reports (default: current).")
    sp_backup.add_argument("--dest", default=r"D:\Backups\Browsers", help="Destination folder (default: D:\\Backups\\Browsers).")
    sp_backup.add_argument("--kill-browsers", action="store_true", help="Kill Edge/Yandex/Opera processes before backup (recommended).")
    sp_backup.add_argument("--best-effort", action="store_true", help="Continue even if some files are locked; skipped files will be reported.")
    sp_backup.set_defaults(func=cmd_backup)

    sp_wu = sub.add_parser("winupdate-cache", help="Reset Windows Update download cache (admin recommended).")

    sp_wu.add_argument("--outdir", default=argparse.SUPPRESS, help="Output dir for reports (default: current).")
    sp_wu.add_argument("--yes", action="store_true", help="Execute (otherwise dry-run).")
    sp_wu.set_defaults(func=cmd_winupdate_cache)

    sp_trim = sub.add_parser("trim", help="Run SSD TRIM (Optimize-Volume) for a drive (admin required).")

    sp_trim.add_argument("--outdir", default=argparse.SUPPRESS, help="Output dir for reports (default: current).")
    sp_trim.add_argument("--drive", default="C", help="Drive letter (default C).")
    sp_trim.set_defaults(func=cmd_trim)

    args = ap.parse_args()
    if not hasattr(args, \"outdir\"):
        args.outdir = str(DEFAULT_OUTDIR)
    args.func(args)


if __name__ == "__main__":
    main()
