#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host ("=" * 78)
    Write-Host $Title
    Write-Host ("=" * 78)
}

function Test-Admin {
    try {
        return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    } catch { return $false }
}

function Ensure-LogDir([string]$LogDir) {
    if (-not $LogDir) { throw "LogDir is empty" }
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
}

function Start-ToolkitTranscript([string]$LogDir, [string]$Prefix) {
    Ensure-LogDir $LogDir
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $cn = $env:COMPUTERNAME
    $path = Join-Path $LogDir ("{0}_{1}_{2}.txt" -f $Prefix, $cn, $ts)
    try { Start-Transcript -Path $path -Force | Out-Null } catch { }
    return $path
}

function Stop-ToolkitTranscript {
    try { Stop-Transcript | Out-Null } catch { }
}

function Get-FreeGB([string]$DriveLetter = "C") {
    try {
        return [math]::Round((Get-PSDrive $DriveLetter).Free/1GB, 2)
    } catch { return $null }
}

function Safe-Remove([string]$PathToRemove) {
    if (-not $PathToRemove) { return }
    try {
        if (Test-Path $PathToRemove) {
            Remove-Item -Recurse -Force $PathToRemove -ErrorAction SilentlyContinue
        }
    } catch { }
}

function Safe-RemoveChildren([string]$Folder) {
    if (-not $Folder) { return }
    try {
        if (Test-Path $Folder) {
            Safe-Remove (Join-Path $Folder "*")
        }
    } catch { }
}

function Stop-ServiceSafe([string]$Name) {
    try { net stop $Name | Out-Host } catch { }
}

function Start-ServiceSafe([string]$Name) {
    try { net start $Name | Out-Host } catch { }
}

function Write-Json([object]$Obj, [string]$Path) {
    try {
        $Obj | ConvertTo-Json -Depth 6 | Set-Content -Path $Path -Encoding UTF8
    } catch { }
}
