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

-- ================= kitty：终端光标颜色随模式变化 =================
-- 终端光标由 kitty 绘制，上面的 Cursor/iCursor 高亮组只在 Neovide 生效，
-- 所以这里用 kitty 的 OSC 21 协议直接改光标颜色。
if not vim.g.neovide and (vim.env.KITTY_WINDOW_ID or vim.env.TERM == "xterm-kitty") then
  local function cursor_color(mode)
    local m = mode:sub(1, 1)
    if m == "i" then
      return "#98FB98" -- Insert：浅绿
    elseif m == "v" or m == "V" or m == "\22" or m == "s" or m == "S" or m == "\19" then
      return "#FFBBDD" -- Visual / Select：粉蓝
    elseif m == "R" then
      return "#FF8C42" -- Replace：橙
    end
    return "#B794F4" -- Normal：紫
  end

  local function emit(color)
    local seq = color and ("\27]21;cursor=" .. color .. "\27\\") or "\27]21;cursor\27\\"
    io.stdout:write(seq)
    io.stdout:flush()
  end

  vim.api.nvim_create_autocmd("ModeChanged", {
    callback = function()
      emit(cursor_color(vim.api.nvim_get_mode().mode))
    end,
  })

  -- 退出时恢复 kitty.conf 里的 cursor 颜色
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      emit(nil)
    end,
  })

  emit(cursor_color(vim.api.nvim_get_mode().mode))
end
