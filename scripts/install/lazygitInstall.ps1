Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\windows\Common.ps1')

Install-WingetPackageIfMissing -Id 'JesseDuffield.lazygit' -Commands @('lazygit') -Name 'Lazygit'
Write-Info "Lazygit is ready: $((& lazygit --version | Select-Object -First 1))"
