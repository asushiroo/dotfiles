# Windows setup

The `windows` branch is for local Windows development. It uses PowerShell and winget; Bash, tmux, and Ghostty files remain available for remote Linux hosts but are not run by the Windows setup script.

## Prerequisites

- Windows 10 or 11 with PowerShell and winget
- Developer Mode enabled, or an elevated terminal, to create symbolic links

## Initialize

```powershell
git clone <your-repo-url> $HOME\dotfiles
Set-Location $HOME\dotfiles
.\setup.ps1
```

If local script execution is restricted:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

## Managed tools

- Git, Neovim, Starship, Yazi, and Lazygit
- Neovim dependencies: ripgrep, fd, fzf, zoxide, and Node.js LTS
- Yazi dependencies: FFmpeg and jq

## Configuration locations

- Neovim: `%LOCALAPPDATA%\nvim`
- Yazi: `%APPDATA%\yazi\config`
- Starship: `$HOME\.config\starship.toml`
- Lazygit: `%LOCALAPPDATA%\lazygit\config.yml`
- Codex: `$HOME\.codex`

## Individual scripts

```powershell
.\scripts\install\gitInstall.ps1
.\scripts\install\lazygitInstall.ps1
.\scripts\install\gitConfig.ps1
.\scripts\link\lazygitLink.ps1
```
