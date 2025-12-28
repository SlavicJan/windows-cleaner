# Win Maintain Pack v3 (Windows 10/11)

Набор для **диагностики + безопасной очистки** Windows.

## Как запускать (самый простой путь)
Распакуй архив в папку, например: `D:\win_maintain_pack_v3`.

Дальше запускай BAT из этой папки:
- **01_scan.bat** — отчёт: где место / что крупное
- **02_cleanup_dryrun.bat** — «что будет удалено» (без удаления)
- **03_cleanup_execute.bat** — реальная очистка (**желательно запуск от Админа**)
- **04_cleanup_browser_caches.bat** — чистка кэшей браузеров (закрой браузеры)
- **05_cleanup_nvidia_app_cache.bat** — чистка кэша NVIDIA app (закрой NVIDIA app)
- **06_backup_browsers.bat** — бэкап профилей браузеров (лучше закрыть браузеры)
- **07_collect_session_zip.bat** — собрать всё в один zip-архив (логи + отчёты)

## Запуск вручную (если любишь терминал)
Открой PowerShell/Terminal в папке архива и выполняй:

```powershell
python .\win_maintain.py --outdir . scan
python .\win_maintain.py --outdir . cleanup           # dry-run
python .\win_maintain.py --outdir . cleanup --yes     # реально
python .\win_maintain.py backup-browsers --dest D:\Backups\Browsers --kill-browsers
python .\win_maintain.py winupdate-cache --yes
python .\win_collect_session.py --outdir D:\Backups\WinSession
```

> В v3 `--outdir` понимается **и до, и после** команды.

## Важно про бэкап браузеров
- Чтобы скопировались **Cookies / сессии**, браузеры должны быть закрыты (или используй `--kill-browsers`).
- Пароли/куки обычно шифруются Windows (DPAPI). После **чистой переустановки Windows** перенос «просто копированием папки» часто не расшифруется. Для миграции между установками лучше:
  - включить Sync (Edge/Yandex/Opera)
  - экспортировать пароли (CSV) и закладки.

## Что НЕ делает этот пак
- Не «ускоряет» Windows магией. Он просто чистит мусор/кэши и даёт отчёты.
- Не удаляет драйвера/системные файлы без твоего действия.

## Added: PowerShell cleanup toolkit (ps_toolkit)

This pack includes an updated PowerShell cleanup toolkit (v5) under `ps_toolkit/`.
- `08_ps_audit_only.bat` — audit only (safe, opens log folder)
- `09_ps_full_cleanup_admin.bat` — full cleanup (requests Admin, opens log folder)
- `ps_toolkit/scripts/zip_today_logs.bat` — zip today's logs
