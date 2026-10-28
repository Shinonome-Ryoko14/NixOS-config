{ lib, osConfig, ... }:
{
  imports = [
    ./neovim
    ./cli.nix
  ] ++ lib.optional (osConfig.my.shell.type == "fish") ./fish
    ++ lib.optional (osConfig.my.shell.type == "zsh") ./zsh.nix;
}
