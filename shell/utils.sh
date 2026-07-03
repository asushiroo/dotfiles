alias lzg='lazygit'

cdf() {
	if [[ "$1" == "-i" ]]; then
		local dir
		dir=$(fd -t d . . --exclude .git | fzf --preview 'ls -la {}') && cd "$dir"
		return
	fi

	if [[ -z "$1" ]]; then
		echo "Usage: cdf <pattern>  或  cdf -i"
		return 1
	fi

	local pattern="$1"
	local dir=""

	for depth in $(seq 1 15); do
		dir=$(fd -t d -i --max-depth "$depth" --exclude .git "$pattern" . | head -n 1)
		if [[ -n "$dir" ]]; then
			cd "$dir"
			return
		fi
	done

	echo "No directory found matching: $pattern"
}

ide() {
	session="work"
	if ! tmux has-session -t "$session" 2>/dev/null; then
		# 1. 在后台创建会话
		tmux new-session -d -s "$session"

		# 2. 关键：先 attach 进去，利用 -c 参数在进入后立即执行布局命令
		# 这样 tmux 能拿到真实的窗口尺寸后再进行百分比切分
		tmux attach-session -t "$session" \; \
			run-shell "tmux split-window -h -p 20; \
                       tmux select-pane -t 0; \
                       tmux split-window -v -p 15; \
                       tmux select-pane -t 0"
	else
		tmux attach-session -t "$session"
	fi
}
