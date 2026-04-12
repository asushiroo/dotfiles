local M = {}

local transparent_groups = {
	"RenderMarkdownH1Bg",
	"RenderMarkdownH2Bg",
	"RenderMarkdownH3Bg",
	"RenderMarkdownH4Bg",
	"RenderMarkdownH5Bg",
	"RenderMarkdownH6Bg",
	"RenderMarkdownCode",
	"RenderMarkdownCodeBorder",
	"RenderMarkdownCodeInline",
	"RenderMarkdownInlineHighlight",
}

local function clear_group_bg(group)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
	if not ok or type(hl) ~= "table" then
		pcall(vim.api.nvim_set_hl, 0, group, { bg = "NONE", ctermbg = "NONE" })
		return
	end

	hl.bg = nil
	hl.ctermbg = nil
	hl.link = nil
	if vim.tbl_isempty(hl) then
		hl = { bg = "NONE", ctermbg = "NONE" }
	end
	pcall(vim.api.nvim_set_hl, 0, group, hl)
end

function M.clear_backgrounds()
	for _, group in ipairs(transparent_groups) do
		clear_group_bg(group)
	end
end

function M.setup_transparent_highlights()
	M.clear_backgrounds()

	local group = vim.api.nvim_create_augroup("UserRenderMarkdownTransparent", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			vim.schedule(M.clear_backgrounds)
		end,
	})
end

return M
