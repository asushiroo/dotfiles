# Neovim 配置说明

## Leader 键

- `Leader` = `<Space>`

## 已启用的 LSP / 补全 / UI 插件

- `mason.nvim`
- `mason-lspconfig.nvim`
- `nvim-lspconfig`
- `blink.cmp`
- `friendly-snippets`
- `none-ls.nvim`
- `none-ls-extras.nvim`
- `lspsaga.nvim`
- `trouble.nvim`
- `flutter-tools.nvim`
- `rustaceanvim`
- `typst-preview.nvim`
- `dressing.nvim`

## 当前默认启用的语言服务

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

## 快捷键总览

### 通用

| 快捷键 | 模式 | 说明 |
| --- | --- | --- |
| `<C-z>` | 普通 / 插入 | 撤销 |

### Bufferline

| 快捷键 | 说明 |
| --- | --- |
| `<leader>bh` | 切换到上一个 buffer |
| `<leader>bl` | 切换到下一个 buffer |
| `<leader>bp` | 选择 buffer |
| `<leader>bd` | 关闭当前 buffer |

### Hop

| 快捷键 | 说明 |
| --- | --- |
| `<leader>hp` | Hop 到单词 |

### 插入模式自动补全 `blink.cmp`

| 快捷键 | 说明 |
| --- | --- |
| `<C-space>` | 打开补全菜单 |
| `<C-e>` | 关闭补全菜单 |
| `<CR>` | 确认当前补全项 |
| `<Tab>` | 选择并确认补全 / 跳到下一个 snippet |
| `<S-Tab>` | 跳到上一个 snippet |
| `<C-j>` | 下一个候选项 |
| `<C-k>` | 上一个候选项 |
| `<C-d>` | 向下滚动补全文档 |
| `<C-u>` | 向上滚动补全文档 |

### 命令行补全 `blink.cmp`

- `:` / `@` 使用命令行补全
- `/` / `?` 使用当前 buffer 内容补全

| 快捷键 | 说明 |
| --- | --- |
| `<Tab>` | 打开并确认命令行补全 |
| `<C-j>` | 下一个候选项 |
| `<C-k>` | 上一个候选项 |
| `<C-e>` | 取消命令行补全 |

### LSP 基础

| 快捷键 | 说明 |
| --- | --- |
| `K` | 悬停文档 |
| `gd` | 跳转到定义 |
| `gD` | 跳转到声明 |
| `gr` | 查看引用 |
| `gi` | 跳转到实现 |
| `[d` | 上一个诊断 |
| `]d` | 下一个诊断 |
| `<leader>rn` | 重命名符号 |
| `<leader>ca` | 代码操作 |
| `<leader>lf` | 格式化代码 |
| `<leader>e` | 查看当前行诊断 |
| `<leader>q` | 将诊断放入 loclist |

### LSP UI `lspsaga.nvim`

| 快捷键 | 说明 |
| --- | --- |
| `<leader>lr` | Lspsaga 重命名 |
| `<leader>lc` | Lspsaga 代码操作 |
| `<leader>ld` | Lspsaga 跳转定义 |
| `<leader>lD` | Lspsaga 预览定义 |
| `<leader>lR` | Lspsaga finder（引用 / 定义 / 实现） |
| `<leader>li` | Lspsaga implementation finder |
| `<leader>lh` | Lspsaga 悬停文档 |
| `<leader>lP` | Lspsaga 当前行诊断 |
| `<leader>ln` | Lspsaga 下一个诊断 |
| `<leader>lp` | Lspsaga 上一个诊断 |
| `<leader>lo` | Lspsaga symbols outline |

### 诊断列表 `trouble.nvim`

| 快捷键 | 说明 |
| --- | --- |
| `<leader>lt` | 打开 diagnostics 列表 |
| `<leader>lT` | 打开 symbols 列表 |

### Typst

| 快捷键 | 说明 |
| --- | --- |
| `<A-b>` | 切换 Typst 预览 |

## 自动格式化

- 已启用保存时自动格式化：`BufWritePre`
- 若 `null-ls` 可用，优先使用 `null-ls`
- 也可以手动使用 `<leader>lf` 触发格式化

## 当前已配置的格式化工具

- Lua: `stylua`
- Bash: `shfmt`
- Go: `gofumpt`
- Python: `black`
- C#: `csharpier`
- HTML / CSS / JSON / TypeScript: `prettier`

## 语言专项说明

- Rust 使用 `rustaceanvim` 管理 `rust-analyzer`
- Flutter / Dart 使用 `flutter-tools.nvim`
- Typst 使用 `tinymist` + `typst-preview.nvim`
- C# 使用 `omnisharp`，并额外接入 `csharpier` 格式化

## 环境依赖提示

- Flutter 功能依赖本机已安装 `flutter`
- Rust 功能依赖本机已安装 Rust toolchain
- Typst 预览依赖本机可用的 Typst 环境
- OmniSharp 依赖本机可用的 `dotnet`
- Markdown LaTeX 渲染使用 vendored `mdmath.nvim`，依赖 `node` / `npm` / ImageMagick / `rsvg-convert`
- Markdown LaTeX 渲染依赖终端支持 Kitty Graphics Protocol；通过 SSH + tmux 使用时，需要本地终端支持该协议，且远端 `tmux` 开启 `allow-passthrough`
- 若系统依赖不存在，对应专项插件 / LSP 会自动跳过加载，避免启动时报错

## 安装 / 更新

首次安装或补装插件、LSP、formatter 后，建议执行：

```vim
:Lazy sync
:Mason
```
