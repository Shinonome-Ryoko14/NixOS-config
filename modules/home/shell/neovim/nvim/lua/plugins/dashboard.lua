local header = [[
██████╗ ██╗   ██╗ ██████╗ ██╗  ██╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
██╔══██╗╚██╗ ██╔╝██╔═══██╗██║ ██╔╝██╔═══██╗██║   ██║██║████╗ ████║
██████╔╝ ╚████╔╝ ██║   ██║█████╔╝ ██║   ██║██║   ██║██║██╔████╔██║
██╔══██╗  ╚██╔╝  ██║   ██║██╔═██╗ ██║   ██║██║   ██║██║██║╚██╔╝██║
██║  ██║   ██║   ╚██████╔╝██║  ██╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║
╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝
        ]]
header = header:gsub("\r", "")

local rows = {}
for _, line in ipairs(vim.split(header, "\n", { plain = true })) do
  if line:match("%S") then
    rows[#rows + 1] = {
      text = line,
      prefix = vim.fn.strcharpart(line, 0, 43),
    }
  end
end

return {
  "folke/snacks.nvim",
  init = function()
    local ns = vim.api.nvim_create_namespace("ryoko_header_pink")
    vim.api.nvim_create_autocmd("User", {
      pattern = { "SnacksDashboardOpened", "SnacksDashboardUpdatePost" },
      callback = function()
        vim.api.nvim_set_hl(0, "RyokoPink", { fg = "#FFB6C1", bold = true })

        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype ~= "snacks_dashboard" then
          return
        end

        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
          for _, h in ipairs(rows) do
            local start = line:find(h.text, 1, true)
            if start then
              vim.api.nvim_buf_set_extmark(buf, ns, row - 1, start - 1, {
                end_col = start - 1 + #h.prefix,
                hl_group = "RyokoPink",
                priority = 5000,
              })
              break
            end
          end
        end
      end,
    })
  end,
  opts = {
    dashboard = {
      preset = { header = header },
    },
  },
}
