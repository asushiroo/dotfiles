param(
    [Parameter(Mandatory = $true)][string]$Local,
    [Parameter(Mandatory = $true)][string]$Remote
)

$env:NVIM_GIT_TOOL = 'difftool'
$env:NVIM_GIT_WINDOW_LABELS = "LOCAL`nREMOTE"
$env:NVIM_GIT_WINDOW_FILES = "$Local`n$Remote"

& nvim -d -R -- $Local $Remote
exit $LASTEXITCODE
