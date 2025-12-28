WinMaintain USB Pack (v1.1)

Что это:
- Полностью переносимый набор для обслуживания Windows 10/11 с флешки.
- Основная часть — PowerShell toolkit (чистка + логи + упаковка логов).
- Дополнительно — проверка готовности Windows 11 (PowerShell, best-effort).

Как пользоваться:
1) Скопируй папку USB_TOOLS целиком на флешку.
2) Запусти StartHere.bat (меню) ИЛИ AutoRun_Full_Then_Zip.bat (одна кнопка).
3) Для Quick/Full будет UAC запрос (админ). Это нормально.

Где логи:
- toolkit\cleanup_toolkit\logs\YYYY-MM-DD\
- Кнопка Zip logs создаёт ZIP рядом с тулкитом: toolkit\cleanup_toolkit\logs_...zip
- Если логов “сегодня” ещё нет — zip берёт последний доступный день.

Важно:
- Чистку кэшей браузеров лучше делать при закрытых браузерах.
- Если флешка медленная, запись логов будет чуть медленнее — это нормально.

Один EXE без Python:
- Самый практичный вариант: 7-Zip SFX (самораспаковывающийся .exe, который запускает StartHere.bat).
- Смотри: docs\BUILD_ONEFILE_EXE_RU.md или BUILD\sfx_onefile\make_sfx.bat
