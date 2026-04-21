# BREW镜像配置
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"

# BREW环境变量（仅 Linux 初始化）
if [[ "$(uname -s)" == "Linux" ]]; then
	if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	elif command -v brew >/dev/null 2>&1; then
		eval "$(brew shellenv)"
	fi
fi

# 软件环境变量
if [[ -f "$HOME/.cargo/env" ]]; then
	source "$HOME/.cargo/env"
fi
