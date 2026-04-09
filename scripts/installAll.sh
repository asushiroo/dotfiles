#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
homebrew_install_script="$script_dir/install/homeBrewInstall.sh"
neovim_install_script="$script_dir/install/neovimInstall.sh"
starship_install_script="$script_dir/install/starshipInstall.sh"

if [[ ! -f "$homebrew_install_script" ]]; then
	echo "Homebrew install script not found: $homebrew_install_script" >&2
	exit 1
fi

if [[ ! -f "$neovim_install_script" ]]; then
	echo "Neovim install script not found: $neovim_install_script" >&2
	exit 1
fi

if [[ ! -f "$starship_install_script" ]]; then
	echo "Starship install script not found: $starship_install_script" >&2
	exit 1
fi

echo "Running Homebrew setup script..."
bash "$homebrew_install_script"

echo "Running Neovim setup script..."
bash "$neovim_install_script"

echo "Running Starship setup script..."
bash "$starship_install_script"

echo "All install scripts completed."
