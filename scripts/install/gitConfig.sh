#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIFFTOOL_SCRIPT="$REPO_DIR/scripts/bin/nvim-git-difftool.sh"
MERGETOOL_SCRIPT="$REPO_DIR/scripts/bin/nvim-git-mergetool.sh"

log_msg() {
	local level="$1"
	shift
	printf '[%s] %s\n' "$level" "$*"
}

log_info() {
	log_msg "info" "$*"
}

main() {
	git config --global core.editor nvim
	git config --global sequence.editor nvim

	git config --global diff.tool nvimdiff
	git config --global difftool.prompt false
	git config --global difftool.nvimdiff.cmd "$DIFFTOOL_SCRIPT \"\$LOCAL\" \"\$REMOTE\""
	git config --global merge.tool nvimdiff
	git config --global mergetool.prompt false
	git config --global mergetool.nvimdiff.cmd "$MERGETOOL_SCRIPT \"\$BASE\" \"\$LOCAL\" \"\$REMOTE\" \"\$MERGED\""

	log_info "Git editor/diff/merge tool configured: nvim + custom nvimdiff bridge"
}

main "$@"
