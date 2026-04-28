return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			enabled = true,
			file_types = { "markdown" },
			render_modes = { "n", "c", "t" },
			anti_conceal = {
				enabled = false,
			},
			latex = {
				enabled = false,
			},
			code = {
				-- Keep code rendering but avoid full-line background blocks in a
				-- transparent terminal/theme.
				disable_background = true,
				width = "block",
				border = "none",
			},
			heading = {
				-- Keep heading icons, but do not paint heading backgrounds so
				-- transparent themes stay clean. Floating icons while horizontal
				-- scrolling are handled by core.markdown.render_markdown.
				enabled = true,
				sign = false,
				position = "overlay",
				width = "block",
				left_margin = 0,
				left_pad = 0,
				right_pad = 0,
				border = false,
				border_virtual = false,
				backgrounds = {},
			},
			pipe_table = {
				-- Tables are rendered by core.markdown.table_render instead.
				-- That renderer draws a whole clipped visual line per table row,
				-- avoiding Neovim conceal/leftcol coordinate drift.
				enabled = false,
			},
		},
		config = function(_, opts)
			local patch = require("core.markdown.render_markdown")
			require("render-markdown").setup(opts)
			patch.setup_transparent_highlights()
		end,
		keys = {
			{ "<leader>um", "<Cmd>RenderMarkdown buf_toggle<CR>", desc = "Markdown render toggle", silent = true },
			{ "<leader>uM", "<Cmd>RenderMarkdown preview<CR>", desc = "Markdown render split preview", silent = true },
		},
	},
	{
		dir = vim.fs.joinpath(vim.fn.stdpath("config"), "vendor", "mdmath.nvim"),
		name = "mdmath.nvim",
		ft = { "markdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		build = ":MdMath build",
		opts = {
			filetypes = { "markdown" },
			foreground = "Normal",
			anticonceal = false,
			hide_on_insert = true,
			dynamic = false,
			dynamic_scale = 1.0,
			internal_scale = 1.0,
			update_interval = 200,
		},
		config = function(_, opts)
			require("mdmath").setup(opts)
		end,
		keys = {
			{ "<leader>ue", "<Cmd>MdMath enable<CR>", desc = "Markdown equation render on", silent = true },
			{ "<leader>uE", "<Cmd>MdMath disable<CR>", desc = "Markdown equation render off", silent = true },
			{ "<leader>ur", "<Cmd>MdMath clear<CR>", desc = "Markdown equation rerender", silent = true },
		},
	},
	{
		"3rd/image.nvim",
		ft = { "markdown" },
		build = false,
		opts = {
			backend = "kitty",
			processor = "magick_cli",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					only_render_image_at_cursor_mode = "inline",
					floating_windows = false,
					filetypes = { "markdown" },
					resolve_image_path = function(document_path, image_path, fallback)
						image_path = image_path:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")

						if image_path:match("^~/") then
							return vim.fn.expand(image_path)
						end

						return fallback(document_path, image_path)
					end,
				},
			},
			max_height_window_percentage = 45,
			window_overlap_clear_enabled = true,
			editor_only_render_when_focused = false,
			hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
		},
		config = function(_, opts)
			require("core.image.rsvg_fallback").apply()
			require("image").setup(opts)
		end,
		keys = {
			{
				"<leader>ui",
				function()
					local image = require("image")
					if image.is_enabled() then
						image.disable()
					else
						image.enable()
					end
				end,
				desc = "Markdown image toggle",
				silent = true,
			},
		},
	},
	{
		"3rd/diagram.nvim",
		ft = { "markdown" },
		dependencies = {
			"3rd/image.nvim",
		},
		opts = function()
			local puppeteer_cfg = vim.fs.joinpath(vim.fn.stdpath("cache"), "diagram-mermaid-puppeteer.json")
			local mermaid_cfg = vim.fs.joinpath(vim.fn.stdpath("cache"), "diagram-mermaid-config.json")
			if vim.fn.filereadable(puppeteer_cfg) == 0 then
				vim.fn.writefile({
					vim.json.encode({
						args = { "--no-sandbox", "--disable-setuid-sandbox" },
					}),
				}, puppeteer_cfg)
			end
			-- 先写一个默认配置；实际字号会在渲染时按当前终端字符高度动态覆盖。
			vim.fn.writefile({
				vim.json.encode({
					theme = "dark",
					themeVariables = {
						fontSize = "12px",
						lineColor = "#ffffff",
						arrowheadColor = "#ffffff",
					},
					themeCSS = table.concat({
						".edgeLabel rect{fill:transparent!important;}",
						".edgeLabel text{fill:#e8e8e8!important;}",
						".node rect,.node polygon,.node circle,.node path{stroke:#ffffff!important;}",
					}),
				}),
			}, mermaid_cfg)

			return {
				integrations = {
					require("diagram.integrations.markdown"),
				},
				events = {
					-- 关闭 diagram.nvim 内置自动事件，完全交给
					-- core.markdown.mermaid 控制，避免与 markdown/image 渲染互相干扰。
					render_buffer = {},
					clear_buffer = {},
				},
				renderer_options = {
					mermaid = {
						background = "transparent",
						scale = 1,
						cli_args = { "-p", puppeteer_cfg, "-c", mermaid_cfg },
					},
				},
			}
		end,
		config = function(_, opts)
			require("diagram").setup(opts)
			local cache_dir = vim.fn.stdpath("cache")
			local puppeteer_cfg = vim.fs.joinpath(cache_dir, "diagram-mermaid-puppeteer.json")
			local mermaid_cfg = vim.fs.joinpath(cache_dir, "diagram-mermaid-config.json")

			-- Mermaid 图片单独修正：固定左对齐、使用虚拟占位。
			local ok_image, image = pcall(require, "image")
			if ok_image and image and not image._markdown_mermaid_from_file_patched then
				local original_from_file = image.from_file
				image.from_file = function(path, options, ...)
					local is_mermaid = type(path) == "string" and path:find("/diagram%-cache/mermaid/", 1, false)
					local opts_local = options
					if is_mermaid and type(options) == "table" then
						opts_local = vim.tbl_deep_extend("force", {}, options, {
							max_width_window_percentage = 100,
							max_height_window_percentage = 100,
							render_offset_top = 0,
							x = 0,
							inline = true,
							with_virtual_padding = true,
						})
					end

					local img = original_from_file(path, opts_local, ...)
					if is_mermaid and img then
						img.geometry.x = 0
						img.inline = true
						img.with_virtual_padding = true
						img.render_offset_top = 0
						img.max_width_window_percentage = 100
						img.max_height_window_percentage = 100
					end
					return img
				end
				image._markdown_mermaid_from_file_patched = true
			end

			local function parse_direction(source)
				for line in source:gmatch("[^\r\n]+") do
					local dir = line:match("^%s*flowchart%s+([%a]+)")
					if dir then
						return dir:upper()
					end
					dir = line:match("^%s*graph%s+([%a]+)")
					if dir then
						return dir:upper()
					end
				end
				return "TD"
			end

			local function summarize_source(source)
				local direction = parse_direction(source)
				local stmt_count = 0
				local node_count = 0
				local edge_count = 0
				local max_label_width = 0

				for line in source:gmatch("[^\r\n]+") do
					local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
					if trimmed ~= "" and not trimmed:match("^%%") then
						stmt_count = stmt_count + 1

						for label in trimmed:gmatch("%[(.-)%]") do
							local text = label:gsub('^["\']', ""):gsub('["\']$', "")
							max_label_width = math.max(max_label_width, vim.fn.strdisplaywidth(text))
							node_count = node_count + 1
						end

						local _, arrows = trimmed:gsub("%-%->", "")
						edge_count = edge_count + arrows
						local _, arrows2 = trimmed:gsub("==>", "")
						edge_count = edge_count + arrows2
					end
				end

				node_count = math.max(node_count, stmt_count)
				return direction, node_count, edge_count, max_label_width
			end

			local function get_term_cell_size()
				local cell_w, cell_h = 8, 16
				local ok_term, term = pcall(require, "image.utils.term")
				if ok_term and term and term.get_size then
					local sz = term.get_size()
					if sz and sz.cell_width and sz.cell_height and sz.cell_width > 0 and sz.cell_height > 0 then
						cell_w = math.max(1, math.floor(sz.cell_width + 0.5))
						cell_h = math.max(1, math.floor(sz.cell_height + 0.5))
					end
				end
				return cell_w, cell_h
			end

			local last_font_px = nil
			local function write_mermaid_theme(font_px)
				if last_font_px == font_px then
					return
				end
				last_font_px = font_px
				vim.fn.writefile({
					vim.json.encode({
						theme = "dark",
						themeVariables = {
							fontSize = string.format("%dpx", font_px),
							lineColor = "#ffffff",
							arrowheadColor = "#ffffff",
						},
						themeCSS = table.concat({
							".edgeLabel rect{fill:transparent!important;}",
							".edgeLabel text{fill:#e8e8e8!important;}",
							".node rect,.node polygon,.node circle,.node path{stroke:#ffffff!important;}",
						}),
					}),
				}, mermaid_cfg)
			end

			local function estimate_canvas(source)
				local direction, node_count, edge_count, max_label_width = summarize_source(source)
				local cell_w, cell_h = get_term_cell_size()
				local win = vim.api.nvim_get_current_win()
				local win_cols = 80
				local win_rows = 24
				if win and vim.api.nvim_win_is_valid(win) then
					win_cols = math.max(40, vim.api.nvim_win_get_width(win) - 2)
					win_rows = math.max(8, vim.api.nvim_win_get_height(win) - 2)
				end

				-- 按当前终端字符高度计算 Mermaid 字号。
				local font_px = math.max(10, math.min(24, math.floor(cell_h * 0.9 + 0.5)))
				write_mermaid_theme(font_px)

				local win_px = win_cols * cell_w
				local min_label_px = math.floor((max_label_width + 8) * font_px * 0.62)
				local width
				local height_rows
				if direction == "LR" or direction == "RL" then
					width = math.max(win_px, min_label_px + math.min(node_count, 8) * font_px * 2)
					height_rows = 7 + math.ceil(node_count / 3) * 4 + math.ceil(edge_count / 5)
				else
					width = math.max(win_px, min_label_px + math.min(node_count, 4) * font_px)
					height_rows = 6 + node_count * 3 + math.ceil(edge_count * 0.6)
				end

				-- 避免源图远大于窗口导致二次缩放后文字变小。
				local width_cap = math.floor(win_px * 1.12)
				width = math.floor(math.max(win_px, math.min(width_cap, width)))
				height_rows = math.max(8, math.min(win_rows * 8, height_rows))
				local height = height_rows * cell_h

				return math.max(640, width), math.max(cell_h * 6, height)
			end

			-- Mermaid 尺寸按当前字符大小 + 图复杂度动态计算。
			local ok_renderers, renderers = pcall(require, "diagram.renderers")
			if ok_renderers and renderers and renderers.mermaid and not renderers.mermaid._dynamic_size_patched then
				local original_render = renderers.mermaid.render
				renderers.mermaid.render = function(source, options)
					local render_opts = vim.tbl_deep_extend("force", {}, options or {})
					local width, height = estimate_canvas(source)
					render_opts.scale = nil
					render_opts.theme = "dark"
					render_opts.width = width
					render_opts.height = height
					render_opts.cli_args = { "-p", puppeteer_cfg, "-c", mermaid_cfg }
					return original_render(source, render_opts)
				end
				renderers.mermaid._dynamic_size_patched = true
			end
		end,
		keys = {
			{
				"<leader>ud",
				function()
					require("diagram").render()
				end,
				desc = "Mermaid render",
				silent = true,
			},
			{
				"<leader>uD",
				function()
					require("diagram").clear()
				end,
				desc = "Mermaid clear",
				silent = true,
			},
		},
	},
}
