#!/usr/bin/env bash

set -euo pipefail

log_msg() {
	local level="$1"
	shift
	printf '[%s] %s\n' "$level" "$*"
}

log_info() {
	log_msg "info" "$*"
}

log_error() {
	log_msg "error" "$*" >&2
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
homebrew_install_script="$script_dir/install/homeBrewInstall.sh"
git_install_script="$script_dir/install/gitInstall.sh"
rsync_install_script="$script_dir/install/rsyncInstall.sh"
neovim_install_script="$script_dir/install/neovimInstall.sh"
starship_install_script="$script_dir/install/starshipInstall.sh"
yazi_install_script="$script_dir/install/yaziInstall.sh"
lazygit_install_script="$script_dir/install/lazygitInstall.sh"

if [[ ! -f "$homebrew_install_script" ]]; then
	log_error "Homebrew install script not found: $homebrew_install_script"
	exit 1
fi

if [[ ! -f "$git_install_script" ]]; then
	log_error "Git install script not found: $git_install_script"
	exit 1
fi

if [[ ! -f "$rsync_install_script" ]]; then
	log_error "rsync install script not found: $rsync_install_script"
	exit 1
fi

if [[ ! -f "$neovim_install_script" ]]; then
	log_error "Neovim install script not found: $neovim_install_script"
	exit 1
fi

if [[ ! -f "$starship_install_script" ]]; then
	log_error "Starship install script not found: $starship_install_script"
	exit 1
fi

if [[ ! -f "$yazi_install_script" ]]; then
	log_error "Yazi install script not found: $yazi_install_script"
	exit 1
fi

if [[ ! -f "$lazygit_install_script" ]]; then
	log_error "Lazygit install script not found: $lazygit_install_script"
	exit 1
fi

log_info "Running Homebrew setup script..."
bash "$homebrew_install_script"

log_info "Running Git setup script..."
bash "$git_install_script"

log_info "Running rsync setup script..."
bash "$rsync_install_script"

log_info "Running Neovim setup script..."
bash "$neovim_install_script"

log_info "Running Starship setup script..."
bash "$starship_install_script"

log_info "Running Yazi setup script..."
bash "$yazi_install_script"

log_info "Running Lazygit setup script..."
bash "$lazygit_install_script"

log_info "All install scripts completed."
