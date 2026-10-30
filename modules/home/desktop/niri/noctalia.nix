{ lib, inputs, osConfig, config, ... }:
let
  cfg = osConfig.my.desktop.noctalia;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # Noctalia draws the bar only. DMS keeps the services that the rest of the
  # desktop depends on: notifications, lock screen, clipboard, spotlight and
  # the xhup / vocotype plugins. The overlapping Noctalia services are disabled
  # below so both shells can run side by side without fighting over D-Bus names.
  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      settings = {
        shell = {
          avatar_path = "~/.face.icon";
          clipboard_enabled = false;
          launch_apps_as_systemd_services = true;
          setup_wizard_enabled = false;
          telemetry_enabled = false;
        };

        theme = {
          mode = "dark";
          shell_mode = "follow";
          sync_color_scheme = false;
          # Follow the wallpaper so the palette matches the rest of the desktop.
          source = "wallpaper";
          wallpaper_scheme = "muted";
        };

        # The DMS wallpaper plugin owns the actual wallpaper (including animated
        # ones). Keeping Noctalia's layer off avoids drawing a second wallpaper,
        # while default.path still feeds the palette and the lock screen.
        wallpaper = {
          enabled = false;
          fill_color = "surface";
          default.path = "${config.home.homeDirectory}/.background/wallpaper.jpg";
        };

        notification.enable_daemon = false;
        lockscreen.enabled = false;

        bar = {
          order = [ "main" ];
          main = {
            position = "top";
            enabled = true;
            thickness = 38;
            background_opacity = 0.82;
            compositor_blur = true;
            border = "outline_variant";
            border_width = 1.0;
            shadow = false;
            radius = 19;
            margin_ends = 24;
            margin_edge = 6;
            padding = 14;
            widget_spacing = 6;
            font_weight = 500;
            start = [ "launcher" "workspaces" ];
            center = [ "clock" ];
            end = [ "tray" "network" "bluetooth" "volume" "battery" "control-center" "session" ];
          };
        };
      };
    };
  };
}
