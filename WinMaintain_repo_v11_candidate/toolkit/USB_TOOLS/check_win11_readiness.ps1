param(
  [string]$OutDir
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $OutDir -or $OutDir.Trim().Length -eq 0) {
  $OutDir = Join-Path $here "exports"
}

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$computer = $env:COMPUTERNAME
$outTxt = Join-Path $OutDir ("win11_readiness_{0}_{1}.txt" -f $computer, $ts)
$outJson = Join-Path $OutDir ("win11_readiness_{0}_{1}.json" -f $computer, $ts)

function SafeTry($ScriptBlock) {
  try { & $ScriptBlock } catch { $null }
}

$os = SafeTry { Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber, WindowsEditionId, BiosFirmwareType, CsManufacturer, CsModel }
$bootMode = $os.BiosFirmwareType

$secureBoot = $null
$secureBootErr = $null
try {
  $secureBoot = Confirm-SecureBootUEFI
} catch {
  $secureBootErr = $_.Exception.Message
}

$tpm = $null
try {
  $tpm = Get-Tpm
} catch {
  $tpm = $null
}

$sysDrive = (Get-PSDrive -Name C -ErrorAction SilentlyContinue)
$freeGB = if ($sysDrive) { [math]::Round($sysDrive.Free/1GB,2) } else { $null }
$totalGB = if ($sysDrive) { [math]::Round($sysDrive.Used/1GB + $sysDrive.Free/1GB,2) } else { $null }

# Disk partition style for the system disk
$systemDisk = $null
$partitionStyle = $null
try {
  $systemDisk = Get-Disk | Where-Object IsSystem -eq $true | Select-Object -First 1
  if ($systemDisk) { $partitionStyle = $systemDisk.PartitionStyle }
} catch { }

# CPU 64-bit
$cpu64 = $null
try {
  $cpu64 = (Get-CimInstance Win32_Processor | Select-Object -First 1).AddressWidth -eq 64
} catch { }

# RAM
$ramGB = $null
try {
  $ramBytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
  $ramGB = [math]::Round($ramBytes/1GB,2)
} catch { }

# Verdict logic (best-effort)
$checks = @()
$checks += [pscustomobject]@{ Name="CPU 64-bit"; Value=$cpu64; Pass=($cpu64 -eq $true) }
$checks += [pscustomobject]@{ Name="RAM >= 4 GB"; Value=$ramGB; Pass=($ramGB -ge 4) }
$checks += [pscustomobject]@{ Name="Free C: >= 25 GB"; Value=$freeGB; Pass=($freeGB -ge 25) }
$checks += [pscustomobject]@{ Name="UEFI boot"; Value=$bootMode; Pass=($bootMode -match "Uefi") }
$checks += [pscustomobject]@{ Name="Secure Boot enabled"; Value=$secureBoot; Pass=($secureBoot -eq $true) }
$checks += [pscustomobject]@{ Name="TPM present"; Value=($tpm.TpmPresent); Pass=($tpm -and $tpm.TpmPresent) }
$checks += [pscustomobject]@{ Name="Disk GPT (system)"; Value=$partitionStyle; Pass=($partitionStyle -eq "GPT") }

$failCount = ($checks | Where-Object { -not $_.Pass }).Count
$verdict = if ($failCount -eq 0) { "READY" } else { "NOT READY" }

$result = [pscustomobject]@{
  Generated = (Get-Date).ToString("s")
  Host = $computer
  Admin = ([bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
  OS = $os
  SystemDrive = [pscustomobject]@{ TotalGB=$totalGB; FreeGB=$freeGB }
  SystemDisk = $systemDisk
  SecureBoot = [pscustomobject]@{ Enabled=$secureBoot; Error=$secureBootErr }
  TPM = $tpm
  Checks = $checks
  Verdict = $verdict
}

# Write files
$result | ConvertTo-Json -Depth 6 | Set-Content -Path $outJson -Encoding UTF8
$lines = @()
$lines += "=== Windows 11 Readiness (portable) ==="
$lines += "Generated: $($result.Generated)"
$lines += "Host: $computer"
$lines += "Admin: $($result.Admin)"
$lines += ""
$lines += "--- OS ---"
$lines += "$($os.WindowsProductName) | Version: $($os.WindowsVersion) | Build: $($os.OsBuildNumber) | EditionId: $($os.WindowsEditionId)"
$lines += "Firmware: $($os.BiosFirmwareType) | Manufacturer/Model: $($os.CsManufacturer) $($os.CsModel)"
$lines += ""
$lines += "--- System Drive (C:) ---"
$lines += "Total: $totalGB GB | Free: $freeGB GB"
$lines += ""
$lines += "--- Secure Boot ---"
$lines += "Enabled: $secureBoot"
if ($secureBootErr) { $lines += "Note: $secureBootErr" }
$lines += ""
$lines += "--- TPM ---"
if ($tpm) {
  $lines += "Present: $($tpm.TpmPresent) | Ready: $($tpm.TpmReady) | Enabled: $($tpm.TpmEnabled) | Activated: $($tpm.TpmActivated)"
} else {
  $lines += "TPM info unavailable (Get-Tpm failed)."
}
$lines += ""
$lines += "--- Checks ---"
foreach ($c in $checks) {
  $mark = if ($c.Pass) { "PASS" } else { "FAIL" }
  $lines += ("[{0}] {1}: {2}" -f $mark, $c.Name, $c.Value)
}
$lines += ""
$lines += "Verdict: $verdict"
$lines | Set-Content -Path $outTxt -Encoding UTF8

Write-Host "Saved:"
Write-Host " - $outTxt"
Write-Host " - $outJson"
Start-Process explorer.exe $OutDir | Out-Null
