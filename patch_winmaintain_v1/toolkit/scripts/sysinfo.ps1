# sysinfo.ps1
# Outputs basic system information as JSON (safe/read-only)

$ErrorActionPreference = "Stop"

function Is-Admin {
  $current = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($current)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Try-SecureBoot {
  try {
    $v = Confirm-SecureBootUEFI -ErrorAction Stop
    return [bool]$v
  } catch {
    return $null
  }
}

function Try-TPM {
  try {
    $t = Get-Tpm -ErrorAction Stop
    return @{
      Present = [bool]$t.TpmPresent
      Ready   = [bool]$t.TpmReady
      Enabled = [bool]$t.TpmEnabled
      Activated = [bool]$t.TpmActivated
      ManagedAuthLevel = $t.ManagedAuthLevel
    }
  } catch {
    return $null
  }
}

$cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$fw = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control").PEFirmwareType
$fwMode = if ($fw -eq 2) { "UEFI" } elseif ($fw -eq 1) { "BIOS" } else { "Unknown" }

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$cs  = Get-CimInstance Win32_ComputerSystem | Select-Object -First 1
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  [PSCustomObject]@{
    Drive = $_.DeviceID
    FreeBytes = [int64]$_.FreeSpace
    SizeBytes = [int64]$_.Size
    FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
    SizeGB = [math]::Round($_.Size / 1GB, 2)
    FileSystem = $_.FileSystem
    VolumeName = $_.VolumeName
  }
}

$py = Get-Command python -ErrorAction SilentlyContinue
$pyVersion = $null
if ($py) {
  try { $pyVersion = (& python --version 2>&1).ToString().Trim() } catch {}
}

$payload = [PSCustomObject]@{
  Timestamp = (Get-Date).ToString("s")
  ComputerName = $env:COMPUTERNAME
  UserName = $env:USERNAME
  IsAdmin = (Is-Admin)

  Windows = [PSCustomObject]@{
    ProductName = $cv.ProductName
    DisplayVersion = $cv.DisplayVersion
    CurrentBuild = $cv.CurrentBuild
    UBR = $cv.UBR
    EditionID = $cv.EditionID
  }

  Firmware = [PSCustomObject]@{
    Mode = $fwMode
    SecureBootEnabled = (Try-SecureBoot)
  }

  TPM = (Try-TPM)

  Hardware = [PSCustomObject]@{
    CPU = $cpu.Name
    Cores = $cpu.NumberOfCores
    LogicalProcessors = $cpu.NumberOfLogicalProcessors
    RAMBytes = [int64]$cs.TotalPhysicalMemory
    RAMGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
  }

  Disks = $disks

  Python = [PSCustomObject]@{
    Exists = [bool]$py
    Version = $pyVersion
    Path = if ($py) { $py.Source } else { $null }
  }
}

$payload | ConvertTo-Json -Depth 6
