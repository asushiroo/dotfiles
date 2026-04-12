-- 将方向键下映射为向下滚动一行
vim.keymap.set({ "n", "v" }, "<Down>", "<C-e>", { desc = "Scroll down" })
-- 将方向键上映射为向上滚动一行
vim.keymap.set({ "n", "v" }, "<Up>", "<C-y>", { desc = "Scroll up" })
-- 将方向键左映射为向左横向滚动
vim.keymap.set({ "n", "v" }, "<Left>", "5zh", { desc = "Scroll left" })
-- 将方向键右映射为向右横向滚动
vim.keymap.set({ "n", "v" }, "<Right>", "5zl", { desc = "Scroll right" })
vim.g.mapleader = " "
vim.g.maplocalleader = ","
