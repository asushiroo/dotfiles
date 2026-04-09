# zsh的初始化shell
# starship初始化
case $- in
*i*)
	[ "$TERM" != "dumb" ] && eval "$(starship init zsh)"
	;;
esac
# zoxide初始化
eval "$(zoxide init zsh)"
