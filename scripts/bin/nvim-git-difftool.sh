#!/usr/bin/env bash

set -euo pipefail

local_file="${1:?missing LOCAL file}"
remote_file="${2:?missing REMOTE file}"

export NVIM_GIT_TOOL="difftool"
export NVIM_GIT_WINDOW_LABELS=$'LOCAL\nREMOTE'
export NVIM_GIT_WINDOW_FILES="$(printf '%s\n%s' "$local_file" "$remote_file")"

exec nvim -d -R "$local_file" "$remote_file"
