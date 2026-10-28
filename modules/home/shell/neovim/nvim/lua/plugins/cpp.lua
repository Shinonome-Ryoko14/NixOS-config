-- C / C++ 现代化开发配置（NixOS 适配版）
-- 依赖 neovim wrapper 的 PATH: g++ (gcc 16.2), clangd, clang-format, clang-tidy
return {
  -- ---------------------------------------------------------------
  -- clangd：沿用 LazyVim lang.clangd extra 的启动参数，
  --         关闭 Mason 管理，直接使用 wrapper PATH 里的 clangd
  -- ---------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.clangd = vim.tbl_deep_extend("force", opts.servers.clangd or {}, {
        -- clangd 由 neovim wrapper 的 PATH 提供。
        -- Mason 里也有 clangd 包，不关掉的话 LazyVim 会把它交给
        -- mason-lspconfig，未通过 Mason 安装时就不会 vim.lsp.enable。
        mason = false,
      })
      -- 系统头文件（bits/stdc++.h / libstdc++）由 ~/.config/clangd/config.yaml
      -- 里的 `CompileFlags.Compiler: g++` 负责，见 modules/home/shell/neovim/default.nix
    end,
  },

  -- ---------------------------------------------------------------
  -- clang-format：作为 C / C++ 的默认格式化器（保存时自动格式化）
  -- 风格由 ~/.clang-format 控制
  -- ---------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
      },
    },
  },
}
