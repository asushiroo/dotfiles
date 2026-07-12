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

main() {
	git config --global diff.tool nvimdiff
	git config --global difftool.prompt false

	log_info "Git difftool configured: nvimdiff"
}

main "$@"
