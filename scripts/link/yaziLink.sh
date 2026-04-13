#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE="$REPO_DIR/yazi"
TARGET="$HOME/.config/yazi"

if [ ! -d "$SOURCE" ]; then
	echo "错误: 未找到源目录 $SOURCE"
	exit 1
fi

mkdir -p "$HOME/.config"

if [ -L "$TARGET" ]; then
	rm "$TARGET"
elif [ -e "$TARGET" ]; then
	echo "错误: $TARGET 已存在且不是符号链接，请先手动处理后再重试。"
	exit 1
fi

ln -s "$SOURCE" "$TARGET"

echo "已创建符号链接: $TARGET -> $SOURCE"
