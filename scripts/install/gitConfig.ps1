Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\windows\Common.ps1')

$repoRoot = Resolve-RepoRoot -ScriptRoot $PSScriptRoot
$diffToolScript = Join-Path $repoRoot 'scripts\bin\nvim-git-difftool.ps1'
$mergeToolScript = Join-Path $repoRoot 'scripts\bin\nvim-git-mergetool.ps1'
$powerShell = (Get-Command powershell.exe -ErrorAction Stop).Source

$diffCommand = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" "$LOCAL" "$REMOTE"' -f $powerShell, $diffToolScript
$mergeCommand = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" "$BASE" "$LOCAL" "$REMOTE" "$MERGED"' -f $powerShell, $mergeToolScript

& git config --global core.editor nvim
& git config --global sequence.editor nvim
& git config --global diff.tool nvimdiff
& git config --global difftool.prompt false
& git config --global difftool.nvimdiff.cmd $diffCommand
& git config --global merge.tool nvimdiff
& git config --global mergetool.prompt false
& git config --global mergetool.nvimdiff.cmd $mergeCommand

if ($LASTEXITCODE -ne 0) {
    throw 'Failed to configure Git editor/diff/merge tools.'
}

Write-Info 'Git editor/diff/merge tool configured: nvim + PowerShell nvimdiff bridge'
