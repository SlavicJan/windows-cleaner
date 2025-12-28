param(
  [string]$LogDir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs")
)

. (Join-Path $PSScriptRoot "lib\common.ps1")
Ensure-LogDir $LogDir
$transcript = Start-ToolkitTranscript -LogDir $LogDir -Prefix "audit"

Write-Section "00 - Audit / Inventory"
Write-Host ("Admin: {0}" -f (Test-Admin))
Write-Host ("Free C: (GB): {0}" -f (Get-FreeGB "C"))

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$bios = Get-CimInstance Win32_BIOS

$secureBoot = $null
try { $secureBoot = Confirm-SecureBootUEFI } catch { $secureBoot = "UNKNOWN" }

$tpmPresent = $null
$tpmReady = $null
try {
  $tpm = Get-Tpm
  $tpmPresent = $tpm.TpmPresent
  $tpmReady = $tpm.TpmReady
} catch {
  $tpmPresent = "UNKNOWN"
  $tpmReady = "UNKNOWN"
}

$vols = @()
try {
  $vols = Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem,
    @{n="SizeGB";e={[math]::Round($_.Size/1GB,2)}},
    @{n="FreeGB";e={[math]::Round($_.SizeRemaining/1GB,2)}}
} catch { }

$result = [pscustomobject]@{
  Timestamp = (Get-Date).ToString("s")
  ComputerName = $env:COMPUTERNAME
  User = $env:USERNAME
  OS = [pscustomobject]@{
    Caption = $os.Caption
    Version = $os.Version
    BuildNumber = $os.BuildNumber
    Architecture = $os.OSArchitecture
  }
  Hardware = [pscustomobject]@{
    Manufacturer = $cs.Manufacturer
    Model = $cs.Model
    RAM_GB = [math]::Round($cs.TotalPhysicalMemory/1GB,2)
    CPU = $cpu.Name
    BIOS_Version = ($bios.SMBIOSBIOSVersion)
  }
  Security = [pscustomobject]@{
    SecureBoot = $secureBoot
    TPM_Present = $tpmPresent
    TPM_Ready = $tpmReady
  }
  Storage = [pscustomobject]@{
    FreeC_GB = (Get-FreeGB "C")
    Volumes = $vols
  }
}

$outJson = Join-Path $LogDir ("audit_{0}_{1}.json" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))
Write-Host "Writing audit JSON -> $outJson"
Write-Json $result $outJson

function Get-DirSizeBytes([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return 0 }
  $m = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
       Measure-Object -Property Length -Sum
  if ($null -eq $m -or -not ($m.PSObject.Properties.Name -contains "Sum") -or $null -eq $m.Sum) { return 0 }
  return [int64]$m.Sum
}

Write-Section "Top dirs in user profile (quick)"
try {
  $candidates = @(
    @{ Name = "LOCALAPPDATA"; Path = $env:LOCALAPPDATA },
    @{ Name = "APPDATA"; Path = $env:APPDATA },
    @{ Name = "TEMP"; Path = $env:TEMP }
  )

  $candidates |
    ForEach-Object {
      $sizeBytes = Get-DirSizeBytes -Path $_.Path
      [pscustomobject]@{
        Name = $_.Name
        Path = $_.Path
        SizeGB = [math]::Round($sizeBytes/1GB, 2)
      }
    } |
    Sort-Object SizeGB -Descending |
    Format-Table -AutoSize
} catch {
  Write-Host ("Top dirs skipped: {0}" -f $_.Exception.Message)
}

Write-Host ""
Write-Host "Transcript saved to: $transcript"
Stop-ToolkitTranscript
