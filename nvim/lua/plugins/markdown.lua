return {
	{
		"OXY2DEV/markview.nvim",
		lazy = false,
		priority = 900,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			preview = {
				filetypes = { "markdown" },
				icon_provider = "devicons",
			},
			markdown = {
				enable = true,
			},
			markdown_inline = {
				enable = true,
			},
			latex = {
				enable = false,
			},
		},
		keys = {
			{ "<leader>um", "<Cmd>Markview toggle<CR>", desc = "Markdown preview toggle", silent = true },
			{ "<leader>uM", "<Cmd>Markview splitToggle<CR>", desc = "Markdown split preview", silent = true },
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
