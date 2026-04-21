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

nvim_link_script="$script_dir/link/nvimLink.sh"
tmux_link_script="$script_dir/link/tmuxLink.sh"
yazi_link_script="$script_dir/link/yaziLink.sh"
starship_link_script="$script_dir/link/starshipLink.sh"
codex_rsync_script="$script_dir/link/codexRsync.sh"

if [[ ! -f "$nvim_link_script" ]]; then
	log_error "nvim link script not found: $nvim_link_script"
	exit 1
fi

if [[ ! -f "$tmux_link_script" ]]; then
	log_error "tmux link script not found: $tmux_link_script"
	exit 1
fi

if [[ ! -f "$yazi_link_script" ]]; then
	log_error "yazi link script not found: $yazi_link_script"
	exit 1
fi

if [[ ! -f "$starship_link_script" ]]; then
	log_error "starship link script not found: $starship_link_script"
	exit 1
fi

if [[ ! -f "$codex_rsync_script" ]]; then
	log_error "codex link script not found: $codex_rsync_script"
	exit 1
fi

log_info "Running nvim link setup script..."
bash "$nvim_link_script"

log_info "Running tmux link setup script..."
bash "$tmux_link_script"

log_info "Running yazi link setup script..."
bash "$yazi_link_script"

log_info "Running starship link setup script..."
bash "$starship_link_script"

log_info "Running codex link setup script..."
bash "$codex_rsync_script"

log_info "All link scripts completed."
