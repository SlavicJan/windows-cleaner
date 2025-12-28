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
- Add `--outdir <path>` to place JSON reports elsewhere; if omitted they land in `out/` next to the toolkit.
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







WinMaintain Toolkit: Руководство и Инструкции / User Guide & Instructions
Описание / Description

WinMaintain — это комплексный набор инструментов для обслуживания и очистки Windows 10/11. Он включает функции аудита дискового пространства, безопасной очистки кэшей и временных файлов, резервного копирования профилей браузеров и сбора логов для поддержки. Главная цель — предоставить понятный и безопасный способ привести систему в порядок без риска потерять важные данные.

WinMaintain is a comprehensive toolkit for maintaining and cleaning Windows 10/11 systems. It provides disk usage auditing, safe cleanup of caches and temporary files, browser profile backups, and log collection for support. The main goal is to offer a clear and safe way to tidy up your system without risking important data.

Предварительные условия / Preconditions

Свободное место: оставьте 20–30 ГБ свободного пространства на диске C. Обновления Windows любят «съедать» место.

Закройте браузеры: перед резервным копированием закройте Edge, Yandex, Opera и другие. Иначе скрипты будут пытаться завершить их сами.

Закройте приложение NVIDIA: если хотите удалить кэш NVIDIA App.

Права администратора: запуск некоторых функций требует «Запуск от имени администратора».

Быстрый старт для обычных пользователей / Quick Start for non‑technical users

Скачайте последнюю портативную сборку WinMaintain_Portable_{version}.zip со страницы Releases проекта и распакуйте её в удобную папку (например, D:\WinMaintain).

Дважды щёлкните toolkit/START_HERE.bat. Запускайте его от имени администратора для доступа к очистке системных каталогов.

Прочитайте строку окружения вверху меню. Она покажет версию Python, наличие прав администратора, состояние TPM/Secure Boot и свободное место на диске C (пример: Python=3.11 | Admin=Yes | TPM=No | SecureBoot=Yes | FreeC=12.5 GB).

Выберите пункт меню:

1) Показать информацию о системе / Show system information — выводит информацию о Windows и оборудовании.

2) Аудит диска / Run disk audit — анализирует, какие каталоги занимают место (Python должен быть установлен).

3) Быстрая очистка / Quick cleanup — удаляет безопасные кэши (темы, браузеры, временные файлы).

4) Полная очистка / Full cleanup — глубокая очистка Windows Update, установочных кэшей, пакетов NVIDIA (потребуются права администратора).

5) Резервное копирование браузеров / Backup browser profiles — создаёт копии профилей браузеров.

6) Сбор логов / Collect log files — собирает логи и файлы в одну папку/архив.

9) Просмотр отчёта об окружении / View environment report — открывает out\env_report.json и копирует его содержимое в буфер обмена.

0) Выход / Exit — завершает программу.

Если Python не установлен, пункты 2–4 будут помечены как «Disabled».

Использование для технических пользователей / Usage for technical users

Вы можете обойти графическое меню и вызывать компоненты напрямую:

Python‑скрипты / Python scripts

Аудит: python toolkit\win_maintain.py scan --outdir out

Быстрая очистка: python toolkit\win_maintain.py cleanup --quick --outdir out

Полная очистка: python toolkit\win_maintain.py cleanup --outdir out --yes

Резервное копирование браузеров: python toolkit\win_maintain.py backup-browsers --dest D:\Backups\Browsers

Сбор сессии: python toolkit\win_collect_session.py --dest D:\Backups\WinSession --zip

PowerShell‑аудит / PowerShell audit

Скрипт ps_toolkit\run_toolkit.ps1 проводит инвентаризацию и умеет запускать быстрые/полные очистки через PowerShell. Логи и JSON‑отчёты хранятся в toolkit\ps_toolkit\logs\YYYY-MM-DD\. Для получения отчёта по системе вы также можете запустить powershell -ExecutionPolicy Bypass -File toolkit\detect_env.ps1.

Выводы и места хранения / Output and logs

out\env_report.json — JSON‑отчёт об окружении (версия Python, права администратора, TPM, Secure Boot, свободное место).

out\ — Python‑сканер (win_maintain.py) сохраняет свои отчёты по умолчанию здесь (или в указанный --outdir).

toolkit\ps_toolkit\logs\YYYY-MM-DD\ — PowerShell‑аудит и очистка записывают сюда свои логи и JSON‑отчёты.

D:\Backups\WinSession — директория (и zip) для сессий, собранных win_collect_session.py.

Создание одного EXE через PyInstaller / Building a single EXE via PyInstaller

Проект уже имеет GitHub Actions workflow, который собирает один файл-сканер (WinMaintainScanner_{tag}.exe) из toolkit/win_maintain.py. Вы можете собрать его локально так:

Установите Python и установите PyInstaller: pip install pyinstaller.

Перейдите в корень репозитория: cd windows-cleaner.

Выполните команду:

pyinstaller --noconfirm --onefile toolkit/win_maintain.py --name WinMaintainScanner


Готовый WinMaintainScanner.exe появится в папке dist/. Этот exe запускает сканер без меню; чтобы использовать его, выполните WinMaintainScanner.exe scan или WinMaintainScanner.exe cleanup --quick.

Если нужно собрать полный «all‑in‑one» пакет с меню, можно использовать существующий скрипт build/build_portable.ps1 (Windows PowerShell) или написать собственный инсталлятор. Также можно оформить запрос на CodeX: указать, что требуется собрать единый exe, который включает START_HERE.bat как GUI, и добавить поддержку запуска PowerShell‑команд.

Создание и описание релиза / Release creation and description

Функция CI публикует портативный ZIP и exe на страницу релизов при пуше тега. Вы можете добавить описание релиза в файле CHANGELOG.md и затем создать тег вида v1.0.0:

git tag -a v1.0.0 -m "WinMaintain v1.0.0: unified entry point, environment detection, portable zip and EXE"
git push origin v1.0.0


После этого GitHub Actions соберёт WinMaintain_Portable_v1.0.0.zip и WinMaintainScanner_v1.0.0.exe и выложит их на страницу Releases.

Важные примечания / Important notes

В текущем исходном коде осталась синтаксическая ошибка в toolkit/win_maintain.py (неправильный вызов add_argument для --outdir), из-за которой Python‑скрипт падает. Перед использованием исправьте её, как описано в отдельном промте.

Не выполняйте команду clean в PowerShell без контекста — эта команда существует только в утилите diskpart и может полностью очистить диск. Для очистки экрана используйте cls или Clear-Host.

Этот документ предназначен для пользователей и разработчиков WinMaintain, чтобы облегчить запуск, настройку и сборку проекта.