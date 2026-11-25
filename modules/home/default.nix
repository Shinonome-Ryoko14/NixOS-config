{ pkgs, osConfig, ... }:
{
  imports = [
    ./shell
    ./desktop
    ./apps.nix
  ];
  programs.dank-material-shell.enable = osConfig.my.desktop.enable;
  home.enableNixpkgsReleaseCheck = false;

  home.username = osConfig.my.user.name;
  home.homeDirectory = osConfig.my.user.home;

  home.packages = with pkgs; [
    # archives
    zip
    xz
    unzip
    p7zip

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # nix related
    nix-output-monitor
  ];

  home.stateVersion = "25.05";
}
