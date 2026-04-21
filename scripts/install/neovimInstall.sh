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

log_warn() {
	log_msg "warn" "$*"
}

log_error() {
	log_msg "error" "$*" >&2
}

minimum_tree_sitter_cli_version="0.26.1"
cargo_domestic_sparse_index="sparse+https://rsproxy.cn/index/"
rustup_upstream_script_url="https://sh.rustup.rs"
rustup_domestic_script_url="https://rsproxy.cn/rustup-init.sh"
rustup_domestic_dist_server="https://rsproxy.cn"
rustup_domestic_update_root="https://rsproxy.cn/rustup"
npm_domestic_registry="https://registry.npmmirror.com"
nvm_domestic_node_mirror="https://npmmirror.com/mirrors/node"

required_formulae=(
	neovim
	ripgrep
	fd
	fzf
	zoxide
	cmake
	imagemagick
	librsvg
	node
)

ubuntu_packages_for_tree_sitter=(
	build-essential
	pkg-config
	clang
	libclang-dev
)

resolve_brew_bin() {
	if command -v brew >/dev/null 2>&1; then
		command -v brew
		return 0
	fi

	for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
		if [[ -x "$candidate" ]]; then
			echo "$candidate"
			return 0
		fi
	done

	log_error "Homebrew not found. Please run the Homebrew install script first."
	return 1
}

load_brew_env() {
	local brew_bin
	brew_bin="$(resolve_brew_bin)"
	eval "$("$brew_bin" shellenv)"
}

load_nvm_if_available() {
	export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

	if [[ -s "$NVM_DIR/nvm.sh" ]]; then
		# shellcheck disable=SC1090
		. "$NVM_DIR/nvm.sh"
		return 0
	fi

	return 1
}

load_cargo_env_if_available() {
	if [[ -f "$HOME/.cargo/env" ]]; then
		# shellcheck disable=SC1090
		. "$HOME/.cargo/env"
		return 0
	fi

	return 1
}

run_rustup_installer() {
	local script_url="$1"
	shift

	local rustup_script
	rustup_script="$(mktemp)"
	curl --proto '=https' --tlsv1.2 -sSf "$script_url" -o "$rustup_script"
	sh "$rustup_script" "$@"
	local status=$?
	rm -f "$rustup_script"
	return "$status"
}

run_nvm_install_lts() {
	if nvm install --lts; then
		return 0
	fi

	log_warn "Node.js LTS install failed with upstream source, retrying with domestic mirror..."
	NVM_NODEJS_ORG_MIRROR="$nvm_domestic_node_mirror" nvm install --lts
}

run_npm_command() {
	if npm "$@"; then
		return 0
	fi

	log_warn "npm command failed with upstream registry, retrying with domestic mirror..."
	npm --registry "$npm_domestic_registry" "$@"
}

run_as_root() {
	if [[ "$(id -u)" -eq 0 ]]; then
		"$@"
	else
		sudo "$@"
	fi
}

install_ubuntu_packages_if_needed() {
	if [[ "$(uname -s)" != "Linux" ]] || [[ ! -r /etc/os-release ]]; then
		return 0
	fi

	# shellcheck disable=SC1091
	. /etc/os-release

	if [[ "${ID:-}" != "ubuntu" ]] && [[ "${ID_LIKE:-}" != *ubuntu* ]]; then
		return 0
	fi

	local package
	local missing_packages=()

	for package in "${ubuntu_packages_for_tree_sitter[@]}"; do
		if dpkg -s "$package" >/dev/null 2>&1; then
			continue
		fi
		missing_packages+=("$package")
	done

	if [[ "${#missing_packages[@]}" -eq 0 ]]; then
		log_info "Ubuntu packages for tree-sitter build are already installed"
		return 0
	fi

	log_info "Installing Ubuntu packages: ${missing_packages[*]}"
	run_as_root apt-get update
	run_as_root apt-get install -y "${missing_packages[@]}"
}

