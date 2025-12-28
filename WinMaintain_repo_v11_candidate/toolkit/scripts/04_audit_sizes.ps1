#requires -Version 5.1
Write-Host "[4/5] Size audit (top folders)" -ForegroundColor Cyan

function Top-Folders($root, $top=25) {
  Write-Host "--- $root ---" -ForegroundColor DarkCyan
  Get-ChildItem $root -Directory -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
      $sum = (Get-ChildItem $_.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum
      [pscustomobject]@{ Path=$_.FullName; GB=[math]::Round($sum/1GB,2) }
    } | Sort-Object GB -Descending | Select-Object -First $top
}

Top-Folders "$env:USERPROFILE\AppData\Local" 25
Top-Folders "$env:USERPROFILE\AppData\Roaming" 25
