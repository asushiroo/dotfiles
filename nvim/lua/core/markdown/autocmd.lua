vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.colorcolumn = ""
		vim.opt_local.wrap = false
		vim.opt_local.linebreak = false
		vim.opt_local.breakindent = false

		require("core.markdown.table_render").setup(0)
		require("core.markdown.mermaid").setup(0)

		vim.api.nvim_buf_create_user_command(0, "MarkdownTableRenderRefresh", function()
			require("core.markdown.table_render").update(0)
		end, {
			desc = "Refresh custom Markdown table renderer",
		})

		vim.api.nvim_buf_create_user_command(0, "MarkdownTableRenderClear", function()
			require("core.markdown.table_render").clear(0)
		end, {
			desc = "Clear custom Markdown table renderer",
		})

		vim.api.nvim_buf_create_user_command(0, "MarkdownTableFormat", function()
			require("core.markdown.table").format_table_at_cursor()
		end, {
			desc = "Format current Markdown table with aligned padding",
		})

		vim.api.nvim_buf_create_user_command(0, "MarkdownTableFormatAll", function()
			require("core.markdown.table").format_all_tables()
		end, {
			desc = "Format all Markdown tables with aligned padding",
		})

		vim.api.nvim_buf_create_user_command(0, "MarkdownTableDebug", function()
			require("core.markdown.table").debug_table_at_cursor()
		end, {
			desc = "Format current Markdown table with '-' debug padding",
		})

		vim.api.nvim_buf_create_user_command(0, "MarkdownTableDebugAll", function()
			require("core.markdown.table").debug_all_tables()
		end, {
			desc = "Format all Markdown tables with '-' debug padding",
		})

		vim.keymap.set("n", "<leader>mt", function()
			require("core.markdown.table").format_table_at_cursor()
		end, {
			buffer = true,
			desc = "Format Markdown table",
			silent = true,
		})

		vim.keymap.set("n", "<leader>mT", function()
			require("core.markdown.table").format_all_tables()
		end, {
			buffer = true,
			desc = "Format all Markdown tables",
			silent = true,
		})

		vim.keymap.set("n", "<leader>md", function()
			require("core.markdown.table").debug_table_at_cursor()
		end, {
			buffer = true,
			desc = "Debug Markdown table padding",
			silent = true,
		})

		vim.keymap.set("n", "<leader>mD", function()
			require("core.markdown.table").debug_all_tables()
		end, {
			buffer = true,
			desc = "Debug all Markdown table padding",
			silent = true,
		})

		vim.keymap.set("n", "<LeftMouse>", function()
			if require("core.markdown.link").copy_under_mouse() then
				return
			end

			local left_mouse = vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true)
			vim.api.nvim_feedkeys(left_mouse, "n", false)
		end, {
			buffer = true,
			desc = "Copy Markdown link under mouse",
			silent = true,
		})
	end,
})
