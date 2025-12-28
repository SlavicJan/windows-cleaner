
# Сборка Python Scanner в EXE (PyInstaller onedir)

## Требования
- Windows 10/11 x64
- Python 3.11–3.13 (на ПК сборки)
- PyInstaller
- Иконка: `assets\icons\app.ico`

## 1) Виртуальное окружение
PowerShell:
```powershell
cd D:\Dev\WinMaintain\python_app
py -3.13 -m venv .venv
.\.venv\Scripts\pip install -U pip pyinstaller
```

## 2) Сборка onedir
```powershell
.\.venv\Scripts\pyinstaller `
  -D -n WinMaintainScanner `
  --clean --noconfirm `
  --icon ..\assets\icons\app.ico `
  win_maintain.py
```

## 3) Важно про out/logs
EXE должен писать результаты рядом с собой или в `%LOCALAPPDATA%\WinMaintain\out`.
