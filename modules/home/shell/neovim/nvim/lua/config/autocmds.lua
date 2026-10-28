-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- ~/.config/nvim/lua/config/autocmds.lua

local function set_cursor_colors()
  -- 强制定义 Normal 模式光标为日落色
  vim.api.nvim_set_hl(0, "Cursor", { fg = "#FFFFFF", bg = "#B794F4", force = true })
  -- 强制定义 Insert 模式光标为浅绿色
  vim.api.nvim_set_hl(0, "iCursor", { fg = "#FFFFFF", bg = "#98FB98", force = true })
  -- Visual 模式：粉蓝色 (新添加)
  vim.api.nvim_set_hl(0, "vCursor", { fg = "#FFFFFF", bg = "#FFBBDD", force = true })
end

-- 确保在主题加载后执行
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = set_cursor_colors,
})

-- 立即执行一次
set_cursor_colors()
