{ config, lib, inputs, ... }:
{
  nixpkgs.overlays = [ inputs.nur.overlays.default ]
    ++ lib.optionals config.my.desktop.enable [
      inputs.xwayland-satellite.overlays.default
    ];
}
