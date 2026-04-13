alias ide='tmux new-session -d -s work 2>/dev/null; \
           tmux split-window -h -p 20 -t work; \
           tmux select-pane -t work:0.0; \
           tmux split-window -v -p 15 -t work; \
           tmux select-pane -t work:0.0; \
           tmux attach-session -t work'
