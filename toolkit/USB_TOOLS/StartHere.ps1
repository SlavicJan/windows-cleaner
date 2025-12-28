param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$bat = Join-Path $here "StartHere.bat"

if (-not (Test-Path $bat)) {
  Write-Host "StartHere.bat not found: $bat"
  exit 1
}

Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$bat`"" -WorkingDirectory $here -Wait
