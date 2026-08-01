#!/usr/bin/env bash

set -euo pipefail

base_file="${1:-}"
local_file="${2:?missing LOCAL file}"
remote_file="${3:?missing REMOTE file}"
merged_file="${4:?missing MERGED file}"

labels=("LOCAL")
files=("$local_file")
args=("$local_file")

if [[ -n "$base_file" ]]; then
	labels+=("BASE")
	files+=("$base_file")
	args+=("$base_file")
fi

labels+=("REMOTE" "MERGED")
files+=("$remote_file" "$merged_file")
args+=("$remote_file" "$merged_file")

export NVIM_GIT_TOOL="mergetool"
export NVIM_GIT_WINDOW_LABELS="$(printf '%s\n' "${labels[@]}")"
export NVIM_GIT_WINDOW_FILES="$(printf '%s\n' "${files[@]}")"

exec nvim -d "${args[@]}" -c '$wincmd w' -c 'wincmd J'
