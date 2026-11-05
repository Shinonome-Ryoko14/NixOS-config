{ lib, pkgs, ... }:
{
  imports = [
    ../../profiles/workstation.nix
  ];

  my = {
    user.name = "ryoko";
    configPath = "/home/ryoko/nixos-config";
    home.imports = [ ./home.nix ];
    shell.type = "zsh";
    nix.cacheProfile = "public";

    ai.enable = lib.mkForce false;
    network.edunet.enable = lib.mkForce false;

    apps = {
      edge.enable = true;
      chrome.enable = true;
      wechat.enable = true;
      qq.enable = true;
      neteaseMusic.enable = true;
    };
    programs.appimage.enable = true;
    programs.steam.enable = true;
    desktop.wallpaperEngine.enable = false;
    desktop.noctalia.enable = true;
    desktop.zekNiri.enable = true;
    # 本机沿用带中文目录名的壁纸目录;其他主机默认 ~/Pictures/wallpaper。
    desktop.wallpaperDir = "/home/ryoko/图片/wallpaper";
    desktop.outputs."eDP-1" = {
      mode = "1920x1080@60.000";
      scale = 1;
    };
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

  services.openssh.enable = lib.mkForce false;
  programs.mosh.enable = lib.mkForce false;
  networking.firewall.allowedUDPPortRanges = lib.mkForce [ ];

  system.stateVersion = lib.mkForce "26.05";
}
