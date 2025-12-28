param()

# Environment detection script for WinMaintain.  This script gathers information
# about the current environment and writes a JSON report to the out\ folder.

# Initialize report object
$envReport = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    python_version = $null
    is_admin = $false
    tpm_enabled = $null
    secure_boot = $null
    free_space_gb = $null
}

# Detect administrator privileges
try {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $envReport.is_admin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {
    $envReport.is_admin = $false
}

# Detect Python version
try {
    $pyVersion = & python --version 2>$null
    if ($pyVersion) {
        # Example output: Python 3.11.5
        $parts = $pyVersion -split '\s+'
        if ($parts.Length -ge 2) { $envReport.python_version = $parts[1] }
    }
} catch {
    $envReport.python_version = $null
}

# Detect TPM presence (may fail on systems without the module)
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $envReport.tpm_enabled = $tpm.TpmPresent
} catch {
    $envReport.tpm_enabled = $null
}

# Detect Secure Boot status (supported only on UEFI systems)
try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    $envReport.secure_boot = $sb
} catch {
    $envReport.secure_boot = $null
}

# Detect free space on drive C
try {
    $drive = Get-PSDrive -Name C -ErrorAction Stop
    $envReport.free_space_gb = [math]::Round($drive.Free / 1GB, 2)
} catch {
    $envReport.free_space_gb = $null
}

# Build summary string for quick display
$py = if ($envReport.python_version) { $envReport.python_version } else { "No" }
$adm = if ($envReport.is_admin) { "Yes" } else { "No" }
$tpm = if ($envReport.tpm_enabled -eq $true) { "Yes" } elseif ($envReport.tpm_enabled -eq $false) { "No" } else { "Unknown" }
$sb  = if ($envReport.secure_boot -eq $true) { "Yes" } elseif ($envReport.secure_boot -eq $false) { "No" } else { "Unknown" }
$free = if ($envReport.free_space_gb) { $envReport.free_space_gb } else { "?" }
$envReport["summary"] = "Python=" + $py + " | Admin=" + $adm + " | TPM=" + $tpm + " | SecureBoot=" + $sb + " | FreeC=" + $free + "GB"

# Write JSON report to out\env_report.json
$scriptDir = Split-Path -Parent $PSCommandPath
$outDir = Join-Path $scriptDir "..\out" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $outDir) {
    $outDirPath = Join-Path (Split-Path -Parent $scriptDir) "out"
    New-Item -ItemType Directory -Force -Path $outDirPath | Out-Null
    $outDir = (Resolve-Path $outDirPath)
}
$reportPath = Join-Path $outDir "env_report.json"
$envReport | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8

# Output summary for the batch file to capture
$envReport.summary