install_formulae_if_needed() {
	local formula
	local missing_formulae=()

	for formula in "${required_formulae[@]}"; do
		if brew list --versions "$formula" >/dev/null 2>&1; then
			log_info "Already installed: $formula"
			continue
		fi

		missing_formulae+=("$formula")
	done

	if [[ "${#missing_formulae[@]}" -eq 0 ]]; then
		log_info "All Neovim-related Homebrew dependencies are already installed"
		return 0
	fi

	log_info "Installing formulae: ${missing_formulae[*]}"
	brew install "${missing_formulae[@]}"
}

ensure_npm_available() {
	if command -v npm >/dev/null 2>&1; then
		return 0
	fi

	load_nvm_if_available || true

	if command -v npm >/dev/null 2>&1; then
		return 0
	fi

	if command -v nvm >/dev/null 2>&1; then
		log_info "Installing Node.js LTS via nvm (upstream source first)..."
		if run_nvm_install_lts; then
			nvm use --lts >/dev/null
		fi
	fi

	if command -v npm >/dev/null 2>&1; then
		return 0
	fi

	log_error "npm not found. Please install Node.js with nvm first."
	return 1
}

resolve_repo_root() {
	local script_source script_dir
	script_source="${BASH_SOURCE[0]}"

	while [[ -L "$script_source" ]]; do
		script_source="$(readlink "$script_source")"
	done

	script_dir="$(cd "$(dirname "$script_source")" && pwd)"

	if [[ -f "$script_dir/../../.git/config" ]]; then
		(cd "$script_dir/../.." && pwd)
		return 0
	fi

	if command -v git >/dev/null 2>&1; then
		if git -C "$script_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
			git -C "$script_dir" rev-parse --show-toplevel
			return 0
		fi
	fi

	if [[ -d "$HOME/.config/dotfiles/.git" ]]; then
		echo "$HOME/.config/dotfiles"
		return 0
	fi

	log_error "Failed to resolve dotfiles repository root from $script_source"
	return 1
}

mdmath_mathjax_is_healthy() {
	local mdmath_js_dir="$1"

	[[ -f "$mdmath_js_dir/package.json" ]] || return 1
	[[ -f "$mdmath_js_dir/node_modules/mathjax/package.json" ]] || return 1

	(
		cd "$mdmath_js_dir"
		node --input-type=module -e "await import('mathjax')"
	) >/dev/null 2>&1
}

ensure_cargo_available() {
	if command -v cargo >/dev/null 2>&1; then
		return 0
	fi

	load_cargo_env_if_available || true

	if command -v cargo >/dev/null 2>&1; then
		return 0
	fi

	log_info "cargo not found, installing Rust toolchain via rustup..."
	if run_rustup_installer "$rustup_upstream_script_url" -y --profile minimal; then
		:
	else
		log_warn "Rust toolchain install failed with upstream source, retrying with domestic mirror..."
		RUSTUP_DIST_SERVER="$rustup_domestic_dist_server" \
			RUSTUP_UPDATE_ROOT="$rustup_domestic_update_root" \
			run_rustup_installer "$rustup_domestic_script_url" -y --profile minimal
	fi
	load_cargo_env_if_available

	if command -v cargo >/dev/null 2>&1; then
		return 0
	fi

	log_error "cargo is still unavailable after rustup installation."
	return 1
}

set_libclang_path_if_available() {
	local candidate

	if [[ -n "${LIBCLANG_PATH:-}" ]] && compgen -G "${LIBCLANG_PATH}/libclang.so*" >/dev/null; then
		return 0
	fi

	for candidate in \
		/usr/lib/llvm-*/lib \
		/usr/lib/x86_64-linux-gnu \
		/usr/lib64 \
		/usr/local/lib
	do
		if compgen -G "${candidate}/libclang.so*" >/dev/null; then
			export LIBCLANG_PATH="$candidate"
			log_info "Using LIBCLANG_PATH=$LIBCLANG_PATH"
			return 0
		fi
	done

	return 1
}

