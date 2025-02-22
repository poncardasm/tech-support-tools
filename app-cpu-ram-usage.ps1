# Description: Get the top 10 processes by CPU and RAM usage

Get-Process | Group-Object -Property Name | ForEach-Object {
  [PSCustomObject]@{
      Name      = $_.Name
      'CPU(s)'  = [math]::Round(($_.Group | Measure-Object CPU -Sum).Sum, 2)
      'RAM (MB)' = [math]::Round(($_.Group | Measure-Object WorkingSet -Sum).Sum / 1MB, 2)
  }
} | Sort-Object 'CPU(s)' -Descending | Select-Object -First 10