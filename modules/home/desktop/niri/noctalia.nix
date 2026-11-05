{ lib, inputs, osConfig, config, ... }:
let
  cfg = osConfig.my.desktop.noctalia;
  zek = osConfig.my.desktop.zekNiri.enable;
  home = config.home.homeDirectory;
  wallpaper = osConfig.my.desktop.wallpaperDir;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # Noctalia provides the panels and visual shell. DMS keeps the services the
  # rest of the desktop depends on: notifications, lock screen, spotlight and
  # the xhup / vocotype plugins. Clipboard moves to Noctalia because Waybar's
  # ZEK modules call `noctalia msg panel-toggle clipboard`; DMS clipboard is
  # disabled by the zek-niri activation.
  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      settings = lib.recursiveUpdate
        {
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
            default.path = "${home}/.background/wallpaper.jpg";
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
        }
        (lib.optionalAttrs zek {
          # ZEKniri uses Waybar as the status bar; Noctalia's own bar stays off.
          # Drop the tray widget as well so Noctalia releases
          # org.kde.StatusNotifierWatcher for Waybar.
          bar.main.enabled = false;
          bar.main.end = [ "network" "bluetooth" "volume" "battery" "control-center" "session" ];

          backdrop = {
            blur_intensity = 0.0;
            tint_intensity = 0.0;
          };

          theme = {
            builtin = "Tokyo-Night";
            community_palette = "Oxide";
            custom_palette = "ZEKniri-preset";
            mode = "dark";
            shell_mode = "light";
            source = "custom";
            wallpaper_scheme = "soft";
            sync_color_scheme = false;
          };

          wallpaper = {
            enabled = true;
            directory = wallpaper;
            fill_color = "surface";
            transition_on_startup = true;
            default.path = "${wallpaper}/Image_1788066106777_803.jpg";
            last.path = "${wallpaper}/Image_1788066106777_803.jpg";
            monitors."eDP-1".path = "${wallpaper}/Image_1788066106777_803.jpg";
          };

          shell = {
            niri_overview_type_to_launch_enabled = true;
            animation.speed = 0.7;
            panel = {
              control_center_placement = "floating";
              list_item_background = true;
              session_placement = "floating";
              session_position = "center";
              transparency_mode = "glass";
            };
          };

          osd.kinds.keyboard_layout = false;

          dock = {
            auto_hide = true;
            cross_axis_padding = 2;
            enabled = true;
            icon_size = 28;
            main_axis_padding = 9;
            pinned = [
              "org.gnome.Nautilus"
              "firefox"
              "kitty"
              "Alacritty"
              "mark-shot"
              "com.microsoft.Edge"
              "com.mitchellh.ghostty"
            ];
            reserve_space = false;
          };

          # The git plugin sources are unreachable from the user service on
          # this host (GitHub fetches time out), so keep them cached but do
          # not retry on every start. Re-enable in Settings → Plugins once
          # the proxy/network is available.
          plugins = {
            auto_update = "none";
            enabled = [ ];
            source = [
              {
                kind = "git";
                location = "https://github.com/noctalia-dev/official-plugins";
                name = "official";
              }
              {
                kind = "git";
                location = "https://github.com/noctalia-dev/community-plugins";
                name = "community";
              }
            ];
          };

          # ZEKniri desktop widgets, scaled from the author's 1707x1067 logical
          # layout to this host's 1920x1080 output.
          desktop_widgets = {
            schema_version = 2;
            widget_order = [
              "desktop-widget-0000000000000005"
              "desktop-widget-0000000000000001"
              "desktop-widget-0000000000000003"
              "desktop-widget-0000000000000002"
              "desktop-widget-0000000000000006"
              "desktop-widget-0000000000000007"
            ];
            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };
            widget = {
              "desktop-widget-0000000000000001" = {
                box_height = 81.0;
                box_width = 396.0;
                cx = 1698.0;
                cy = 70.0;
                output = "eDP-1";
                placement_height = 1080.0;
                placement_width = 1920.0;
                rotation = 0.0;
                type = "audio_visualizer";
                settings = {
                  background = false;
                  background_color = "surface";
                  bands = 52;
                  color_1 = "primary";
                  color_2 = "surface";
                  reversed = false;
                  show_when_idle = true;
                };
              };
              "desktop-widget-0000000000000002" = {
                box_height = 113.0;
                box_width = 306.0;
                cx = 168.0;
                cy = 103.0;
                output = "eDP-1";
                placement_height = 1080.0;
                placement_width = 1920.0;
                rotation = -0.0;
                type = "media_player";
                settings = {
                  background = true;
                  background_color = "primary";
                  background_opacity = 0.45;
                  background_padding = 5;
                  layout = "horizontal";
                };
              };
              "desktop-widget-0000000000000003" = {
                box_height = 146.0;
                box_width = 270.0;
                cx = 150.0;
                cy = 249.0;
                output = "eDP-1";
                placement_height = 1080.0;
                placement_width = 1920.0;
                rotation = -0.0;
                type = "sysmon";
                settings = {
                  background = true;
                  background_color = "on_primary";
                  background_opacity = 0.46;
                  color2 = "error";
                  display = "graph";
                  gauge_layout = "horizontal";
                  shadow = true;
                  show_label = true;
                  stat = "cpu_usage";
                  stat2 = "ram_pct";
                };
              };
              "desktop-widget-0000000000000005" = {
                box_height = 340.0;
                box_width = 1908.0;
                cx = 960.0;
                cy = 1080.0;
                output = "eDP-1";
                placement_height = 1080.0;
                placement_width = 1920.0;
                rotation = -0.0;
                type = "audio_visualizer";
                settings = {
                  background = false;
                  background_color = "primary";
                  background_opacity = 0.45;
                  background_padding = 10;
                  background_radius = 12;
                  bands = 128;
                  centered = true;
                  color_1 = "primary";
                  color_2 = "surface_container";
                  mirrored = true;
                  reversed = false;
                  show_when_idle = true;
                };
              };
              "desktop-widget-0000000000000006" = {
                box_height = 0.0;
                box_width = 0.0;
                cx = 1783.0;
                cy = 181.0;
                output = "eDP-1";
                placement_height = 1080.0;
                placement_width = 1920.0;
                rotation = 0.0;
                type = "clock";
                settings = {
                  background = false;
                  clock_style = "digital";
                  color = "primary";
                };
              };
              "desktop-widget-0000000000000007" = {
                box_height = 211.0;
                box_width = 180.0;
                cx = 96.0;
                cy = 435.0;
                output = "eDP-1";
                placement_height = 1080.0;
                placement_width = 1920.0;
                rotation = 0.0;
                type = "fancy_audio_visualizer";
                settings = {
                  background = false;
                  bloom_intensity = 0.6;
                  secondary_color = "outline_variant";
                  visualization_mode = "all";
                };
              };
            };
          };

          widget = {
            audio_visualizer = {
              bands = 128;
              color_1 = "#D5114B";
              color_2 = "#F5E100";
              show_when_idle = true;
              width = 314;
            };
            battery = {
              display_mode = "graphic";
              label_content = "time";
              scale = 0.6;
              show_label = false;
            };
            brightness.show_label = false;
            control-center.scale = 0.75;
            cpu = {
              highlight_color = "on_error";
              show_value = false;
            };
            ram.show_value = false;
            temp.show_value = false;
            volume.show_label = false;
            workspaces = {
              capsule_fill = "surface";
              capsule_radius = "auto";
              empty_color = "primary";
              occupied_color = "#EE551D";
            };
          };
        });
    };
  };
}
