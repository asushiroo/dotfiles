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
			editor_only_render_when_focused = true,
			hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
		},
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
}
