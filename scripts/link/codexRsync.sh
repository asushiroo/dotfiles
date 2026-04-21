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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

SOURCE="$REPO_DIR/.codex"
TARGET="$HOME/.codex"

DRY_RUN="${DRY_RUN:-false}"

run() {
	if [ "$DRY_RUN" = true ]; then
		log_msg "dry-run" "$*"
	else
		eval "$@"
	fi
}

[ -d "$SOURCE" ] || {
	log_error "未找到源目录: $SOURCE"
	exit 1
}

mkdir -p "$TARGET"

log_info "使用 rsync 同步 .codex 配置"

FLAGS="-av"
[ "$DRY_RUN" = true ] && FLAGS="$FLAGS --dry-run"
FLAGS="$FLAGS --backup --suffix=.bak"

log_info "执行: rsync $FLAGS \"$SOURCE/\" \"$TARGET/\""

run "rsync $FLAGS \"$SOURCE/\" \"$TARGET/\""

log_info "同步完成 ✔"
