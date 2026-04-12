local M = {}

local function truncate_middle(text, keep)
	keep = keep or 10
	text = text or ""
	local len = vim.fn.strchars(text)
	if len <= keep then
		return text
	end

	local left = math.floor(keep / 2)
	local right = keep - left
	return vim.fn.strcharpart(text, 0, left) .. "..." .. vim.fn.strcharpart(text, len - right, right)
end

local function in_range(col, start_col, end_col)
	return col >= start_col and col <= end_col
end

local function add_match(matches, url, start_idx, end_idx)
	if not url or url == "" then
		return
	end

	matches[#matches + 1] = {
		url = url,
		start_col = start_idx - 1,
		end_col = end_idx - 1,
	}
end

local function markdown_links(line)
	local matches = {}

	local start = 1
	while start <= #line do
		local s, e, url = line:find("!%[[^%]]*%]%(([^%)]+)%)", start)
		if not s then
			break
		end
		add_match(matches, url, s, e)
		start = e + 1
	end

	start = 1
	while start <= #line do
		local s, e, url = line:find("%[[^%]]+%]%(([^%)]+)%)", start)
		if not s then
			break
		end
		add_match(matches, url, s, e)
		start = e + 1
	end

	start = 1
	while start <= #line do
		local s, e, url = line:find("<(https?://[^>]+)>", start)
		if not s then
			break
		end
		add_match(matches, url, s, e)
		start = e + 1
	end

	start = 1
	while start <= #line do
		local s, e, url = line:find("(https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+)", start)
		if not s then
			break
		end
		add_match(matches, url:gsub("[%.,;:]+$", ""), s, e)
		start = e + 1
	end

	return matches
end

local function find_link(line, col)
	for _, match in ipairs(markdown_links(line)) do
		if in_range(col, match.start_col, match.end_col) then
			return match.url
		end
	end
end

function M.copy_under_mouse()
	local mouse = vim.fn.getmousepos()
	local win = mouse.winid
	if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
		return false
	end

	local bufnr = vim.api.nvim_win_get_buf(win)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "markdown" then
		return false
	end

	local lnum = mouse.line or 0
	if lnum <= 0 or lnum > vim.api.nvim_buf_line_count(bufnr) then
		return false
	end

	local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
	local col = math.max(0, (mouse.column or 1) - 1)
	local link = find_link(line, col)
	if not link then
		return false
	end

	pcall(vim.fn.setreg, "+", link)
	pcall(vim.fn.setreg, "*", link)
	vim.fn.setreg('"', link)
	vim.notify(("已复制链接: %s"):format(truncate_middle(link, 10)), vim.log.levels.INFO)
	return true
end

return M
