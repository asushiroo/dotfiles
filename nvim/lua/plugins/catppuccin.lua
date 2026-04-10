return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	opts = {
		flavour = "mocha",
		transparent_background = true,
		show_end_of_buffer = false,
		term_colors = true,
		integrations = {
			bufferline = true,
			cmp = true,
			gitsigns = true,
			indent_blankline = { enabled = true },
			lsp_saga = true,
			native_lsp = {
				enabled = true,
				underlines = {
					errors = { "undercurl" },
					hints = { "undercurl" },
					warnings = { "undercurl" },
					information = { "undercurl" },
				},
				inlay_hints = {
					background = false,
				},
			},
			nvimtree = true,
			telescope = { enabled = true },
			treesitter = true,
			trouble = true,
		},
		custom_highlights = function(c)
			return {
				Normal = { fg = c.text, bg = "NONE" },
				NormalNC = { fg = c.text, bg = "NONE" },
				SignColumn = { bg = "NONE" },
				EndOfBuffer = { bg = "NONE" },
				FoldColumn = { bg = "NONE" },
				NormalFloat = { bg = "NONE" },
				FloatBorder = { fg = c.surface2, bg = "NONE" },
				FloatTitle = { fg = c.blue, bg = "NONE", bold = true },
				WinSeparator = { fg = c.surface1, bg = "NONE" },
				StatusLine = { bg = "NONE" },
				StatusLineNC = { bg = "NONE" },
				TabLine = { bg = "NONE" },
				TabLineFill = { bg = "NONE" },
				TabLineSel = { bg = "NONE" },
				Pmenu = { bg = "NONE" },
				PmenuSbar = { bg = "NONE" },
				PmenuThumb = { bg = c.surface1 },
				TelescopeNormal = { bg = "NONE" },
				TelescopeBorder = { fg = c.surface2, bg = "NONE" },
				TelescopeTitle = { fg = c.blue, bg = "NONE", bold = true },
				NvimTreeNormal = { bg = "NONE" },
				NvimTreeNormalNC = { bg = "NONE" },
				NvimTreeEndOfBuffer = { bg = "NONE" },
				NvimTreeWinSeparator = { bg = "NONE" },
				Visual = { bg = c.surface2 },
				VisualNOS = { bg = c.surface1 },

				LineNr = { fg = c.overlay1 },
				LineNrAbove = { fg = c.overlay1 },
				LineNrBelow = { fg = c.overlay1 },

				LspReferenceText = { bg = "NONE", underline = true, sp = c.blue },
				LspReferenceRead = { bg = "NONE", underline = true, sp = c.blue },
				LspReferenceWrite = { bg = "NONE", underline = true, sp = c.peach },
				LspSignatureActiveParameter = { bg = "NONE", underline = true, bold = true, sp = c.yellow },
				LspInlayHint = { bg = "NONE", fg = c.overlay1, italic = true },

				DiagnosticVirtualTextError = { bg = "NONE", fg = c.red },
				DiagnosticVirtualTextWarn = { bg = "NONE", fg = c.yellow },
				DiagnosticVirtualTextInfo = { bg = "NONE", fg = c.sky },
				DiagnosticVirtualTextHint = { bg = "NONE", fg = c.teal },

				DiagnosticUnderlineError = { undercurl = true, sp = c.red },
				DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
				DiagnosticUnderlineInfo = { undercurl = true, sp = c.sky },
				DiagnosticUnderlineHint = { undercurl = true, sp = c.teal },
			}
		end,
	},
	config = function(_, opts)
		require("catppuccin").setup(opts)
		vim.cmd.colorscheme("catppuccin")
		require("core.transparent").apply()
	end,
}
