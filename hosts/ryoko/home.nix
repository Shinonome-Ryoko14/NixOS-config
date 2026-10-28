{ lib, config, ... }:
{
  home.stateVersion = lib.mkForce "26.05";

  # Use the official OpenCode binary from ~/.opencode/bin instead of the
  # nixpkgs build. The two versions share ~/.local/share/opencode, and the
  # 1.x schema cannot open the database created by 2.x.
  home.sessionPath = [ "${config.home.homeDirectory}/.opencode/bin" ];

  programs.git.settings.user = lib.mkForce {
    name = "Shinonome-Ryoko14";
    email = "w13949636385@gmail.com";
  };

  programs.jujutsu.settings.user = lib.mkForce {
    name = "Shinonome-Ryoko14";
    email = "w13949636385@gmail.com";
  };

  xresources.properties."Xft.dpi" = lib.mkForce 96;

  # Keep this host's Fcitx5 input method list: a US keyboard layout with Rime
  # as the default engine, instead of the shared module's group.
  xdg.configFile."fcitx5/profile" = lib.mkForce {
    source = ./fcitx5-profile;
    force = true;
  };
}
