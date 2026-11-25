{ config, lib, ... }:
lib.mkIf config.my.virtualisation.docker.enable {
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
