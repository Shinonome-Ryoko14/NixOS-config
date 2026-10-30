{ config, lib, ... }:
let
  # Keep cache trust local; NUR repositories do not configure substituters.
  privateCache = {
    url = "https://cache.example.com/nur";
    key = "nur:dJh05Op2+iv3GCHoaF2+1FfQtqcUZzf/4v/ZTaLHomY=";
  };
  baseCaches = [ "https://mirrors.cernet.edu.cn/nix-channels/store" "https://cache.nixos.org/" ];
  noctaliaCache = {
    url = "https://noctalia.cachix.org";
    key = "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=";
  };
  desktopCaches = lib.optional config.my.desktop.enable noctaliaCache.url;
  desktopKeys = lib.optional config.my.desktop.enable noctaliaCache.key;
  private = config.my.nix.cacheProfile == "private";
in
{
  age.secrets.attic-netrc = lib.mkIf private {
    file = ../../secrets/attic-netrc.age;
    mode = "0400";
  };

  systemd.services.nix-daemon = lib.mkIf private {
    restartTriggers = [ config.age.secrets.attic-netrc.file ];
  };

  nix.settings = {
    # Only import our private cache; project caches (including lantian) stay disabled.
    substituters = lib.mkForce (
      (if private then baseCaches ++ [ privateCache.url ] else [ "https://cache.nixos.org" ])
      ++ desktopCaches
    );
    extra-substituters = lib.mkForce [ ];
    extra-trusted-public-keys = lib.mkForce (lib.optionals private [ privateCache.key ] ++ desktopKeys);
    netrc-file = lib.mkIf private config.age.secrets.attic-netrc.path;
  };
}
