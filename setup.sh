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

resolve_repo_dir() {
	local script_source script_dir
	script_source="${BASH_SOURCE[0]}"

	while [[ -L "$script_source" ]]; do
		script_source="$(readlink "$script_source")"
	done

	script_dir="$(cd "$(dirname "$script_source")" && pwd)"
	echo "$script_dir"
}

select_shell_rc() {
	local shell_name
	shell_name="$(basename "${SHELL:-bash}")"

	case "$shell_name" in
	zsh)
		echo "$HOME/.zshrc"
		;;
	*)
		echo "$HOME/.bashrc"
		;;
	esac
}

ensure_shell_init() {
	local repo_dir shell_init rc_file source_line
	repo_dir="$1"
	shell_init="$repo_dir/shell/init.sh"
	rc_file="$(select_shell_rc)"
	source_line="source \"$shell_init\""

	mkdir -p "$(dirname "$rc_file")"
	touch "$rc_file"

	if grep -Fqx "$source_line" "$rc_file"; then
		log_info "Shell init already enabled in $rc_file"
		return 0
	fi

	if grep -Fq "$shell_init" "$rc_file"; then
		log_info "Shell init already referenced in $rc_file"
		return 0
	fi

	printf '\n# dotfiles shell init\n%s\n' "$source_line" >> "$rc_file"
	log_info "Added shell init to $rc_file"
}

main() {
	local repo_dir
	repo_dir="$(resolve_repo_dir)"

	log_info "Running install scripts..."
	bash "$repo_dir/scripts/installAll.sh"

	log_info "Ensuring shell init is loaded..."
	ensure_shell_init "$repo_dir"

	log_info "Running link scripts..."
	bash "$repo_dir/scripts/linkAll.sh"

	log_info "Setup completed."
	log_info "Please restart your shell or run: source \"$repo_dir/shell/init.sh\""
}

main "$@"
