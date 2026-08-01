local is_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil

if is_ssh then
    vim.g.clipboard = "osc52"
end
