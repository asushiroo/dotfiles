# bash的初始化shell
# starship初始化
case $- in
*i*)
	[ "$TERM" != "dumb" ] && eval "$(starship init bash)"
	;;
esac
# zoxide初始化
eval "$(zoxide init bash)"

# yazi初始化
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd <"$tmp" || true
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

__dotfiles_osc52_copy() {
	local input encoded

	if [[ $# -gt 0 ]]; then
		input="$*"
	else
		input="$(cat)"
	fi

	encoded="$(printf '%s' "$input" | base64 | tr -d '\r\n')"

	if [[ -n "${TMUX:-}" ]]; then
		printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "$encoded"
	else
		printf '\033]52;c;%s\a' "$encoded"
	fi
}

ycopy() {
	local input

	if [[ $# -gt 0 ]]; then
		input="$*"
	else
		input="$(cat)"
	fi

	if command -v pbcopy >/dev/null 2>&1; then
		printf '%s' "$input" | pbcopy
		return 0
	fi

	if command -v xclip >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
		printf '%s' "$input" | xclip -selection clipboard
		return 0
	fi

	if [[ -n "${SSH_CONNECTION:-}" ]] || [[ -n "${TMUX:-}" ]]; then
		__dotfiles_osc52_copy "$input"
		return 0
	fi

	echo "No clipboard backend available (expected pbcopy, xclip, or OSC52)." >&2
	return 1
}

alias yc='ycopy'
