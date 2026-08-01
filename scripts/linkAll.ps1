Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$scripts = @(
    (Join-Path $scriptRoot 'link\nvimLink.ps1'),
    (Join-Path $scriptRoot 'link\yaziLink.ps1'),
    (Join-Path $scriptRoot 'link\starshipLink.ps1'),
    (Join-Path $scriptRoot 'link\lazygitLink.ps1'),
    (Join-Path $scriptRoot 'link\codexSync.ps1')
)

foreach ($script in $scripts) {
    & $script
}
