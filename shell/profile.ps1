$env:STARSHIP_CONFIG = Join-Path $HOME '.config\starship.toml'

if (-not $env:YAZI_FILE_ONE) {
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $gitCommand) {
        $gitRoot = Resolve-Path (Join-Path (Split-Path -Parent $gitCommand.Source) '..') | Select-Object -ExpandProperty Path
        $fileExe = Join-Path $gitRoot 'usr\bin\file.exe'
        if (Test-Path -LiteralPath $fileExe) {
            $env:YAZI_FILE_ONE = $fileExe
        }
    }
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& zoxide init powershell | Out-String)
}

function y {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())

    try {
        & yazi @args "--cwd-file=$tmp"

        if (Test-Path -LiteralPath $tmp) {
            $cwd = [System.IO.File]::ReadAllText($tmp).Trim([char]0, [char]10, [char]13)
            if ($cwd -and (Test-Path -LiteralPath $cwd)) {
                Set-Location -LiteralPath $cwd
            }
        }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

Set-Alias -Name lzg -Value lazygit -ErrorAction SilentlyContinue
