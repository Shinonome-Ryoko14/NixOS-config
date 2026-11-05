{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.my;
  # Every switch defaults to off; profiles and hosts enable them.
  requires = enabled: dependency: name: dependencyName: {
    assertion = !enabled || dependency;
    message = "my.${name} requires my.${dependencyName}";
  };
in
{
  # Feature switches shared by the NixOS and Home Manager modules.
  # Hosts select them through profiles/ and their own default.nix.
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
    shell = {
      type = mkOption {
        type = types.enum [ "fish" "zsh" ];
        default = "fish";
        description = "Login shell managed by Home Manager.";
      };
      profile = mkOption {
        type = types.enum [ "full" "minimal" ];
        default = "full";
        description = "Fish profile; minimal keeps Starship and zoxide but omits Atuin and nix-index/comma.";
      };
    };
    editor.neovim.profile = mkOption {
      type = types.enum [ "full" "minimal" ];
      default = "full";
      description = "Neovim profile; minimal ships a basic init without LazyVim or its development tools.";
    };
    nix.cacheProfile = mkOption {
      type = types.enum [ "private" "public" ];
      default = "public";
      description = "Cache policy; public uses only cache.nixos.org and requires no credentials, private additionally enables the Attic cache in secrets/attic-netrc.age.";
    };
    ai.enable = mkEnableOption "Claude Code, Codex and OpenCode CLI tools";

    desktop = {
      enable = mkEnableOption "Niri with DankMaterialShell and Dank Greeter, Chinese input, audio and desktop utilities";
      utilities.enable = mkEnableOption "commonly used graphical tools: terminal, editor, audio and disk utilities";
      graphicalBoot = {
        enable = mkEnableOption "quiet boot with the DMS Plymouth theme and Dank Greeter handoff";
        scale = mkOption {
          type = types.ints.positive;
          default = 1;
          description = "Display scale used to render the Plymouth theme assets.";
        };
      };
      greeter.extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Host-specific niri configuration for the Dank Greeter, such as outputs.";
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
      wallpaperEngine.enable = mkEnableOption "Wallpaper Engine animated wallpapers with the DMS plugin";
      wallpaperDir = mkOption {
        type = types.str;
        default = "${cfg.user.home}/Pictures/wallpaper";
        defaultText = lib.literalExpression "\"\${config.my.user.home}/Pictures/wallpaper\"";
        example = "/home/ryoko/图片/wallpaper";
        description = ''
          Directory the desktop reads wallpapers from and where the ZEK-niri
          activation seeds its bundled wallpapers. Override it on hosts that use
          a localized XDG directory (for example ~/图片/wallpaper).
        '';
      };
      noctalia.enable = mkEnableOption "Noctalia Shell bar replacing the DMS DankBar";
      zekNiri.enable = mkEnableOption "ZEKniri look: Waybar bar, Noctalia panels, ZEK niri animations, blur and theme";
      codexComputerUse.enable = mkEnableOption "Codex Desktop Computer Use integration";
      easyeffects.enable = mkEnableOption "EasyEffects microphone denoising";
      phone.enable = mkEnableOption "Valent / KDE Connect phone integration";
      screenCast.enable = mkEnableOption "GNOME Network Displays and Wi-Fi display ports";
    };

    input.speech = {
      enable = mkEnableOption "speech recognition";
      backend = mkOption {
        type = types.enum [ "vocotype" "vinput" ];
        default = "vocotype";
        description = "Fcitx5 speech recognition backend.";
      };
      doubao.enable = mkEnableOption "Doubao speech credentials and worker integration";
    };
    input.vtype.enable = mkEnableOption "VType (WeChat Pinyin) Fcitx5 addon; the engine is fetched by wetype-setup";

    fonts = {
      extra.enable = mkEnableOption "additional Chinese and typesetting fonts";
      windows.enable = mkEnableOption "Windows fonts from chinese-fonts-overlay";
    };

    hardware.bluetooth.enable = mkEnableOption "Bluetooth and its desktop applet";
    kernel.cachyos.enable = mkEnableOption "CachyOS BORE kernel (cached in our private Attic)";

    network = {
      tailscale.enable = mkEnableOption "Tailscale networking";
      edunet.enable = mkEnableOption "campus network authentication";
      proxy = {
        backend = mkOption {
          type = types.nullOr (types.enum [ "dae" "honk" ]);
          default = null;
          description = "Transparent proxy using the shared encrypted nodes; null disables it.";
        };
        lanInterfaces = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "virbr0" ];
          description = ''
            LAN interfaces whose forwarded traffic dae or honk should proxy.
            These interfaces must exist before the proxy starts. Enabling Docker
            or libvirt does not automatically add their bridges to this list.
          '';
        };
      };
    };

    services.aria2.enable = mkEnableOption "aria2 RPC and local AriaNg web interface";

    virtualisation = {
      docker.enable = mkEnableOption "rootless Docker";
      podman.enable = mkEnableOption "Podman and Distrobox";
      libvirt.enable = mkEnableOption "libvirt, QEMU and virt-manager";
      waydroid.enable = mkEnableOption "Waydroid";
    };

    # One switch per application. Profiles enable only the first-install set;
    # try anything else with nix shell or nix profile.
    apps = {
      edge.enable = mkEnableOption "Microsoft Edge";
      chrome.enable = mkEnableOption "Google Chrome";
      wechat.enable = mkEnableOption "WeChat";
      qq.enable = mkEnableOption "QQ";
      neteaseMusic.enable = mkEnableOption "Netease Cloud Music (netease-cloud-music-gtk)";
      telegram.enable = mkEnableOption "Telegram Desktop";
      mpv.enable = mkEnableOption "mpv";
      vlc.enable = mkEnableOption "VLC";
      obs.enable = mkEnableOption "OBS Studio";
      ytDlp.enable = mkEnableOption "yt-dlp";
      ffmpeg.enable = mkEnableOption "FFmpeg command-line tools";
      vscode.enable = mkEnableOption "VS Code with Vim, Dracula, Tinymist, LaTeX Workshop, CodeSnap and the Chinese language pack";
      anki.enable = mkEnableOption "Anki";
      obsidian.enable = mkEnableOption "Obsidian";
      typesetting.enable = mkEnableOption "Typst, Pandoc and Tectonic";
    };

    programs = {
      wireshark.enable = mkEnableOption "Wireshark with capture permissions";
      appimage.enable = mkEnableOption "AppImage execution support";
      nixLd.enable = mkEnableOption "compatibility loader for external binaries";
      steam.enable = mkEnableOption "Steam and its system integration";
    };
  };

  config.assertions = map
    (name: requires cfg.apps.${name}.enable cfg.desktop.enable "apps.${name}" "desktop")
    [ "edge" "chrome" "wechat" "qq" "neteaseMusic" "telegram" "mpv" "vlc" "obs" "vscode" "anki" "obsidian" ]
  ++ [
    {
      assertion = !(cfg.network.proxy.backend == "honk" && config.services.dae.enable);
      message = "my.network.proxy.backend = \"honk\" conflicts with services.dae";
    }
    (requires cfg.desktop.utilities.enable cfg.desktop.enable "desktop.utilities" "desktop")
    (requires cfg.desktop.graphicalBoot.enable cfg.desktop.enable "desktop.graphicalBoot" "desktop")
    (requires cfg.desktop.wallpaperEngine.enable cfg.desktop.enable "desktop.wallpaperEngine" "desktop")
    (requires cfg.desktop.noctalia.enable cfg.desktop.enable "desktop.noctalia" "desktop")
    (requires cfg.desktop.zekNiri.enable cfg.desktop.enable "desktop.zekNiri" "desktop")
    (requires cfg.desktop.codexComputerUse.enable cfg.desktop.enable "desktop.codexComputerUse" "desktop")
    (requires cfg.desktop.easyeffects.enable cfg.desktop.enable "desktop.easyeffects" "desktop")
    (requires cfg.desktop.phone.enable cfg.desktop.enable "desktop.phone" "desktop")
    (requires cfg.desktop.screenCast.enable cfg.desktop.enable "desktop.screenCast" "desktop")
    (requires cfg.input.speech.enable cfg.desktop.enable "input.speech" "desktop")
    (requires cfg.input.vtype.enable cfg.desktop.enable "input.vtype" "desktop")
    (requires cfg.input.speech.doubao.enable cfg.input.speech.enable "input.speech.doubao" "input.speech")
    (requires (cfg.input.speech.enable && cfg.input.speech.backend == "vinput") cfg.input.speech.doubao.enable "input.speech.backend=vinput" "input.speech.doubao")
    (requires cfg.fonts.extra.enable cfg.desktop.enable "fonts.extra" "desktop")
    (requires cfg.fonts.windows.enable cfg.fonts.extra.enable "fonts.windows" "fonts.extra")
  ];
}
