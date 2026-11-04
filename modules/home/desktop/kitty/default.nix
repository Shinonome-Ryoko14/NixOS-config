{ config, lib, pkgs, osConfig, ... }:
lib.mkIf osConfig.my.desktop.enable {
  # ZEKniri supplies ~/.config/kitty when enabled.
  xdg.configFile."kitty" = lib.mkIf (!osConfig.my.desktop.zekNiri.enable) {
    source = ./config;
    recursive = true;
  };
  # ZEKniri ships its own kitty.conf; do not let the upstream module also
  # generate kitty/kitty.conf next to the recursive directory link.
  programs.kitty.enable = !osConfig.my.desktop.zekNiri.enable;
}
