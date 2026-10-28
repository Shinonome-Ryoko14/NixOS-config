-- Options are automatically loaded before lazy.nvim startup

-- ================= Neovide 专属特化配置 =================
if vim.g.neovide then
  -- 不再强制全屏；需要时按 F11 切换
  vim.g.neovide_fullscreen = false

  -- 绑定 F11 快捷键切换全屏状态（全屏的底层响应非常灵敏）
  vim.keymap.set("n", "<F11>", function()
    vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
  end, { desc = "Toggle Fullscreen", silent = true })

  -- 调整这个值来控制毛玻璃的通透度
  vim.g.neovide_opacity = 0.75
  vim.g.neovide_window_blurred = true

  -- 光标个性化与音爆粒子特效
  vim.api.nvim_set_hl(0, "Cursor", { fg = "white", bg = "#FF8C42" })
  vim.api.nvim_set_hl(0, "iCursor", { fg = "white", bg = "#98FB98" })
  vim.opt.guicursor = "n-c:block-Cursor,v:block-vCursor,i-ci-ve:ver25-iCursor,r-cr:hor20,o:hor50"
  vim.g.neovide_cursor_vfx_mode = "sonicboom"
end

-- ================= 强制全窗口（含文件树）剥离背景 =================
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- 强行剥离 NeoTree 文件树的所有实体背景，让它彻底变透明，露出底层的毛玻璃
    local hl_groups = {
      "NeoTreeNormal",
      "NeoTreeNormalNC",
      "NeoTreeSignColumn",
      "NeoTreeEndOfBuffer",
      "Normal",
      "NormalNC",
    }
    for _, group in ipairs(hl_groups) do
      vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
    end

    -- 浮动窗口（LSP代码提示）单独给一层微弱的半透明深色
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1f2335" })
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "#1f2335" })
  end,
})

-- 与 Wayland 系统剪贴板同步（wl-copy 在 nvim wrapper 的 PATH 里）
vim.opt.clipboard = "unnamedplus"
