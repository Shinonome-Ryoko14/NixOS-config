{ config, lib, pkgs, osConfig, inputs, ... }:
let
  cfg = osConfig.my.desktop.zekNiri;
  zek = inputs.zek-niri;
  home = config.home.homeDirectory;
  wallpaperDir = "${home}/图片/wallpaper";

  # ZEK-menu needs PyGObject plus the GTK 3 / layer-shell typelibs.
  pythonGtk = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  giPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.gtk3
    pkgs.gtk-layer-shell
    pkgs.gdk-pixbuf
    pkgs.pango
    pkgs.atk
    pkgs.harfbuzz
    pkgs.gobject-introspection
  ];
  zekMenu = pkgs.writeShellScriptBin "ZEK-menu" ''
    export GI_TYPELIB_PATH=${giPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}
    export GDK_BACKEND=wayland
    exec ${pythonGtk}/bin/python ${./configs/ZEKniri-menu/ZEK-menu} "$@"
  '';
  zekCli = pkgs.writeShellScriptBin "ZEK-niri" ''
    exec ${pkgs.python3}/bin/python -c 'import sys; sys.argv[0] = "ZEK-niri"; sys.path.insert(0, "${zek}"); from zekniri.cli import main; main()' "$@"
  '';

  # animations.kdl is rewritten by the Noctalia niri-animations plugin, so keep
  # it out of the read-only store tree and seed it as a writable file instead.
  niriConfig = pkgs.runCommand "zek-niri-config" { } ''
    mkdir -p $out
    cp -a ${./configs/niri}/. $out/
    rm -f $out/animations.kdl
  '';
  # toggle-colors.sh rewrites colors-active.css, and Noctalia generates
  # colors-noctalia.css; both must stay writable.
  waybarConfig = pkgs.runCommand "zek-waybar-config" { } ''
    mkdir -p $out
    cp -a ${./configs/waybar}/. $out/
    rm -f $out/colors-active.css $out/colors-noctalia.css
  '';

  dmsClipboard = pkgs.writeText "dms-clsettings.json" (builtins.toJSON {
    disabled = true;
    disableHistory = false;
    maxHistory = 500;
    maxEntrySize = 10485760;
    autoClearDays = 0;
    clearAtStartup = false;
  });
in
lib.mkIf cfg.enable {
  home.packages = with pkgs; [
    waybar
    alacritty
    cava
    fastfetch
    pulseaudio # pactl, used by the waybar cava module
    ddcutil
    playerctl
    wl-clipboard
    capitaine-cursors
    nerd-fonts.jetbrains-mono
    lxgw-wenkai-screen
    font-awesome
    pythonGtk
    zekMenu
    zekCli
    inputs.mark-shot.packages.${pkgs.system}.default
  ];

  # Match the capitaine cursor used by the niri config, overriding DMS's Bibata.
  home.pointerCursor = lib.mkForce {
    enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  xdg.configFile = {
    "niri" = {
      source = niriConfig;
      recursive = true;
    };
    "waybar" = {
      source = waybarConfig;
      recursive = true;
    };
    "kitty" = {
      source = ./configs/kitty;
      recursive = true;
    };
    "fastfetch" = {
      source = ./configs/fastfetch;
      recursive = true;
    };
    "noctalia/palettes" = {
      source = ./configs/noctalia/palettes;
      recursive = true;
    };
    "noctalia/templates" = {
      source = ./configs/noctalia/templates;
      recursive = true;
    };
    "noctalia/templates.toml".source = ./configs/noctalia/templates.toml;
  };

  # Wallpaper pack from the ZEKniri repository.
  home.file."图片/wallpaper".source = "${zek}/assets/wallpapers";

  home.activation.zekNiriSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p \
      "$HOME/.config/niri" \
      "$HOME/.config/waybar" \
      "$HOME/.config/noctalia" \
      "$HOME/.config/ZEKniri" \
      "$HOME/.config/DankMaterialShell" \
      "$HOME/.config/alacritty" \
      "$HOME/.config/cava"

    # Noctalia templates rewrite these files, so they are writable copies.
    run cp -an ${./configs/alacritty}/. "$HOME/.config/alacritty/" || true
    run cp -an ${./configs/cava}/. "$HOME/.config/cava/" || true

    if [ ! -e "$HOME/.config/niri/animations.kdl" ]; then
      run install -m 0644 ${./configs/niri/animations.kdl} "$HOME/.config/niri/animations.kdl"
    fi
    if [ ! -e "$HOME/.config/waybar/colors-active.css" ]; then
      run install -m 0644 ${./configs/waybar/colors-active.css} "$HOME/.config/waybar/colors-active.css"
    fi
    if [ ! -e "$HOME/.config/waybar/colors-noctalia.css" ]; then
      run install -m 0644 ${./configs/waybar/colors-noctalia.css} "$HOME/.config/waybar/colors-noctalia.css"
    fi
    if [ ! -e "$HOME/.config/noctalia/templates-apps.toml" ]; then
      run install -m 0644 ${./configs/noctalia/templates-apps.toml} "$HOME/.config/noctalia/templates-apps.toml"
    fi
    if [ ! -e "$HOME/.config/ZEKniri/ZEK-niri.conf" ]; then
      run install -m 0644 ${zek}/ZEK-niri.conf "$HOME/.config/ZEKniri/ZEK-niri.conf"
    fi
    if [ ! -e "$HOME/.config/ZEKniri/ZEKniri-menu.conf" ]; then
      run install -m 0644 ${./configs/ZEKniri-menu/ZEKniri-menu.conf} "$HOME/.config/ZEKniri/ZEKniri-menu.conf"
    fi

    # Noctalia owns the clipboard; stop DMS from recording a second history.
    if [ -s "$HOME/.config/DankMaterialShell/clsettings.json" ]; then
      run ${pkgs.jq}/bin/jq '.disabled = true' \
        "$HOME/.config/DankMaterialShell/clsettings.json" \
        > "$HOME/.config/DankMaterialShell/clsettings.json.tmp"
      run mv "$HOME/.config/DankMaterialShell/clsettings.json.tmp" \
        "$HOME/.config/DankMaterialShell/clsettings.json"
    else
      run install -m 0600 ${dmsClipboard} "$HOME/.config/DankMaterialShell/clsettings.json"
    fi
  '';

  # ZEK-niri follows Noctalia wallpaper changes and applies the matching palette.
  systemd.user.services.zek-niri-watch = {
    Unit = {
      Description = "ZEK-niri wallpaper palette watcher";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${zekCli}/bin/ZEK-niri watch 2";
      Restart = "on-failure";
      RestartSec = 5;
      path = [
        config.programs.noctalia.package
        pkgs.bash
        pkgs.coreutils
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
