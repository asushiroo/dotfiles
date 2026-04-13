ide() {
	session="work"
	if ! tmux has-session -t "$session" 2>/dev/null; then
		tmux new-session -d -s "$session"
		tmux split-window -h -p 20 -t "$session"
		tmux select-pane -t "$session:0.0"
		tmux split-window -v -p 15 -t "$session"
		tmux select-pane -t "$session:0.0"
	fi
	tmux attach-session -t "$session"
}
export -f ide
