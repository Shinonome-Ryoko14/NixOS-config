{ config, lib, pkgs, osConfig, ... }:
let
  inherit (osConfig.my) configPath;
  full = osConfig.my.editor.neovim.profile == "full";
in
{
  # Link the live checkout when there is one, so plugin updates stay editable.
  xdg.configFile."nvim" = lib.mkIf full {
    source =
      if configPath != null
      then config.lib.file.mkOutOfStoreSymlink "${configPath}/modules/home/shell/neovim/nvim"
      else ./nvim;
  };
  # clangd 在没有 compile_commands.json 时默认调用 `clang`；用用户级配置指定
  # wrapper PATH 里的 g++，否则 libstdc++ / bits/stdc++.h 无法解析。
  xdg.configFile."clangd/config.yaml" = lib.mkIf full {
    force = true;
    text = ''
      CompileFlags:
        Compiler: g++
    '';
  };
  programs.neovim = {
    enable = true;
    # Keep the live ./nvim directory; load Home Manager's init code via the wrapper.
    sideloadInitLua = full;
    initLua = lib.optionalString (!full) ''
      vim.opt.number = true
      vim.opt.mouse = "a"
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.termguicolors = true
    '';
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    # Only on Neovim's PATH: nvim-treesitter (main) builds parsers with the
    # tree-sitter CLI and a C compiler; Mason installs npm-based servers; the
    # <F5> keymap compiles C++ with g++; clangd/clang-format come from
    # clang-tools. Make sure clangd is not installed by Mason.
    extraPackages = lib.optionals full [
      pkgs.tree-sitter
      pkgs.gcc
      pkgs.nodejs
      pkgs.clang-tools
    ];
  };
}
