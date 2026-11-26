{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.my;
  appCatalog = import ./app-catalog.nix;
  # Every switch defaults to off; hosts enable them.
  requires = enabled: dependency: name: dependencyName: {
    assertion = !enabled || dependency;
    message = "my.${name} requires my.${dependencyName}";
  };
in
{
  # Feature switches shared by the NixOS and Home Manager modules.
  # Hosts select them through their own default.nix.
  options.my = {
    user = {
      name = mkOption {
        type = types.str;
        example = "ryoko";
        description = ''
          The single desktop user managed by this configuration. Every host must
          set it explicitly; there is no default, so a fresh clone cannot silently
          create a user that already exists on someone else's machine.
        '';
      };
      home = mkOption {
        type = types.str;
        default = "/home/${cfg.user.name}";
        defaultText = lib.literalExpression "\"/home/\${config.my.user.name}\"";
        description = "Home directory of my.user.name.";
      };
    };

    configPath = mkOption {
      type = types.nullOr types.str;
      default = "${cfg.user.home}/nixos-config";
      defaultText = lib.literalExpression "\"\${config.my.user.home}/nixos-config\"";
      description = ''
        Checkout of this repository. Neovim and niri configs link into it so that
        edits apply without a rebuild; null ships read-only copies from the store.
      '';
    };

    home.imports = mkOption {
      type = types.listOf types.deferredModule;
      default = [ ];
      description = "Host-specific Home Manager modules for my.user.name.";
    };

    cli = {
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [ yazi fd fzf ripgrep eza bat gh jq just difftastic tmux ];
        description = "Base CLI packages; hosts may select a smaller set or add individual extra tools.";
      };
      extra.enable = mkEnableOption "commonly used command-line tools beyond the minimal system";
    };

    desktop = {
      enable = mkEnableOption "Niri with DankMaterialShell and Dank Greeter, Chinese input, audio and desktop utilities";
      utilities.enable = mkEnableOption "commonly used graphical tools: terminal, editor, audio and disk utilities";
      noctalia.enable = mkEnableOption "Noctalia Shell bar replacing the DMS DankBar";
      zekNiri.enable = mkEnableOption "ZEKniri look: Waybar bar, Noctalia panels, ZEK niri animations, blur and theme";
      wallpaperDir = mkOption {
        type = types.str;
        default = "${cfg.user.home}/Pictures/wallpaper";
        defaultText = lib.literalExpression "\"\${config.my.user.home}/Pictures/wallpaper\"";
        example = "/home/ryoko/图片/wallpaper";
        description = ''
          Directory the desktop reads wallpapers from. Override it on hosts that
          use a localized XDG directory (for example ~/图片/wallpaper).
        '';
      };
      outputs = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            mode = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "1920x1080@60.000";
            };
            scale = mkOption {
              type = types.nullOr types.number;
              default = null;
            };
            position = mkOption {
              type = types.nullOr (types.submodule {
                options = {
                  x = mkOption { type = types.int; };
                  y = mkOption { type = types.int; };
                };
              });
              default = null;
            };
          };
        });
        default = { };
        description = "Monitors keyed by connector name (`niri msg outputs`), for both the desktop and the Dank Greeter.";
      };
      outputsConfig = mkOption {
        type = types.lines;
        internal = true;
        readOnly = true;
        default = lib.concatStrings (lib.mapAttrsToList
          (name: o: "output \"${name}\" {\n"
            + lib.optionalString (o.mode != null) "    mode \"${o.mode}\"\n"
            + lib.optionalString (o.scale != null) "    scale ${builtins.toJSON o.scale}\n"
            + lib.optionalString (o.position != null) "    position x=${toString o.position.x} y=${toString o.position.y}\n"
            + "}\n")
          cfg.desktop.outputs);
        description = "niri KDL generated from my.desktop.outputs.";
      };
    };

    fonts.extra.enable = mkEnableOption "additional Chinese and typesetting fonts";

    hardware.bluetooth.enable = mkEnableOption "Bluetooth and its desktop applet";

    virtualisation.docker.enable = mkEnableOption "rootless Docker";

    # One switch per installed application. The catalog is shared with the
    # ryoko CLI, so `ryoko list` can describe every switch without a second
    # copy of the descriptions.
    apps = lib.mapAttrs
      (_: description: { enable = mkEnableOption description; })
      appCatalog;

    programs = {
      appimage.enable = mkEnableOption "AppImage execution support";
      nixLd.enable = mkEnableOption "compatibility loader for external binaries";
      steam.enable = mkEnableOption "Steam and its system integration";
    };
  };

  config.assertions = map
    (name: requires cfg.apps.${name}.enable cfg.desktop.enable "apps.${name}" "desktop")
    [ "edge" "chrome" "wechat" "qq" "neteaseMusic" "mpv" "vscode" ]
  ++ [
    (requires cfg.desktop.utilities.enable cfg.desktop.enable "desktop.utilities" "desktop")
    (requires cfg.desktop.noctalia.enable cfg.desktop.enable "desktop.noctalia" "desktop")
    (requires cfg.desktop.zekNiri.enable cfg.desktop.enable "desktop.zekNiri" "desktop")
    (requires cfg.desktop.zekNiri.enable cfg.desktop.noctalia.enable "desktop.zekNiri" "desktop.noctalia")
    (requires cfg.fonts.extra.enable cfg.desktop.enable "fonts.extra" "desktop")
  ];
}
