{ lib, pkgs, osConfig, ... }:
{
  config = lib.mkIf
    (osConfig.my.desktop.enable
      && osConfig.my.desktop.noctalia.enable)
    {
      home.packages = [ pkgs.wlogout ];

      xdg.configFile."wlogout/layout".text = ''
        {
            "label" : "lock",
            "action" : "dms ipc call lock lock",
            "text" : "Lock",
            "keybind" : "l"
        }
        {
            "label" : "logout",
            "action" : "niri msg action quit",
            "text" : "Logout",
            "keybind" : "e"
        }
        {
            "label" : "suspend",
            "action" : "systemctl suspend",
            "text" : "Suspend",
            "keybind" : "u"
        }
        {
            "label" : "reboot",
            "action" : "systemctl reboot",
            "text" : "Reboot",
            "keybind" : "r"
        }
        {
            "label" : "shutdown",
            "action" : "systemctl poweroff",
            "text" : "Shutdown",
            "keybind" : "s"
        }
      '';

      xdg.configFile."wlogout/style.css".text = ''
        * {
          font-family: "FiraCode Nerd Font", "Noto Sans CJK SC", sans-serif;
          font-size: 18px;
        }

        window {
          background-color: rgba(20, 43, 74, 0.92);
        }

        button {
          background-image: none;
          background-color: rgba(30, 46, 72, 0.94);
          box-shadow: none;
          text-shadow: none;
          color: #cdc2b8;
          border: 1px solid rgba(178, 140, 155, 0.45);
          border-radius: 16px;
          margin: 12px;
          padding: 24px;
          min-width: 170px;
          min-height: 120px;
        }

        button:hover, button:focus {
          background-image: none;
          background-color: #b28c9b;
          color: #142b4a;
        }
      '';
    };
}
