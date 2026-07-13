# asushiro-config-dotfile

一套面向远程开发场景的 dotfiles 仓库，核心目标是把本地终端、远程会话、编辑器、文件管理器和 Git UI 串成一套稳定工作流。

当前这套配置主要按下面的使用方式设计：

- 本地 `macOS`
- 本地终端使用 `Ghostty`
- 通过 `SSH` 连接远程 `Ubuntu`
- 远程会话通过 `tmux` 持久化
- 编辑器使用 `Neovim`
- 文件管理使用 `Yazi`
- Git TUI 使用 `Lazygit`

## 这套仓库解决什么问题

它不是单独给某一个工具写配置，而是把下面这些环节统一起来：

- 一键安装常用命令行工具和编辑器依赖
- 把 `nvim`、`yazi`、`starship`、`lazygit`、`tmux` 等配置链接到用户目录
- 自动把 shell 初始化挂到 `~/.zshrc` 或 `~/.bashrc`
- 为远程开发补上目录跳转、tmux 工作区、Yazi 回写 cwd 等辅助函数
- 针对 Markdown / LaTeX / 图片渲染补齐 Neovim 依赖
- 让本地 Ghostty、远程 tmux、远程 Neovim 尽量协同工作

## 自动化范围

`bash setup.sh` 会按顺序完成这些事情：

1. 运行安装脚本
2. 将 `source "<repo>/shell/init.sh"` 写入当前 shell 的 rc 文件
3. 链接仓库中的配置到用户目录

### 会自动安装的内容

- `Homebrew`（缺失时自动安装）
- `git`
- `rsync`
- `neovim`
- `starship`
- `yazi`
- `lazygit`
- Neovim 所需的一批依赖：`ripgrep`、`fd`、`fzf`、`zoxide`、`cmake`、`imagemagick`、`librsvg`、`node`
- Yazi 所需的一批依赖：`ffmpeg`、`ffmpegthumbnailer`、`jq`、`poppler`，Linux 下额外安装 `xclip`
- Git 全局 diff / merge 工具设置为 `nvimdiff`

### 会自动链接的内容

- `nvim` -> `~/.config/nvim`
- `yazi` -> `~/.config/yazi`
- `lazygit` -> `~/.config/lazygit`
- `starship.toml` -> `~/.config/starship.toml`
- `.tmux.conf` -> `~/.tmux.conf`
- `.codex` -> 通过 `rsync` 同步到 `~/.codex`，并保留 `.bak` 备份

### 不在 `setup.sh` 自动处理的内容

- `Ghostty` 只提供配置，不自动链接；如需启用，手动执行 `bash scripts/link/ghosttyLink.sh`
- `tmux` 配置会自动链接，但仓库当前没有 tmux 安装脚本；目标机器需要你自己先装好 `tmux`

## 主要功能

### 1. Shell 环境和辅助命令

入口是 `shell/init.sh`，会根据系统加载：

- `shell/env.sh`
- `shell/bashrc.sh` 或 `shell/zshrc.sh`
- `shell/utils.sh`

这部分主要提供以下能力：

- 自动初始化 `starship`
- 自动初始化 `zoxide`
- Linux 下自动注入 `brew shellenv`
- 如果存在 `~/.cargo/env`，自动加载 Rust 环境
- 预设 Homebrew / PyPI 国内镜像环境变量，降低安装失败概率

当前额外提供的 shell 命令：

- `y`
  不是直接执行 `yazi`，而是包了一层 cwd 同步逻辑。退出 Yazi 后，shell 当前目录会自动切换到你离开时所在的目录。
- `cdf <pattern>`
  从当前目录向下查找目录名，找到第一个匹配项后直接 `cd` 进去。
- `cdf -i`
  使用 `fd + fzf` 交互式选目录后进入。
- `ide`
  自动创建或复用名为 `work` 的 tmux 会话，并生成一个适合编码的三分屏布局。
- `lzg`
  `lazygit` 的短别名。

### 2. Ghostty 终端配置

仓库提供了 `ghostty/config`，整体偏向本地 macOS 终端体验优化：

- 字体使用 `Maple Mono NF CN`
- 主题使用 `Kanagawa Wave`
- 半透明背景
- 支持 tabs 和 splits 的快捷键
- 支持全局下拉式 quick terminal
- 开启 shell integration，并传递 SSH 环境、terminfo 和 PATH
- 提供分屏切换、缩放、均分、配置热重载等快捷键

这部分只负责配置，不负责安装 Ghostty 本体。

### 3. tmux 远程持久化工作区

`.tmux.conf` 主要围绕“远程开发时更接近本地编辑体验”来写：

- 开启鼠标支持
- 开启 RGB 颜色支持
- 开启 `allow-passthrough`，方便图片 / LaTeX 渲染类能力穿过 tmux
- 开启系统剪贴板集成
- 使用 `h/j/k/l` 在 pane 间移动
- 使用 `H/J/K/L` 按 5 列或 5 行调整 pane 大小
- 新建窗口和分屏时继承当前目录
- 使用 `Ctrl-Left` / `Ctrl-Right` 快速切换窗口
- 复制模式切成 `vi` 风格
- 绑定 `v` 为一键三分屏布局

配合 shell 里的 `ide` 函数，可以很快起一个固定开发布局。

### 4. Neovim 开发环境

Neovim 是这套配置的核心，重点不只是“能编辑”，而是尽量把远程开发需要的语言支持和文档能力补齐。

