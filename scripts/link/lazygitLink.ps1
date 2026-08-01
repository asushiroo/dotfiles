Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\windows\Common.ps1')

$repoRoot = Resolve-RepoRoot -ScriptRoot $PSScriptRoot
$source = Join-Path $repoRoot 'lazygit\config.yml'
$target = Join-Path $env:LOCALAPPDATA 'lazygit\config.yml'

if (-not (Test-Path -LiteralPath $source)) {
    throw "Source file not found: $source"
}

New-SafeSymbolicLink -Target $source -Path $target
