
# Troubleshooting (RU)

## “Logs folder not found”
Сначала запусти Audit или Full cleanup, затем Zip logs/session.

## “Admin: False”
Ты запустил режим без UAC. Для Full cleanup нужен админ (UAC окно).

## “Освободилось мало”
Системные места уже чистые. Проверь:
- AppData (браузеры/Packages/IDE caches)
- OneDrive (локальные копии)
- JetBrains/VSCode/Cursor/Windsurf caches

## Браузеры не почистились полностью
Закрой Edge/Chrome/Yandex/Opera перед чисткой.

## Антивирус ругается на EXE/SFX
Возможны ложные срабатывания на single-file упаковки.
