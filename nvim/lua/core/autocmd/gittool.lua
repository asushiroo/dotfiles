local git_tool = vim.env.NVIM_GIT_TOOL

if git_tool == nil or git_tool == "" then
	return
end

local state = {
	hint_buf = nil,
	hint_visible = true,
	hint_win = nil,
	keymaps_ready = false,
	label_order = {},
	label_to_buf = {},
	label_to_win = {},
	window_files = {},
}

local function split_env(name)
	local value = vim.env[name]
	local items = {}

	if value == nil or value == "" then
		return items
	end

	for item in value:gmatch("[^\n]+") do
		table.insert(items, item)
	end

	return items
end

local function display_path(path)
	if path == nil or path == "" then
		return ""
	end

	local shortened = vim.fn.fnamemodify(path, ":~:.")
	if vim.fn.strdisplaywidth(shortened) <= 36 then
		return shortened
	end

	return "..." .. vim.fn.fnamemodify(path, ":t")
end

local function close_hint()
	if state.hint_win ~= nil and vim.api.nvim_win_is_valid(state.hint_win) then
		vim.api.nvim_win_close(state.hint_win, true)
	end

	state.hint_win = nil

	if state.hint_buf ~= nil and vim.api.nvim_buf_is_valid(state.hint_buf) then
		pcall(vim.api.nvim_buf_delete, state.hint_buf, { force = true })
	end

	state.hint_buf = nil
end

local function build_source_hint()
	local hints = {}
	local slot = 1

	for _, label in ipairs(state.label_order) do
		if label ~= "MERGED" then
			table.insert(hints, string.format("<leader>%d %s", slot, label))
			slot = slot + 1
		end
	end

	return table.concat(hints, "  ")
end

local function build_hint_lines()
	if git_tool == "mergetool" then
		return {
			"Git mergetool",
			"[c / ]c jump to prev / next conflict",
			build_source_hint() .. " -> apply into MERGED",
			"<leader>du refresh diff  <leader>dw write MERGED",
			"<leader>dh toggle hint  <leader>dq confirm quit",
		}
	end

	return {
		"Git difftool",
		"[c / ]c jump to prev / next diff hunk",
		"do / dp get or put current diff hunk",
		"<leader>dh toggle hint  <leader>dq quit all windows",
	}
end

local function open_hint()
	if not state.hint_visible then
		return
	end

	close_hint()

	local lines = build_hint_lines()
	local width = 0

	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end

	state.hint_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.hint_buf].bufhidden = "wipe"
	vim.api.nvim_buf_set_lines(state.hint_buf, 0, -1, false, lines)

	state.hint_win = vim.api.nvim_open_win(state.hint_buf, false, {
		border = "rounded",
		col = math.max(vim.o.columns - width - 6, 0),
		focusable = false,
		height = #lines,
		noautocmd = true,
		relative = "editor",
		row = 1,
		style = "minimal",
		width = width + 2,
		zindex = 200,
	})

	vim.api.nvim_set_option_value("winblend", 5, { win = state.hint_win })
end

local function toggle_hint()
	state.hint_visible = not state.hint_visible

	if state.hint_visible then
		open_hint()
		return
	end

	close_hint()
end

local function apply_diffopt()
	for _, item in ipairs({
		"algorithm:histogram",
		"indent-heuristic",
		"linematch:60",
	}) do
		if not vim.tbl_contains(vim.opt.diffopt:get(), item) then
			vim.opt.diffopt:append(item)
		end
	end
end

local function refresh_windows()
	state.label_to_buf = {}
	state.label_to_win = {}

	local wins = vim.api.nvim_tabpage_list_wins(0)
	for index, label in ipairs(state.label_order) do
		local win = wins[index]
		if win ~= nil and vim.api.nvim_win_is_valid(win) then
			local bufnr = vim.api.nvim_win_get_buf(win)
			local file = state.window_files[index] or vim.api.nvim_buf_get_name(bufnr)
			local winbar = string.format(" %s %s ", label, display_path(file))

			state.label_to_buf[label] = bufnr
			state.label_to_win[label] = win
			vim.api.nvim_set_option_value("winbar", winbar, { win = win })
		end
	end
end

local function with_merged_win(fn)
	local merged_win = state.label_to_win.MERGED
	if merged_win ~= nil and vim.api.nvim_win_is_valid(merged_win) then
		vim.api.nvim_set_current_win(merged_win)
	end

	fn()
end

local function diffget_from(label)
	local bufnr = state.label_to_buf[label]
	if bufnr == nil then
		vim.notify("Missing " .. label .. " window", vim.log.levels.WARN)
		return
	end

	with_merged_win(function()
		vim.cmd("diffget " .. bufnr)
		vim.cmd("diffupdate")
	end)
end

local function set_keymaps()
	if state.keymaps_ready then
		return
	end

	state.keymaps_ready = true

	local opts = { silent = true }

	vim.keymap.set("n", "<leader>dh", toggle_hint, vim.tbl_extend("force", opts, {
		desc = "Toggle git tool hint",
	}))
	vim.keymap.set("n", "<leader>dq", function()
		vim.cmd("confirm qall")
	end, vim.tbl_extend("force", opts, {
		desc = "Quit git tool",
	}))

	if git_tool ~= "mergetool" then
		return
	end

	local slot = 1
	for _, label in ipairs(state.label_order) do
		if label ~= "MERGED" then
			local lhs = "<leader>" .. slot
			vim.keymap.set("n", lhs, function()
				diffget_from(label)
			end, vim.tbl_extend("force", opts, {
				desc = "Use " .. label,
			}))
			slot = slot + 1
		end
	end

	vim.keymap.set("n", "<leader>du", function()
		vim.cmd("diffupdate")
	end, vim.tbl_extend("force", opts, {
		desc = "Refresh diff",
	}))
	vim.keymap.set("n", "<leader>dw", function()
		with_merged_win(function()
			vim.cmd("write")
		end)
	end, vim.tbl_extend("force", opts, {
		desc = "Write merged buffer",
	}))
end

state.label_order = split_env("NVIM_GIT_WINDOW_LABELS")
state.window_files = split_env("NVIM_GIT_WINDOW_FILES")

if #state.label_order == 0 then
	if git_tool == "mergetool" then
		state.label_order = { "LOCAL", "BASE", "REMOTE", "MERGED" }
	else
		state.label_order = { "LOCAL", "REMOTE" }
	end
end

local group = vim.api.nvim_create_augroup("GitToolPrompt", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
	group = group,
	callback = function()
		vim.schedule(function()
			apply_diffopt()
			refresh_windows()
			set_keymaps()
			open_hint()
		end)
	end,
})

vim.api.nvim_create_autocmd({ "TabEnter", "VimResized", "WinEnter" }, {
	group = group,
	callback = function()
		vim.schedule(function()
			refresh_windows()
			open_hint()
		end)
	end,
})
