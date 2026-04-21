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

resolve_brew_bin() {
	if command -v brew >/dev/null 2>&1; then
		command -v brew
		return 0
	fi

	for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
		if [[ -x "$candidate" ]]; then
			echo "$candidate"
			return 0
		fi
	done

	log_error "Homebrew not found. Please run the Homebrew install script first."
	return 1
}

load_brew_env() {
	local brew_bin
	brew_bin="$(resolve_brew_bin)"
	eval "$("$brew_bin" shellenv)"
}

install_rsync_if_needed() {
	if command -v rsync >/dev/null 2>&1; then
		log_info "rsync is already installed: $(rsync --version | head -n 1)"
		return 0
	fi

	log_info "Installing rsync via Homebrew..."
	brew install rsync
}

main() {
	load_brew_env
	install_rsync_if_needed

	log_info "rsync is ready: $(rsync --version | head -n 1)"
}

main "$@"
