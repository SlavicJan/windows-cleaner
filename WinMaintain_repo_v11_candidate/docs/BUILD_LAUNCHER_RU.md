
# Сборка .NET Launcher (один EXE с UI)

## Требования
- Windows 10/11 x64
- .NET 8 SDK
- Visual Studio Community (рекомендуется) или `dotnet` CLI
- 7-Zip (для сборки payload.zip)

## 1) Подготовить payload
Payload — это содержимое, которое будет распаковано лаунчером в:
`%LOCALAPPDATA%\WinMaintain\toolkit`

Рекомендуемый минимум:
- `USB_TOOLS\` (PowerShell toolkit + меню)

## 2) Собрать payload.zip
Пример (cmd):
```bat
cd D:\Dev\WinMaintain
rmdir /s /q dist\payload 2>nul
mkdir dist\payload
xcopy /E /I /Y toolkit\USB_TOOLS dist\payload\USB_TOOLS
"C:\Program Files\7-Zip\7z.exe" a -tzip -mx=9 dist\payload.zip .\dist\payload\*
```

## 3) Вшить payload.zip в проект
В Visual Studio:
- добавь `payload.zip` в проект
- Properties -> Build Action = **Embedded Resource**
- добавь `assets\icons\app.ico` как иконку приложения

## 4) Publish single-file self-contained
PowerShell:
```powershell
cd D:\Dev\WinMaintain\launcher\WinMaintainLauncher
dotnet publish -c Release -r win-x64 `
  /p:PublishSingleFile=true `
  /p:SelfContained=true `
  /p:IncludeAllContentForSelfExtract=true
```
