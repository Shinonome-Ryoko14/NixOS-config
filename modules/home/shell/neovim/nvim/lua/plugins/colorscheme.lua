return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "storm", -- 可选: "night", "moon", "day"
      transparent = true,
      styles = {
        comments = { italic = true },
        sidebars = "transparent",
        floats = "transparent",
      },
      --- @param hl table
      --- @param c table
      on_highlights = function(hl, c)
        -- 注释改成较亮的蓝绿色 (Teal)
        hl.Comment = { fg = c.cyan, italic = true }
      end,
    },
  },
}
