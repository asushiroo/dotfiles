#!/usr/bin/env bash

set -euo pipefail

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

detect_platform_and_rc_file() {
	local os_name
	os_name="$(uname -s)"

	if [[ "$os_name" == "Darwin" ]]; then
		echo "macos:$HOME/.zshrc:zsh"
		return 0
	fi

	if [[ "$os_name" == "Linux" ]] && [[ -r /etc/os-release ]]; then
		# shellcheck disable=SC1091
		. /etc/os-release

		if [[ "${ID:-}" == "ubuntu" ]] || [[ "${ID_LIKE:-}" == *ubuntu* ]]; then
			echo "ubuntu:$HOME/.bashrc:bash"
			return 0
		fi
	fi

	echo "Unsupported system: $os_name" >&2
	return 1
}

install_starship_if_needed() {
	if brew list --versions starship >/dev/null 2>&1; then
		echo "Starship is already installed"
		return 0
	fi

	echo "Installing Starship via Homebrew..."
	brew install starship
}

ensure_starship_init_in_rc() {
	local init_snippet

	if [[ "$shell_name" == "zsh" ]]; then
		init_snippet='eval "$(starship init zsh)"'
	else
		init_snippet='eval "$(starship init bash)"'
	fi

	if grep -Fq "$init_snippet" "$rc_file" 2>/dev/null; then
		echo "Starship init already exists in $rc_file"
		return 0
	fi

	cat >>"$rc_file" <<EOF

case \$- in
  *i*)
    [ "\$TERM" != "dumb" ] && $init_snippet
    ;;
esac
EOF

	echo "Starship init appended to $rc_file"
}

main() {
	local platform_and_rc

	load_brew_env
	platform_and_rc="$(detect_platform_and_rc_file)"
	platform="${platform_and_rc%%:*}"
	rest="${platform_and_rc#*:}"
	rc_file="${rest%%:*}"
	shell_name="${rest##*:}"

	touch "$rc_file"

	install_starship_if_needed
	ensure_starship_init_in_rc

	echo "Starship is ready: $(starship --version)"
	echo "Shell profile configured: $rc_file"
}

main "$@"
