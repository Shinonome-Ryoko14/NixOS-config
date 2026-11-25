{ config, lib, ... }:
let
  baseCaches = [
    "https://mirrors.cernet.edu.cn/nix-channels/store"
    "https://cache.nixos.org/"
  ];
  noctaliaCache = {
    url = "https://noctalia.cachix.org";
    key = "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=";
  };
  desktopCaches = lib.optional config.my.desktop.enable noctaliaCache.url;
  desktopKeys = lib.optional config.my.desktop.enable noctaliaCache.key;
in
{
  nix.settings = {
    substituters = lib.mkForce (baseCaches ++ desktopCaches);
    extra-substituters = lib.mkForce [ ];
    extra-trusted-public-keys = lib.mkForce desktopKeys;
  };
}
