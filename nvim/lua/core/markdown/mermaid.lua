local M = {}

local ns = vim.api.nvim_create_namespace("UserMarkdownMermaidConceal")
local augroup = vim.api.nvim_create_augroup("UserMarkdownMermaid", { clear = true })

local function find_mermaid_blocks(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local blocks = {}
	local i = 1

	while i <= #lines do
		local line = lines[i]
		local fence, info = line:match("^%s*([`~][`~][`~]+)%s*(.-)%s*$")
		if not fence then
			i = i + 1
			goto continue
		end

		local info_l = (info or ""):lower()
		if not info_l:match("^mermaid[%s%{%}]?.*$") then
			i = i + 1
			goto continue
		end

		local fence_char = fence:sub(1, 1)
		local fence_len = #fence
		local j = i + 1
		while j <= #lines do
			local close = lines[j]:match("^%s*(" .. fence_char .. "+)%s*$")
			if close and #close >= fence_len then
				break
			end
			j = j + 1
		end

		blocks[#blocks + 1] = {
			start_row = i - 1, -- 0-indexed
			end_row = math.min(j, #lines) - 1, -- 0-indexed
		}
		i = (j <= #lines) and (j + 1) or (#lines + 1)

		::continue::
	end

	return blocks
end

local function set_window_conceal(bufnr, level, cursor_modes)
	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].conceallevel = level
			vim.wo[win].concealcursor = cursor_modes
		end
	end
end

local function clear_conceal(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

local function apply_conceal(bufnr)
	clear_conceal(bufnr)
	for _, block in ipairs(find_mermaid_blocks(bufnr)) do
		local start_text = (vim.api.nvim_buf_get_lines(bufnr, block.start_row, block.start_row + 1, false)[1]) or ""
		-- 保留第一行作为 image.nvim inline 虚拟占位锚点，避免图片覆盖后文。
		vim.api.nvim_buf_set_extmark(bufnr, ns, block.start_row, 0, {
			end_row = block.start_row,
			end_col = #start_text,
			hl_group = "Conceal",
			conceal = "",
			priority = 250,
		})
		-- 折叠其余 mermaid 源码行，减少空白。
		if block.end_row > block.start_row then
			vim.api.nvim_buf_set_extmark(bufnr, ns, block.start_row + 1, 0, {
				end_row = block.end_row + 1,
				end_col = 0,
				conceal_lines = "",
				priority = 260,
			})
		end
	end
end

local function render_now(bufnr)
	pcall(function()
		local wins = vim.fn.win_findbuf(bufnr)
		local target_win = wins[1]
		if target_win and vim.api.nvim_win_is_valid(target_win) then
			local cur_win = vim.api.nvim_get_current_win()
			if cur_win ~= target_win then
				vim.api.nvim_set_current_win(target_win)
				require("diagram").render()
				vim.api.nvim_set_current_win(cur_win)
				return
			end
		end
		require("diagram").render()
	end)
end

local function clear_now(bufnr)
	pcall(function()
		local wins = vim.fn.win_findbuf(bufnr)
		local target_win = wins[1]
		if target_win and vim.api.nvim_win_is_valid(target_win) then
			local cur_win = vim.api.nvim_get_current_win()
			if cur_win ~= target_win then
				vim.api.nvim_set_current_win(target_win)
				require("diagram").clear()
				vim.api.nvim_set_current_win(cur_win)
				return
			end
		end
		require("diagram").clear()
	end)
end

local function enable_for_normal(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	set_window_conceal(bufnr, 2, "nc")
	apply_conceal(bufnr)
	render_now(bufnr)
end

local function disable_for_insert(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	set_window_conceal(bufnr, 0, "")
	clear_conceal(bufnr)
	clear_now(bufnr)
end

function M.setup(bufnr)
	bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	if vim.b[bufnr].markdown_mermaid_setup_done then
		return
	end
	vim.b[bufnr].markdown_mermaid_setup_done = true

	if vim.g.markdown_mermaid_cache_busted ~= 1 then
		local cache_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "diagram-cache", "mermaid")
		pcall(vim.fn.delete, cache_dir, "rf")
		vim.fn.mkdir(cache_dir, "p")
		vim.g.markdown_mermaid_cache_busted = 1
	end

	vim.api.nvim_buf_create_user_command(bufnr, "MermaidRender", function()
		render_now(bufnr)
	end, {
		desc = "Render Mermaid diagrams in current buffer",
	})

	vim.api.nvim_buf_create_user_command(bufnr, "MermaidClear", function()
		clear_now(bufnr)
	end, {
		desc = "Clear Mermaid diagrams in current buffer",
	})

	vim.api.nvim_create_autocmd({ "InsertEnter" }, {
		group = augroup,
		buffer = bufnr,
		callback = function()
			disable_for_insert(bufnr)
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertLeave", "BufWinEnter", "BufWritePost" }, {
		group = augroup,
		buffer = bufnr,
		callback = function()
			enable_for_normal(bufnr)
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged" }, {
		group = augroup,
		buffer = bufnr,
		callback = function()
			if vim.api.nvim_get_mode().mode:sub(1, 1) ~= "i" then
				apply_conceal(bufnr)
			end
		end,
	})

	if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
		disable_for_insert(bufnr)
	else
		enable_for_normal(bufnr)
	end
end

return M
