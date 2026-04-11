local api = vim.api

local M = {}

local winsize = nil
local cached_cell_size = nil

local function valid_cell_size(width, height)
    return type(width) == 'number'
        and type(height) == 'number'
        and width > 0
        and height > 0
end

local function tmux_cell_size()
    if vim.env.TMUX == nil or vim.env.TMUX == '' or vim.fn.executable('tmux') ~= 1 then
        return nil
    end

    local cmd = { 'tmux', 'display-message', '-p' }
    if vim.env.TMUX_PANE ~= nil and vim.env.TMUX_PANE ~= '' then
        vim.list_extend(cmd, { '-t', vim.env.TMUX_PANE })
    end
    vim.list_extend(cmd, { '#{client_cell_width} #{client_cell_height}' })

    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 then
        return nil
    end

    local width, height = (result.stdout or ''):match('(%d+)%s+(%d+)')
    width = tonumber(width)
    height = tonumber(height)

    if valid_cell_size(width, height) then
        return width, height
    end

    return nil
end

function M.size()
    if winsize == nil then
        winsize, err = require'mdmath.terminfo._system'.request_size()
        if not winsize then
            return nil, err
        end
    end

    return winsize
end

function M.cell_size()
    local size, err = M.size()

    if size and size.col > 0 and size.row > 0 and size.xpixel > 0 and size.ypixel > 0 then
        local width = size.xpixel / size.col
        local height = size.ypixel / size.row

        if valid_cell_size(width, height) then
            return width, height
        end
    end

    if cached_cell_size == nil then
        local width, height = tmux_cell_size()
        if valid_cell_size(width, height) then
            cached_cell_size = { width, height }
        else
            cached_cell_size = false
        end
    end

    if cached_cell_size and cached_cell_size ~= false then
        return cached_cell_size[1], cached_cell_size[2]
    end

    if err then
        error('Failed to get terminal cell size: ioctl error ' .. err .. ' and tmux fallback unavailable')
    end

    error('Failed to get terminal cell size: missing pixel size and tmux fallback unavailable')
end

function M.refresh()
    winsize = nil
    cached_cell_size = nil
end

local function create_autocmd()
    api.nvim_create_autocmd('VimResized', {
        callback = function()
            M.refresh()
        end
    })
end

if vim.in_fast_event() then
    vim.schedule(create_autocmd)
else
    create_autocmd()
end

return M
