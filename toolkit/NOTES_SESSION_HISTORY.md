# Windows cleaner project — session history (condensed)

This file is a practical timeline + what was learned, based on the console outputs you shared across chats.

## Current machine snapshot (as observed)
- Windows 10 Home 2009 (Build 19045)
- CPU: Intel Core i3-4170 (64-bit)
- RAM: ~12 GB
- Boot: UEFI, System disk GPT
- Secure Boot: NO
- TPM: not present / not enabled
- Disks: Disk0 SSD ~240GB split into C/D (same physical disk); Disk1 HDD ~160GB MBR

## Windows 11 readiness blockers (hard)
- Secure Boot disabled
- TPM not present/disabled
- (CPU generation is also typically unsupported officially for Win11)

## Space & cleanup actions performed
- Moved Downloads and other data off C:, reached ~30–32 GB free.
- Ran: powercfg -h off, DISM StartComponentCleanup, cleanmgr.
- Cleared Windows Update downloads cache (SoftwareDistribution\Download), TEMP, Recycle Bin.
- Audited heavy folders: AppData\Local (Yandex/Microsoft/Programs/Packages/JetBrains), Roaming (JetBrains/Windsurf/Opera).
- NVIDIA caches: optional cleanup; NVIDIA app UpdateFramework can accumulate OTA artifacts.

## Operational lessons
- Many system cleanups require Administrator (BITS/WUAUSERV service control).
- Browser backup fails on Cookies DB if browsers are running (WinError 32). Close browsers and kill processes before copying.
- PowerShell 'clean' is not a built-in command; use Ctrl+C if prompt shows '>>' due to incomplete pipeline.

## Recommended daily usage
Use LAUNCH_MENU.bat (RUN\) for guided workflow:
1) Scan
2) Cleanup (dry-run then execute)
3) Backup browsers
4) Collect session zip
5) PS toolkit audit/full cleanup

