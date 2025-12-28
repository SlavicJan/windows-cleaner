# WinMaintain sysinfo
# Outputs JSON with system info to out\sysinfo_*.json (or prints to stdout if -OutFile not provided)
param(
  [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
  try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

function Get-UEFIType {
  # 1=BIOS, 2=UEFI
  try {
    $v = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction Stop).PEFirmwareType
    return [int]$v
  } catch { return $null }
}

function Get-SecureBoot {
  try {
    # Throws on BIOS systems
    return [bool](Confirm-SecureBootUEFI)
  } catch { return $null }
}

function Get-TPMInfo {
  $obj = [ordered]@{
    present = $null
    ready = $null
    enabled = $null
    activated = $null
    owned = $null
    manufacturer = $null
    manufacturerVersion = $null
    specVersion = $null
  }
  try {
    $t = Get-Tpm -ErrorAction Stop
    $obj.present = $t.TpmPresent
    $obj.ready = $t.TpmReady
    $obj.enabled = $t.TpmEnabled
    $obj.activated = $t.TpmActivated
    $obj.owned = $t.TpmOwned
    $obj.manufacturer = $t.ManufacturerIdTxt
    $obj.manufacturerVersion = $t.ManufacturerVersion
    $obj.specVersion = $t.SpecVersion
  } catch {
    # module missing / access denied
  }
  return $obj
}

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  [ordered]@{
    device = $_.DeviceID
    volumeName = $_.VolumeName
    size_gb = if ($_.Size) { [math]::Round($_.Size/1GB,2) } else { $null }
    free_gb = if ($_.FreeSpace) { [math]::Round($_.FreeSpace/1GB,2) } else { $null }
    free_pct = if ($_.Size -and $_.FreeSpace) { [math]::Round(100.0*$_.FreeSpace/$_.Size,1) } else { $null }
    fileSystem = $_.FileSystem
  }
}

$fwType = Get-UEFIType
$secureBoot = Get-SecureBoot
$isAdmin = Test-IsAdmin

$py = $null
try {
  $cmd = Get-Command python -ErrorAction Stop
  $py = $cmd.Source
} catch {}

$result = [ordered]@{
  timestamp = (Get-Date).ToString("s")
  computerName = $env:COMPUTERNAME
  userName = $env:USERNAME
  admin = $isAdmin

  os = [ordered]@{
    caption = $os.Caption
    version = $os.Version
    build = $os.BuildNumber
    arch = $os.OSArchitecture
    installDate = ($os.InstallDate).ToString("s")
    lastBoot = ($os.LastBootUpTime).ToString("s")
  }

  hardware = [ordered]@{
    manufacturer = $cs.Manufacturer
    model = $cs.Model
    ram_gb = [math]::Round($cs.TotalPhysicalMemory/1GB,2)
    cpu = [ordered]@{
      name = $cpu.Name
      cores = $cpu.NumberOfCores
      logicalProcessors = $cpu.NumberOfLogicalProcessors
      maxClockMHz = $cpu.MaxClockSpeed
    }
    bios = [ordered]@{
      vendor = $bios.Manufacturer
      version = $bios.SMBIOSBIOSVersion
      serial = $bios.SerialNumber
    }
  }

  firmware = [ordered]@{
    peFirmwareType = $fwType
    uefi = if ($fwType -eq 2) { $true } elseif ($fwType -eq 1) { $false } else { $null }
    secureBoot = $secureBoot
  }

  tpm = (Get-TPMInfo)

  disks = @($disks)

  python = [ordered]@{
    found = [bool]$py
    path = $py
  }
}

$json = $result | ConvertTo-Json -Depth 6

if ($OutFile -and $OutFile.Trim().Length -gt 0) {
  $dir = Split-Path -Parent $OutFile
  if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $json | Out-File -FilePath $OutFile -Encoding UTF8
  Write-Host "Saved: $OutFile"
} else {
  $json
}
