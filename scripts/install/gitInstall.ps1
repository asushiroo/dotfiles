Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\windows\Common.ps1')

Install-WingetPackageIfMissing -Id 'Git.Git' -Commands @('git') -Name 'Git'
Write-Info "Git is ready: $((& git --version))"
