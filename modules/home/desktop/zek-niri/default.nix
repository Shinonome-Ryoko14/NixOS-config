{ config, lib, pkgs, osConfig, inputs, ... }:
let
  cfg = osConfig.my.desktop.zekNiri;
  zek = inputs.zek-niri;
  home = config.home.homeDirectory;
  wallpaperDir = osConfig.my.desktop.wallpaperDir;

  # ZEK-menu needs PyGObject plus the GTK 3 / layer-shell typelibs.
  pythonGtk = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  giPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.gtk3.out
    pkgs.gtk-layer-shell
    pkgs.gdk-pixbuf.out
    pkgs.pango.out
    pkgs.cairo.out
    pkgs.glib.out
    pkgs.atk.out
    pkgs.harfbuzz.out
    pkgs.gobject-introspection
  ];
  zekMenu = pkgs.writeShellScriptBin "ZEK-menu" ''
    export GI_TYPELIB_PATH=${giPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}
    export PYTHONPATH=${zek}''${PYTHONPATH:+:$PYTHONPATH}
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
    chmod -R u+w $out
    rm -f $out/animations.kdl
  '';
  # Noctalia generates colors-noctalia.css, so keep it out of the read-only
  # store tree and seed it as a writable file instead.
  waybarConfig = pkgs.runCommand "zek-waybar-config" { } ''
    mkdir -p $out
    cp -a ${./configs/waybar}/. $out/
    chmod -R u+w $out
    rm -f $out/colors-noctalia.css
  '';

in
lib.mkIf cfg.enable {
  # Default terminal for Noctalia / DMS / xdg-terminal-exec consumers.
  home.sessionVariables.TERMINAL = "kitty";

  home.packages = with pkgs; [
    waybar
    kitty
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
    inputs.mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default
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

  home.activation.zekNiriSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p \
      "$HOME/.config/niri" \
      "$HOME/.config/waybar" \
      "$HOME/.config/noctalia" \
      "$HOME/.config/ZEKniri" \
      "$HOME/.config/alacritty" \
      "$HOME/.config/cava" \
      "${wallpaperDir}"

    # Wallpaper pack from the ZEKniri repository. `cp -a` preserves the Nix
    # store's 0555 directory mode, so restore write access afterwards or
    # Noctalia cannot add downloaded wallpapers to this folder.
    run cp -an ${zek}/assets/wallpapers/. "${wallpaperDir}/" || true
    run chmod -R u+w "${wallpaperDir}"

    # Noctalia templates rewrite these files, so they are writable copies.
    run cp -an ${./configs/alacritty}/. "$HOME/.config/alacritty/" || true
    run cp -an ${./configs/cava}/. "$HOME/.config/cava/" || true
    run chmod -R u+w "$HOME/.config/alacritty" "$HOME/.config/cava"

    if [ ! -e "$HOME/.config/niri/animations.kdl" ]; then
      run install -m 0644 ${./configs/niri/animations.kdl} "$HOME/.config/niri/animations.kdl"
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
  '';

  # Waybar is started by systemd instead of niri's spawn-at-startup so a
  # SIGUSR2 palette reload crash is recovered automatically.
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecReload = "kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
