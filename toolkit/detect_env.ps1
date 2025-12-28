[CmdletBinding()]
param()

# Environment detection script for WinMaintain.
# Collects environment details and writes them to out\env_report.json.

$ErrorActionPreference = 'Stop'

function Get-PythonVersion {
    try {
        $versionLine = & python --version 2>$null
        if (-not $versionLine) { return $null }
        $parts = $versionLine -split '\s+'
        if ($parts.Length -ge 2) { return $parts[1] }
    } catch {
        return $null
    }
    return $null
}

function Test-IsAdministrator {
    try {
        $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Get-TpmStatus {
    try {
        $tpm = Get-Tpm -ErrorAction Stop
        return $tpm.TpmPresent
    } catch {
        return $null
    }
}

function Get-SecureBootStatus {
    try {
        return (Confirm-SecureBootUEFI -ErrorAction Stop)
    } catch {
        return $null
    }
}

function Get-FreeSpaceGb {
    try {
        $drive = Get-PSDrive -Name C -ErrorAction Stop
        return [math]::Round($drive.Free / 1GB, 2)
    } catch {
        return $null
    }
}

$envReport = [ordered]@{
    generated_at   = (Get-Date).ToString('o')
    python_version = Get-PythonVersion
    is_admin       = Test-IsAdministrator
    tpm_enabled    = Get-TpmStatus
    secure_boot    = Get-SecureBootStatus
    free_space_gb  = Get-FreeSpaceGb
}

$py   = if ($envReport.python_version) { $envReport.python_version } else { 'No' }
$adm  = if ($envReport.is_admin) { 'Yes' } else { 'No' }
$tpm  = if ($envReport.tpm_enabled -eq $true) { 'Yes' } elseif ($envReport.tpm_enabled -eq $false) { 'No' } else { 'Unknown' }
$sb   = if ($envReport.secure_boot -eq $true) { 'Yes' } elseif ($envReport.secure_boot -eq $false) { 'No' } else { 'Unknown' }
$free = if ($envReport.free_space_gb -ne $null) { $envReport.free_space_gb } else { '?' }
$envReport['summary'] = "Python=$py | Admin=$adm | TPM=$tpm | SecureBoot=$sb | FreeC=$free GB"

# Ensure out/ folder exists one level above toolkit
$scriptDir = Split-Path -Parent $PSCommandPath
$outDir = Join-Path (Split-Path -Parent $scriptDir) 'out'
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$reportPath = Join-Path $outDir 'env_report.json'
$envReport | ConvertTo-Json -Depth 4 | Set-Content -Path $reportPath -Encoding UTF8

# Emit the summary for callers (batch menu) to display
Write-Output $envReport.summary
