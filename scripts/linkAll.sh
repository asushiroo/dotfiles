#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nvim_link_script="$script_dir/link/nvimLink.sh"
tmux_link_script="$script_dir/link/tmuxLink.sh"
ghostty_link_script="$script_dir/link/ghosttyLink.sh"
yazi_link_script="$script_dir/link/yaziLink.sh"

if [[ ! -f "$nvim_link_script" ]]; then
	echo "nvim link script not found: $nvim_link_script" >&2
	exit 1
fi

if [[ ! -f "$tmux_link_script" ]]; then
	echo "tmux link script not found: $tmux_link_script" >&2
	exit 1
fi

if [[ ! -f "$ghostty_link_script" ]]; then
	echo "ghostty link script not found: $ghostty_link_script" >&2
	exit 1
fi

if [[ ! -f "$yazi_link_script" ]]; then
	echo "yazi link script not found: $yazi_link_script" >&2
	exit 1
fi

echo "Running nvim link setup script..."
bash "$nvim_link_script"

echo "Running tmux link setup script..."
bash "$tmux_link_script"

echo "Running ghostty link setup script..."
bash "$ghostty_link_script"

echo "Running yazi link setup script..."
bash "$yazi_link_script"

echo "All link scripts completed."
