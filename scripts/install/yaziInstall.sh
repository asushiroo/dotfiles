#!/usr/bin/env bash

set -euo pipefail

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

	echo "Homebrew not found. Please run the Homebrew install script first." >&2
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
			echo "Already installed: $formula"
			continue
		fi

		missing_formulae+=("$formula")
	done

	if [[ "${#missing_formulae[@]}" -eq 0 ]]; then
		echo "All Yazi-related dependencies are already installed"
		return 0
	fi

	echo "Installing formulae: ${missing_formulae[*]}"
	brew install "${missing_formulae[@]}"
}

print_runtime_notes() {
	echo
	echo "Yazi is ready: $(yazi --version)"
	echo "Tips:"
	echo "  - Use 'y' instead of 'yazi' to allow shell cwd sync after quit."
	echo "  - On remote Linux -> local macOS, clipboard sync prefers OSC52 through your terminal/tmux."
	echo "  - xclip is installed for Linux X11 clipboard fallback."
}

main() {
	local formulae=("${common_formulae[@]}")

	load_brew_env

	if [[ "$(uname -s)" == "Linux" ]]; then
		formulae+=("${linux_formulae[@]}")
	fi

	install_formulae_if_needed "${formulae[@]}"
	print_runtime_notes
}

main "$@"
