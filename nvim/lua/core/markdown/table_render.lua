local M = {}

local ns = vim.api.nvim_create_namespace("user.markdown_table_render")
local augroup = vim.api.nvim_create_augroup("UserMarkdownTableRender", { clear = false })
local scheduled = {}
local global_setup = false
local state = {}

local function normalize_buf(bufnr)
	if not bufnr or bufnr == 0 then
		return vim.api.nvim_get_current_buf()
	end
	return bufnr
end

local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function is_table_candidate(line)
	return type(line) == "string" and line:find("|", 1, true) ~= nil
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

local function parse_row_positions(line)
	local cells = {}
	local start_byte = 1
	local escaped = false

	local function add_cell(end_byte)
		local raw = line:sub(start_byte, end_byte)
		local left = raw:match("^%s*") or ""
		local text = trim(raw)
		local start_col = start_byte - 1 + #left
		cells[#cells + 1] = {
			text = text,
			start_col = start_col,
			end_col = start_col + #text,
		}
	end

	for i = 1, #line do
		local ch = line:sub(i, i)
		if escaped then
			escaped = false
		elseif ch == "\\" then
			escaped = true
		elseif ch == "|" then
			add_cell(i - 1)
			start_byte = i + 1
		end
	end
	add_cell(#line)

	if line:sub(1, 1) == "|" then
		table.remove(cells, 1)
	end
	if line:sub(-1) == "|" then
		table.remove(cells, #cells)
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

local function table_at(lines, row)
	if row + 1 > #lines then
		return nil
	end

	if not is_table_candidate(lines[row]) or not is_table_candidate(lines[row + 1]) then
		return nil
	end

	local header = parse_row(lines[row])
	local separator = parse_row(lines[row + 1])
	if #header == 0 or #separator == 0 then
		return nil
	end

	for _, cell in ipairs(separator) do
		if not is_separator_cell(cell) then
			return nil
		end
	end

	local col_count = math.max(#header, #separator)
	local last = row + 1
	while last + 1 <= #lines and is_table_candidate(lines[last + 1]) do
		local cells = parse_row(lines[last + 1])
		if #cells == 0 then
			break
		end
		col_count = math.max(col_count, #cells)
		last = last + 1
	end

	local rows = {}
	for i = row, last do
		rows[#rows + 1] = parse_row(lines[i])
	end

	return {
		start_row = row - 1,
		end_row = last - 1,
		col_count = col_count,
		rows = rows,
	}
end

local function find_tables(lines)
	local tables = {}
	local row = 1

	while row <= #lines do
		local table_info = table_at(lines, row)
		if table_info then
			tables[#tables + 1] = table_info
			row = table_info.end_row + 2
		else
			row = row + 1
		end
	end

	return tables
end

local function link_icon(destination)
	if destination:match("github%.com") then
		return "󰊤 "
	end
	return "󰌹 "
end

local function width(text)
	return vim.fn.strdisplaywidth(text or "")
end

local function append_text(chunks, text, hl)
	if text == nil or text == "" then
		return
	end
	hl = hl or "Normal"
	local last = chunks[#chunks]
	if last and last[2] == hl then
		last[1] = last[1] .. text
	else
		chunks[#chunks + 1] = { text, hl }
	end
end

local function append_chunks(target, source)
	for _, chunk in ipairs(source or {}) do
		append_text(target, chunk[1], chunk[2])
	end
end

local function chunks_width(chunks)
	local result = 0
	for _, chunk in ipairs(chunks or {}) do
		result = result + width(chunk[1])
	end
	return result
end

local function render_inline_chunks(text)
	text = text or ""
	local chunks = {}
	local index = 1

	while index <= #text do
		local rest = text:sub(index)
		local _, finish, label, destination

		_, finish, label, destination = rest:find("^!%[([^%]]*)%]%(([^%)]*)%)")
		if finish then
			append_text(chunks, "󰥶 ", "RenderMarkdownLink")
			append_text(chunks, label, "RenderMarkdownLink")
			index = index + finish
			goto continue
		end

		_, finish, label, destination = rest:find("^%[([^%]]*)%]%(([^%)]*)%)")
		if finish then
			append_text(chunks, link_icon(destination), "RenderMarkdownLink")
			append_text(chunks, label, "RenderMarkdownLink")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^<([%w%._%+%-]+@[%w%._%-]+)>")
		if finish then
			append_text(chunks, "󰀓 ", "RenderMarkdownLink")
			append_text(chunks, label, "RenderMarkdownLink")
			index = index + finish
			goto continue
		end

		_, finish, destination = rest:find("^(<https?://[^>]+>)")
		if finish then
			local unwrapped = destination:sub(2, -2)
			append_text(chunks, link_icon(unwrapped), "RenderMarkdownLink")
			append_text(chunks, unwrapped, "RenderMarkdownLink")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^`([^`]*)`")
		if finish then
			append_text(chunks, label, "@markup.raw")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^%*%*([^*]-)%*%*")
		if finish then
			append_text(chunks, label, "@markup.strong")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^__([^_]-)__")
		if finish then
			append_text(chunks, label, "@markup.strong")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^~~([^~]-)~~")
		if finish then
			append_text(chunks, label, "@markup.strikethrough")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^==([^=]-)==")
		if finish then
			append_text(chunks, label, "RenderMarkdownInlineHighlight")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^%*([^*]-)%*")
		if finish then
			append_text(chunks, label, "@markup.italic")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^_([^_]-)_")
		if finish then
			append_text(chunks, label, "@markup.italic")
			index = index + finish
			goto continue
		end

		_, finish, label = rest:find("^\\([\\`*_{}%[%]()#+%-.!|])")
		if finish then
			append_text(chunks, label, "Normal")
			index = index + finish
			goto continue
		end

		local char = vim.fn.strcharpart(rest, 0, 1)
		append_text(chunks, char, "Normal")
		index = index + #char

		::continue::
	end

	return chunks
end

local function pad_cell(chunks, target_width, align)
	local missing = math.max(0, target_width - chunks_width(chunks))
	local padded = {}

	if align == "right" then
		append_text(padded, string.rep(" ", missing), "Normal")
		append_chunks(padded, chunks)
	elseif align == "center" then
		local left = math.floor(missing / 2)
		local right = missing - left
		append_text(padded, string.rep(" ", left), "Normal")
		append_chunks(padded, chunks)
		append_text(padded, string.rep(" ", right), "Normal")
	else
		append_chunks(padded, chunks)
		append_text(padded, string.rep(" ", missing), "Normal")
	end

	return padded
end

local function build_separator(col_width, align)
	col_width = math.max(3, col_width)

	if align == "center" then
		return ":" .. string.rep("-", math.max(1, col_width - 2)) .. ":"
	elseif align == "right" then
		return string.rep("-", math.max(2, col_width - 1)) .. ":"
	elseif align == "left" then
		return ":" .. string.rep("-", math.max(2, col_width - 1))
	else
		return string.rep("-", col_width)
	end
end

local function render_table(table_info)
	local aligns = {}
	local widths = {}
	local rendered_cells = {}

	for col = 1, table_info.col_count do
		aligns[col] = separator_align(table_info.rows[2][col] or "---")
		widths[col] = 3
	end

	for row_index, row in ipairs(table_info.rows) do
		rendered_cells[row_index] = {}
		if row_index ~= 2 then
			for col = 1, table_info.col_count do
				local rendered = render_inline_chunks(row[col] or "")
				rendered_cells[row_index][col] = rendered
				widths[col] = math.max(widths[col], chunks_width(rendered))
			end
		end
	end

	local rendered_lines = {}
	local max_width = 0
	for row_index, _ in ipairs(table_info.rows) do
		local out = {}
		append_text(out, "|", "RenderMarkdownTableRow")

		for col = 1, table_info.col_count do
			if row_index == 2 then
				append_text(out, " " .. build_separator(widths[col], aligns[col]) .. " ", "RenderMarkdownTableHead")
			else
				append_text(out, " ", "Normal")
				append_chunks(out, pad_cell(rendered_cells[row_index][col] or {}, widths[col], aligns[col]))
				append_text(out, " ", "Normal")
			end
			append_text(out, "|", "RenderMarkdownTableRow")
		end

		rendered_lines[row_index] = out
		max_width = math.max(max_width, chunks_width(out))
	end

	return rendered_lines, max_width
end

local function table_widths(table_info)
	local aligns = {}
	local widths = {}

	for col = 1, table_info.col_count do
		aligns[col] = separator_align(table_info.rows[2][col] or "---")
		widths[col] = 3
	end

	for row_index, row in ipairs(table_info.rows) do
		if row_index ~= 2 then
			for col = 1, table_info.col_count do
				widths[col] = math.max(widths[col], chunks_width(render_inline_chunks(row[col] or "")))
			end
		end
	end

	return widths, aligns
end

local function display_offset_to_byte_col(text, display_offset)
	display_offset = math.max(0, display_offset or 0)
	local current = 0
	local byte_col = 0
	local char_count = vim.fn.strchars(text or "")

	for i = 0, char_count - 1 do
		local ch = vim.fn.strcharpart(text, i, 1)
		local ch_width = width(ch)
		if current + ch_width > display_offset then
			return byte_col
		end
		current = current + ch_width
		byte_col = byte_col + #ch
	end

	return #(text or "")
end

local function source_col_for_display_col(lines, table_info, row, display_col)
	local row_index = row - table_info.start_row + 1
	local source = lines[row + 1] or ""

	if row_index == 2 then
		return math.min(#source, math.max(0, display_col))
	end

	local source_cells = parse_row_positions(source)
	local widths = table_widths(table_info)

	local current = 1 -- after the leading '|'
	for col = 1, table_info.col_count do
		local cell = source_cells[col]
		local content_start = current + 1
		local content_end = content_start + widths[col]
		local pipe_col = content_end + 1

		if display_col < content_start then
			return cell and cell.start_col or math.min(#source, math.max(0, display_col))
		elseif display_col <= content_end then
			if not cell then
				return math.min(#source, math.max(0, display_col))
			end
			local byte_offset = display_offset_to_byte_col(cell.text, display_col - content_start)
			return math.min(#source, cell.start_col + byte_offset)
		elseif display_col <= pipe_col then
			return cell and cell.end_col or math.min(#source, math.max(0, display_col))
		end

		current = pipe_col + 1
	end

	return #source
end

local function find_table_for_row(lines, row)
	for _, table_info in ipairs(find_tables(lines)) do
		if row >= table_info.start_row and row <= table_info.end_row then
			return table_info
		end
	end
	return nil
end

local function clip_chunks(chunks, start_col, target_width)
	start_col = math.max(0, start_col or 0)
	target_width = math.max(0, target_width or 0)
	if target_width == 0 then
		return {}
	end

	local out = {}
	local current_col = 0
	local end_col = start_col + target_width

	for _, chunk in ipairs(chunks) do
		local text = chunk[1]
		local hl = chunk[2] or "Normal"
		local char_count = vim.fn.strchars(text)

		for i = 0, char_count - 1 do
			local ch = vim.fn.strcharpart(text, i, 1)
			local ch_width = width(ch)
			local next_col = current_col + ch_width

			if next_col <= start_col then
				current_col = next_col
			elseif current_col >= end_col then
				break
			else
				if current_col < start_col then
					append_text(out, string.rep(" ", next_col - start_col), "Normal")
				elseif next_col > end_col then
					append_text(out, string.rep(" ", end_col - current_col), "Normal")
				else
					append_text(out, ch, hl)
				end
				current_col = next_col
			end
		end
	end

	local missing = target_width - chunks_width(out)
	if missing > 0 then
		append_text(out, string.rep(" ", missing), "Normal")
	end

	return out
end

local function should_render()
	local mode = vim.api.nvim_get_mode().mode
	return not mode:match("^[iR]")
end

local function win_text_width(win)
	local info = vim.fn.getwininfo(win)[1]
	if not info then
		return vim.api.nvim_win_get_width(win)
	end
	return math.max(1, info.width - info.textoff)
end

local function win_view(win)
	local ok, view = pcall(vim.api.nvim_win_call, win, vim.fn.winsaveview)
	if not ok then
		return { leftcol = 0 }
	end
	return view
end

local function win_visible_rows(win)
	local ok, rows = pcall(vim.api.nvim_win_call, win, function()
		return { vim.fn.line("w0") - 1, vim.fn.line("w$") - 1 }
	end)
	if not ok then
		return { 0, math.huge }
	end
	return rows
end

function M.clear(bufnr)
	bufnr = normalize_buf(bufnr)
	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end
	state[bufnr] = nil
end

function M.update(bufnr, win)
	bufnr = normalize_buf(bufnr)
	win = win or vim.api.nvim_get_current_win()

	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(win) then
		return
	end
	if vim.api.nvim_win_get_buf(win) ~= bufnr then
		return
	end

	if vim.bo[bufnr].filetype ~= "markdown" or not should_render() then
		M.clear(bufnr)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local visible = win_visible_rows(win)
	local view = win_view(win)
	local text_width = win_text_width(win)
	local previous = state[bufnr] or {}
	local previous_ids = previous.ids or {}
	local next_ids = {}
	local touched = {}

	for _, table_info in ipairs(find_tables(lines)) do
		if table_info.end_row >= visible[1] and table_info.start_row <= visible[2] then
			local rendered_lines = render_table(table_info)
			-- Do not clamp per table.  All tables follow the same window leftcol,
			-- so short tables slide into right-side padding instead of stopping
			-- earlier than long tables.
			local leftcol = view.leftcol or 0

			for index, rendered in ipairs(rendered_lines) do
				local row = table_info.start_row + index - 1
				if row >= visible[1] and row <= visible[2] then
					local clipped = clip_chunks(rendered, leftcol, text_width)
					local opts = {
						id = previous_ids[row],
						virt_text = clipped,
						virt_text_win_col = 0,
						priority = 20000,
						hl_mode = "replace",
						strict = false,
					}
					next_ids[row] = vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, opts)
					touched[row] = true
				end
			end
		end
	end

	for row, id in pairs(previous_ids) do
		if not touched[row] then
			pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, id)
		end
	end
	state[bufnr] = { ids = next_ids }
end

function M.schedule(bufnr, win)
	bufnr = normalize_buf(bufnr)
	win = win or vim.api.nvim_get_current_win()

	if scheduled[bufnr] then
		return
	end

	scheduled[bufnr] = true
	vim.schedule(function()
		scheduled[bufnr] = nil
		if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_win_is_valid(win) then
			M.update(bufnr, win)
		end
	end)
end

function M.setup(bufnr)
	bufnr = normalize_buf(bufnr)
	if vim.b[bufnr].markdown_table_render_setup then
		M.schedule(bufnr)
		return
	end
	vim.b[bufnr].markdown_table_render_setup = true

	vim.api.nvim_create_autocmd({
		"BufWinEnter",
		"CursorMoved",
		"TextChanged",
		"InsertLeave",
		"ModeChanged",
	}, {
		group = augroup,
		buffer = bufnr,
		callback = function(args)
			M.schedule(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd({
		"InsertEnter",
		"BufLeave",
	}, {
		group = augroup,
		buffer = bufnr,
		callback = function(args)
			M.clear(args.buf)
		end,
	})

	if not global_setup then
		global_setup = true
		vim.api.nvim_create_autocmd("WinScrolled", {
			group = augroup,
			callback = function()
				local win = vim.api.nvim_get_current_win()
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].filetype == "markdown" then
					M.schedule(buf, win)
				end
			end,
		})
	end

	M.schedule(bufnr)
end

return M
