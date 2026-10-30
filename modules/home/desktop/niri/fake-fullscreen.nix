{ pkgs, lib, osConfig, ... }:
let
  fakeFullscreen = pkgs.writeShellApplication {
    name = "niri-fake-fullscreen";
    runtimeInputs = [ pkgs.jq pkgs.niri pkgs.procps pkgs.quickshell ];
    text = builtins.readFile ./fake-fullscreen.sh;
  };
in
{
  config = lib.mkIf osConfig.my.desktop.enable {
    home.packages = [ fakeFullscreen ];
  };
}
