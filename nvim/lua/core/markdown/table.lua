local M = {}

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function is_table_candidate(line)
	if type(line) ~= "string" or line == "" then
		return false
	end

	return line:find("|", 1, true) ~= nil
end

local function parse_row(line)
	local cells = {}
	local buf = {}
	local escaped = false

	for i = 1, #line do
		local ch = line:sub(i, i)

		if escaped then
			table.insert(buf, ch)
			escaped = false
		elseif ch == "\\" then
			table.insert(buf, ch)
			escaped = true
		elseif ch == "|" then
			table.insert(cells, table.concat(buf))
			buf = {}
		else
			table.insert(buf, ch)
		end
	end

	table.insert(cells, table.concat(buf))

	if line:sub(1, 1) == "|" then
		table.remove(cells, 1)
	end

	if line:sub(-1) == "|" then
		table.remove(cells, #cells)
	end

	for i, cell in ipairs(cells) do
		cells[i] = trim(cell)
	end

	return cells
end

local function is_separator_cell(cell)
	return trim(cell):match("^:?-+:?$") ~= nil
end

local function separator_align(cell)
	cell = trim(cell)

	if cell:match("^:.-:$") then
		return "center"
	elseif cell:match("^:") then
		return "left"
	elseif cell:match(":$") then
		return "right"
	else
		return "default"
	end
end

local function markdown_render_width_text(text)
	-- Approximate the visual width after render-markdown has concealed common
	-- inline Markdown syntax and inserted link icons.  This lets us write real
	-- padding spaces into the table instead of relying on virtual padding, which
	-- breaks when horizontally scrolling past the virtual-text anchor.
	local link_icon = "󰌹 "
	local image_icon = "󰥶 "
	local email_icon = "󰀓 "

	text = text:gsub("!%[([^%]]*)%]%([^%)]*%)", image_icon .. "%1")
	text = text:gsub("%[([^%]]*)%]%(([^%)]*)%)", function(label, destination)
		local icon = link_icon
		if destination:match("github%.com") then
			icon = "󰊤 "
		end
		return icon .. label
	end)
	text = text:gsub("<([%w%._%+%-]+@[%w%._%-]+)>", email_icon .. "%1")
	text = text:gsub("<(https?://[^>]+)>", link_icon .. "%1")

	text = text:gsub("`([^`]*)`", "%1")
	text = text:gsub("%*%*([^*]-)%*%*", "%1")
	text = text:gsub("__([^_]-)__", "%1")
	text = text:gsub("%*([^*]-)%*", "%1")
	text = text:gsub("_([^_]-)_", "%1")
	text = text:gsub("==([^=]-)==", "%1")
	text = text:gsub("\\([\\`*_{}%[%]()#+%-.!|])", "%1")

	return text
end

local function rendered_width(text)
	return vim.fn.strdisplaywidth(markdown_render_width_text(text))
end

local function repeat_pad(pad_char, count)
	return string.rep(pad_char or " ", count)
end

local function pad_cell(text, width, align, pad_char)
	local display_width = rendered_width(text)
	local missing = math.max(0, width - display_width)

	if align == "right" then
		return repeat_pad(pad_char, missing) .. text
	elseif align == "center" then
		local left = math.floor(missing / 2)
		local right = missing - left
		return repeat_pad(pad_char, left) .. text .. repeat_pad(pad_char, right)
	else
		return text .. repeat_pad(pad_char, missing)
	end
end

local function build_separator(width, align)
	width = math.max(3, width)

	if align == "center" then
		return ":" .. string.rep("-", math.max(1, width - 2)) .. ":"
	elseif align == "right" then
		return string.rep("-", math.max(2, width - 1)) .. ":"
	elseif align == "left" then
		return ":" .. string.rep("-", math.max(2, width - 1))
	else
		return string.rep("-", width)
	end
end

local function detect_table(lines)
	if #lines < 2 then
		return nil
	end

	local rows = {}
	for _, line in ipairs(lines) do
		table.insert(rows, parse_row(line))
	end

	if #rows[2] == 0 then
		return nil
	end

	local has_separator = true
	for _, cell in ipairs(rows[2]) do
		if not is_separator_cell(cell) then
			has_separator = false
			break
		end
	end

	if not has_separator then
		return nil
	end

	return rows
end

local function format_rows(rows, opts)
	opts = opts or {}
	local pad_char = opts.pad_char or " "

	local col_count = 0
	for _, row in ipairs(rows) do
		col_count = math.max(col_count, #row)
	end

	local aligns = {}
	local widths = {}

	for i = 1, col_count do
		aligns[i] = "left"
		widths[i] = 3
	end

	for i, cell in ipairs(rows[2]) do
		aligns[i] = separator_align(cell)
	end

	for row_index, row in ipairs(rows) do
		if row_index ~= 2 then
			for col = 1, col_count do
				local text = row[col] or ""
				widths[col] = math.max(widths[col], rendered_width(text))
			end
		end
	end

	local formatted = {}

	for row_index, row in ipairs(rows) do
		local out = {}

		for col = 1, col_count do
			local text = row[col] or ""

			if row_index == 2 then
				table.insert(out, " " .. build_separator(widths[col], aligns[col]) .. " ")
			else
				table.insert(out, pad_char .. pad_cell(text, widths[col], aligns[col], pad_char) .. pad_char)
			end
		end

		table.insert(formatted, "|" .. table.concat(out, "|") .. "|")
	end

	return formatted
end

function M.format_table_at_cursor(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	if not is_table_candidate(lines[cursor_row + 1]) then
		vim.notify("当前光标不在 Markdown 表格中", vim.log.levels.WARN)
		return
	end

	local start_row = cursor_row
	while start_row > 0 and is_table_candidate(lines[start_row]) do
		start_row = start_row - 1
	end
	if not is_table_candidate(lines[start_row + 1]) then
		start_row = start_row + 1
	end

	local end_row = cursor_row
	while end_row + 2 <= #lines and is_table_candidate(lines[end_row + 2]) do
		end_row = end_row + 1
	end

	local block = vim.list_slice(lines, start_row + 1, end_row + 1)
	local rows = detect_table(block)

	if not rows then
		vim.notify("未识别到合法的 Markdown 表格块", vim.log.levels.WARN)
		return
	end

	local formatted = format_rows(rows, opts)
	vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, formatted)
end

function M.format_all_tables(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local row = 0
	local changed = 0

	while row < #lines do
		if not is_table_candidate(lines[row + 1]) then
			row = row + 1
		else
			local start_row = row
			local end_row = row
			while end_row + 2 <= #lines and is_table_candidate(lines[end_row + 2]) do
				end_row = end_row + 1
			end

			local block = vim.list_slice(lines, start_row + 1, end_row + 1)
			local rows = detect_table(block)
			if rows then
				local formatted = format_rows(rows, opts)
				vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, formatted)
				for i, line in ipairs(formatted) do
					lines[start_row + i] = line
				end
				changed = changed + 1
			end

			row = end_row + 1
		end
	end

	vim.notify(("已格式化 %d 个 Markdown 表格"):format(changed), vim.log.levels.INFO)
end

function M.debug_table_at_cursor()
	M.format_table_at_cursor({ pad_char = "-" })
end

function M.debug_all_tables()
	M.format_all_tables({ pad_char = "-" })
end

return M
