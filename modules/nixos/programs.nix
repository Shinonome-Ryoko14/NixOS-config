{ config, ... }:
let
  cfg = config.my.programs;
in
{
  programs.nix-ld.enable = cfg.nixLd.enable;
  programs.appimage = { enable = cfg.appimage.enable; binfmt = cfg.appimage.enable; };
  programs.steam.enable = cfg.steam.enable;
}