#### 编辑能力

- 内置 LSP、补全、诊断和代码操作工作流
- 文件树、buffer 切换、快速跳转、自动配对、surround 等常用编辑能力
- 保存时自动格式化
- Git / 诊断 / symbols 相关 UI 已接好

#### 默认启用的语言服务

- `bash-language-server`
- `clangd`
- `css-lsp`
- `emmet-ls`
- `gopls`
- `html-lsp`
- `json-lsp`
- `lua-language-server`
- `omnisharp`
- `pyright`
- `rust-analyzer`
- `tinymist`
- `typescript-language-server`

#### 当前已配置的格式化工具

- Lua: `stylua`
- Bash: `shfmt`
- Go: `gofumpt`
- Python: `black`
- C#: `csharpier`
- HTML / CSS / JSON / TypeScript: `prettier`

#### Markdown / 文档增强

- Markdown 渲染开关
- Markdown split preview
- LaTeX 公式渲染
- Markdown 图片渲染
- 针对表格、链接、Mermaid 等内容的增强模块
- vendored `mdmath.nvim`，并在安装脚本里自动补 `mathjax` 依赖

#### 语言专项支持

- Rust: `rustaceanvim`
- Flutter / Dart: `flutter-tools.nvim`
- Typst: `tinymist + typst-preview.nvim`
- C#: `omnisharp + csharpier`

#### 安装脚本会额外处理的事情

- 自动安装或修复 `mdmath-js` 的 npm 依赖
- 自动保证 `tree-sitter-cli >= 0.26.1`
- Linux 下为 `tree-sitter-cli` 编译补齐必要系统包
- 对 npm / rustup / cargo 安装失败场景提供国内镜像回退

详细快捷键和插件清单见 [nvim/README.md](nvim/README.md)。

### 5. Yazi 文件管理

Yazi 这部分不是默认配置原样搬运，而是专门往“更像 nvim、适合远程开发”这个方向调过：

- 默认显示隐藏文件
- 目录优先排序
- 默认自然排序
- 默认行模式为 `size_and_mtime`
- 文本类文件优先用 `nvim` 打开
- 图片 / PDF / 音视频按系统方式打开
- 已接入 `relative-motions.yazi`

#### 已补上的使用体验

- 支持 `2j`、`5k`、`10gg`、`G` 这类 Vim 风格计数移动
- 提供 `g p`、`g h`、`g r` 这类快速跳转
- 提供 `c p`、`c f`、`c d` 复制路径 / 文件名 / 目录
- 提供 `o r` 交互式选择打开方式
- 推荐通过 shell 里的 `y` 命令启动，从而在退出后同步 cwd

详细快捷键和打开规则见 [yazi/README.md](yazi/README.md)。

### 6. Git / Lazygit 协同

这套仓库对 Git 的处理分两层：

- 命令行层面把全局 diff / merge 工具设置为 `nvimdiff`
- TUI 层面提供 `lazygit/config.yml`，并把编辑器 preset 设成 `nvim`

这样不管你是在命令行冲突处理，还是在 Lazygit 里看改动，默认都会回到同一套编辑器习惯里。

### 7. Codex 配置同步

`scripts/link/codexRsync.sh` 不走符号链接，而是用 `rsync` 将仓库中的 `.codex/` 同步到 `~/.codex/`：

- 默认保留原目录结构
- 同步时启用备份
- 旧文件会以 `.bak` 后缀留下

这种方式比直接软链接更稳，适合本地个人配置长期演进。

## 仓库结构

```text
.
├── ghostty/      # Ghostty 配置
├── lazygit/      # Lazygit 配置
├── nvim/         # Neovim 配置与子文档
├── scripts/      # 安装与链接脚本
├── shell/        # shell 初始化、环境变量、辅助函数
├── yazi/         # Yazi 配置与子文档
├── .tmux.conf    # tmux 配置
├── starship.toml # Starship prompt 配置
└── setup.sh      # 一键初始化入口
```

## 使用方式

### 整体初始化

```bash
git clone <your-repo-url> ~/.config/dotfiles
cd ~/.config/dotfiles
bash setup.sh
```

执行完成后，重启 shell，或者手动执行：

```bash
source ~/.config/dotfiles/shell/init.sh
```

### 单独安装某一部分

```bash
bash scripts/install/neovimInstall.sh
bash scripts/install/yaziInstall.sh
bash scripts/install/lazygitInstall.sh
bash scripts/install/starshipInstall.sh
```

### 单独链接某一部分

```bash
bash scripts/link/nvimLink.sh
bash scripts/link/yaziLink.sh
bash scripts/link/lazygitLink.sh
bash scripts/link/starshipLink.sh
bash scripts/link/tmuxLink.sh
bash scripts/link/ghosttyLink.sh
bash scripts/link/codexRsync.sh
```

## 依赖和前提

- 本地 Ghostty 需要你自己安装
- 远程机器上的 `tmux` 需要你自己安装
- Markdown 图片渲染依赖终端支持 Kitty Graphics Protocol
- 通过 `SSH + tmux` 使用图片 / LaTeX 渲染时，需要本地终端支持该协议，且远端 tmux 开启 `allow-passthrough`
- Rust / Flutter / Typst / C# 等专项功能依赖对应语言工具链已经存在

## 子文档

- [nvim/README.md](nvim/README.md)
- [yazi/README.md](yazi/README.md)
