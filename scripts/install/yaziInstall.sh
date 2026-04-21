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

log_warn() {
	log_msg "warn" "$*"
}

log_error() {
	log_msg "error" "$*" >&2
}

common_formulae=(
	yazi
	ffmpeg
	ffmpegthumbnailer
	jq
	poppler
)

linux_formulae=(
	xclip
)

yazi_plugins=(
	"dedukun/relative-motions"
)

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

install_formulae_if_needed() {
	local formula
	local missing_formulae=()

	for formula in "$@"; do
		if brew list --versions "$formula" >/dev/null 2>&1; then
			log_info "Already installed: $formula"
			continue
		fi

		missing_formulae+=("$formula")
	done

	if [[ "${#missing_formulae[@]}" -eq 0 ]]; then
		log_info "All Yazi-related dependencies are already installed"
		return 0
	fi

	log_info "Installing formulae: ${missing_formulae[*]}"
	brew install "${missing_formulae[@]}"
}

install_yazi_plugins_if_possible() {
	local plugin

	if ! command -v ya >/dev/null 2>&1; then
		log_warn "Skipping Yazi plugin install because 'ya' is unavailable"
		return 0
	fi

	for plugin in "${yazi_plugins[@]}"; do
		log_info "Installing Yazi plugin: $plugin"
		if ! ya pkg add "$plugin"; then
			log_warn "Failed to install Yazi plugin: $plugin"
		fi
	done
}

print_runtime_notes() {
	log_info "Yazi is ready: $(yazi --version)"
	log_info "Tips: Use 'y' instead of 'yazi' to allow shell cwd sync after quit."
	log_info "Tips: relative-motions plugin is configured for motions like 3j / 12k / 10gg."
	log_info "Tips: xclip is installed for Linux X11 clipboard fallback."
}

main() {
	local formulae=("${common_formulae[@]}")

	load_brew_env

	if [[ "$(uname -s)" == "Linux" ]]; then
		formulae+=("${linux_formulae[@]}")
	fi

	install_formulae_if_needed "${formulae[@]}"
	install_yazi_plugins_if_possible
	print_runtime_notes
}

main "$@"
