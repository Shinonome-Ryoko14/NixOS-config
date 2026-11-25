{ lib, pkgs, ... }:
{
  my = {
    user.name = "ryoko";
    configPath = "/home/ryoko/nixos-config";
    home.imports = [ ./home.nix ];

    cli.extra.enable = true;

    apps = {
      edge.enable = true;
      chrome.enable = true;
      wechat.enable = true;
      qq.enable = true;
      neteaseMusic.enable = true;
      mpv.enable = true;
      vscode.enable = true;
    };

    desktop = {
      enable = true;
      utilities.enable = true;
      noctalia.enable = true;
      zekNiri.enable = true;
      # 本机沿用带中文目录名的壁纸目录。
      wallpaperDir = "/home/ryoko/图片/wallpaper";
      outputs."eDP-1" = {
        mode = "1920x1080@60.000";
        scale = 1;
      };
    };

    fonts.extra.enable = true;
    hardware.bluetooth.enable = true;

    programs = {
      appimage.enable = true;
      nixLd.enable = true;
      steam.enable = true;
    };

    # Distributed-Seckill 本地依赖 MySQL/Redis
    virtualisation.docker.enable = true;
  };

  boot.loader = {
    grub.enable = lib.mkForce false;
    systemd-boot.enable = lib.mkForce true;
  };

  hardware.graphics.enable = true;

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  console.keyMap = "us";

  services.printing.enable = true;
  security.rtkit.enable = true;
  programs.firefox.enable = true;
  programs.clash-verge.enable = true;

  programs.appimage.package = lib.mkForce (pkgs.appimage-run.override {
    extraPkgs = pkgs: [ pkgs.libepoxy pkgs.libffi_3_3 ];
  });

  system.stateVersion = lib.mkForce "26.05";
}
