param(
    [AllowEmptyString()][string]$Base,
    [Parameter(Mandatory = $true)][string]$Local,
    [Parameter(Mandatory = $true)][string]$Remote,
    [Parameter(Mandatory = $true)][string]$Merged
)

$labels = @('LOCAL')
$files = @($Local)
$arguments = @('-d', $Local)

if (-not [string]::IsNullOrWhiteSpace($Base)) {
    $labels += 'BASE'
    $files += $Base
    $arguments += $Base
}

$labels += 'REMOTE', 'MERGED'
$files += $Remote, $Merged
$arguments += $Remote, $Merged, '-c', 'wincmd w', '-c', 'wincmd J'

$env:NVIM_GIT_TOOL = 'mergetool'
$env:NVIM_GIT_WINDOW_LABELS = $labels -join "`n"
$env:NVIM_GIT_WINDOW_FILES = $files -join "`n"

& nvim @arguments
exit $LASTEXITCODE
