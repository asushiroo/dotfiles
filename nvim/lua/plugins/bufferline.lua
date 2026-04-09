return {
	"akinsho/bufferline.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },

	opts = {
		options = {
			separator_style = "thin",
		},
	},
	highlights = {
		fill = { bg = "NONE" },
		background = { bg = "NONE" },
		buffer_selected = { bg = "NONE", bold = true },
		separator = { bg = "NONE" },
		separator_selected = { bg = "NONE" },

		-- 🔥 关键：关闭按钮（❌）
		close_button = { bg = "NONE" },
		close_button_visible = { bg = "NONE" },
		close_button_selected = { bg = "NONE" },

		-- 🔥 其他 buffer 状态（建议一起改）
		buffer_visible = { bg = "NONE" },
		buffer = { bg = "NONE" },

		-- 🔥 indicator（下面那条线）
		indicator_selected = { bg = "NONE" },
	},
	keys = {
		{ "<leader>bh", ":BufferLineCyclePrev<CR>", silent = true },
		{ "<leader>bl", ":BufferLineCycleNext<CR>", silent = true },
		{ "<leader>bp", ":BufferLinePick<CR>", silent = true },
		{ "<leader>bd", ":bdelete<CR>", silent = true },
	},
	lazy = false,
}
