Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$scripts = @(
    (Join-Path $scriptRoot 'install\gitInstall.ps1'),
    (Join-Path $scriptRoot 'install\neovimInstall.ps1'),
    (Join-Path $scriptRoot 'install\starshipInstall.ps1'),
    (Join-Path $scriptRoot 'install\yaziInstall.ps1'),
    (Join-Path $scriptRoot 'install\lazygitInstall.ps1'),
    (Join-Path $scriptRoot 'install\gitConfig.ps1')
)

foreach ($script in $scripts) {
    & $script
}
