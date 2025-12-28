# Шаги (рекомендованный порядок)

1) **Скан**
- Запусти `01_scan.bat`
- Посмотри отчёты в `out\`

2) **Dry‑run очистки**
- Запусти `02_cleanup_dryrun.bat`
- Если всё выглядит адекватно — переходи дальше.

3) **Очистка (Apply)**
- Запусти `03_cleanup_execute.bat` (лучше от Админа)

4) **Кэши браузеров** (если надо)
- Закрой Edge/Yandex/Opera → `04_cleanup_browser_caches.bat`

5) **NVIDIA app кэш** (если надо)
- Закрой NVIDIA app → `05_cleanup_nvidia_app_cache.bat`

6) **Бэкап браузеров** (перед большими чистками/переустановкой)
- `06_backup_browsers.bat`

7) **Сбор сессии в архив**
- `07_collect_session_zip.bat`
- Итоговый архив будет в `D:\Backups\WinSession\win_session_*.zip`