tree_sitter_is_healthy() {
	command -v tree-sitter >/dev/null 2>&1 && tree-sitter --version >/dev/null 2>&1 && version_gte "$(tree_sitter_version)" "$minimum_tree_sitter_cli_version"
}

tree_sitter_version() {
	tree-sitter --version | awk '{print $2}'
}

version_gte() {
	local current="$1"
	local expected="$2"
	[[ "$(printf '%s\n%s\n' "$expected" "$current" | sort -V | head -n 1)" == "$expected" ]]
}

ensure_mdmath_js_dependencies() {
	local repo_root mdmath_js_dir
	repo_root="$(resolve_repo_root)"
	mdmath_js_dir="$repo_root/nvim/vendor/mdmath.nvim/mdmath-js"

	if [[ ! -f "$mdmath_js_dir/package.json" ]]; then
		log_info "Skipping mdmath.js dependency install: package.json not found at $mdmath_js_dir"
		return 0
	fi

	ensure_npm_available

	if mdmath_mathjax_is_healthy "$mdmath_js_dir"; then
		log_info "mdmath.js dependency already installed: mathjax"
		return 0
	fi

	log_info "Installing/repairing mdmath.js dependencies (upstream registry first)..."
	(
		cd "$mdmath_js_dir"
		run_npm_command install --no-fund --no-audit
	)

	if mdmath_mathjax_is_healthy "$mdmath_js_dir"; then
		log_info "mdmath.js dependency is ready: mathjax"
		return 0
	fi

	log_error "mdmath.js dependency installation finished, but mathjax is still unavailable."
	return 1
}

install_tree_sitter_cli_with_npm() {
	ensure_npm_available
	log_info "Installing tree-sitter-cli via npm (upstream registry first)..."
	run_npm_command install -g tree-sitter-cli
}

install_tree_sitter_cli_with_cargo() {
	install_ubuntu_packages_if_needed
	ensure_cargo_available
	set_libclang_path_if_available || true
	if command -v npm >/dev/null 2>&1; then
		npm uninstall -g tree-sitter-cli >/dev/null 2>&1 || true
	fi
	log_info "Installing tree-sitter-cli via cargo (upstream source first)..."
	if cargo install tree-sitter-cli --locked --force; then
		return 0
	fi

	log_warn "tree-sitter-cli install failed with upstream cargo source, retrying with domestic mirror..."
	cargo install tree-sitter-cli --locked --force --index "$cargo_domestic_sparse_index"
}

install_tree_sitter_cli_if_needed() {
	if tree_sitter_is_healthy; then
		log_info "Already installed: tree-sitter-cli $(tree_sitter_version)"
		return 0
	fi

	if command -v tree-sitter >/dev/null 2>&1 && tree-sitter --version >/dev/null 2>&1; then
		log_warn "Detected tree-sitter-cli $(tree_sitter_version), but nvim-treesitter requires >= ${minimum_tree_sitter_cli_version}"
	fi

	if [[ "$(uname -s)" == "Linux" ]]; then
		log_info "Linux detected: install tree-sitter-cli from source to avoid GLIBC issues with npm prebuilt binaries"
		install_tree_sitter_cli_with_cargo
	else
		install_tree_sitter_cli_with_npm
	fi

	if tree_sitter_is_healthy; then
		log_info "tree-sitter-cli is ready: $(tree_sitter_version)"
		return 0
	fi

	log_error "tree-sitter-cli installation finished, but the executable is still unavailable."
	return 1
}

main() {
	load_brew_env
	install_formulae_if_needed
	ensure_mdmath_js_dependencies
	install_tree_sitter_cli_if_needed
	log_info "Neovim is ready: $(nvim --version | head -n 1)"
	log_info "Installed/checked brew dependencies: ${required_formulae[*]}"
	log_info "Installed/checked mdmath.js dependency"
	log_info "Installed/checked tree-sitter-cli dependency"
}

main "$@"
