param(
  [string]$LogDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs")
)

. (Join-Path $PSScriptRoot "lib\common.ps1")
Ensure-LogDir $LogDir
$transcript = Start-ToolkitTranscript -LogDir $LogDir -Prefix "cleanup_browsers"

Write-Section "30 - Browser caches (best-effort)"
Write-Host "Close browsers before running (Edge/Chrome/Yandex/Opera)."
Write-Host ("Free C: before (GB): {0}" -f (Get-FreeGB "C"))

$yandexPaths = @(
"$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Cache",
"$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Code Cache",
"$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\GPUCache",
"$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\ShaderCache"
)
Write-Host "Cleaning Yandex cache paths..."
$yandexPaths | ForEach-Object { Safe-Remove $_ }

$operaPaths = @(
"$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache",
"$env:LOCALAPPDATA\Opera Software\Opera Stable\Code Cache",
"$env:LOCALAPPDATA\Opera Software\Opera Stable\GPUCache",
"$env:APPDATA\Opera Software\Opera Stable\Cache",
"$env:APPDATA\Opera Software\Opera Stable\Code Cache",
"$env:APPDATA\Opera Software\Opera Stable\GPUCache"
)
Write-Host "Cleaning Opera cache paths..."
$operaPaths | ForEach-Object { Safe-Remove $_ }

$chromePaths = @(
"$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
"$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
"$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache",
"$env:LOCALAPPDATA\Google\Chrome\User Data\ShaderCache"
)
Write-Host "Cleaning Chrome cache paths (if installed)..."
$chromePaths | ForEach-Object { Safe-Remove $_ }

$edgePaths = @(
"$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
"$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
"$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache",
"$env:LOCALAPPDATA\Microsoft\Edge\User Data\ShaderCache"
)
Write-Host "Cleaning Edge cache paths..."
$edgePaths | ForEach-Object { Safe-Remove $_ }

Write-Host ("Free C: after (GB): {0}" -f (Get-FreeGB "C"))
Write-Host "Transcript saved to: $transcript"
Stop-ToolkitTranscript
