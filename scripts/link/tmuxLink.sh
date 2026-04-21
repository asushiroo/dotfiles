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
SOURCE="$REPO_DIR/.tmux.conf"
TARGET="$HOME/.tmux.conf"

if [ ! -f "$SOURCE" ]; then
	log_error "未找到源文件: $SOURCE"
	exit 1
fi

if [ -L "$TARGET" ]; then
	rm "$TARGET"
elif [ -e "$TARGET" ]; then
	log_error "$TARGET 已存在且不是符号链接，请先手动处理后再重试。"
	exit 1
fi

ln -s "$SOURCE" "$TARGET"

log_info "已创建符号链接: $TARGET -> $SOURCE"
