# Windows Maintenance Pack (v7) — что запускать

## Быстрый сценарий “почистить и не сломать”
1) **LAUNCH_MENU.bat → [5] Audit only** (посмотрел, кто жрёт место)
2) **[6] Quick cleanup** (лучше запускать от администратора — батник сам спросит UAC)
3) Если нужно — **[4] Backup browsers** (перед радикальной чисткой/переездом)

## Для отчёта “готов ли к Win11”
- **[1] Python - Scan** и посмотри `RUN\reports\win11_readiness_*.txt/json`

## Если видишь ошибки “unrecognized arguments: --outdir”
Это бывает, когда `--outdir` передают **после** команды.
Правильно: `python win_maintain.py --outdir . scan`
Неправильно: `python win_maintain.py scan --outdir .`

(В этом паке BAT уже правильные.)

## Где логи
- PowerShell toolkit: `RUN\ps_toolkit\logs\YYYY-MM-DD\`
- Python отчёты: `RUN\reports\`

## Важно про браузеры
Пароли/куки в Chromium-браузерах часто **зашифрованы DPAPI** — при переносе на другой ПК могут не прочитаться.
Самый надёжный путь:
- включить синхронизацию аккаунта (Edge/Yandex/Opera),
- или экспортировать пароли из браузера в CSV (и хранить как секрет).

