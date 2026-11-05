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
  # The Attic credentials are optional: a fresh clone has no secrets/, so never
  # make evaluation or the system closure depend on a file that does not exist.
  hasNetrc = private && builtins.pathExists ../../secrets/attic-netrc.age;
in
{
  warnings = lib.optional (private && !hasNetrc) ''
    my.nix.cacheProfile = "private" 但 secrets/attic-netrc.age 不存在;
    已忽略私人缓存,只用 cache.nixos.org。需要时用 ragenix 重新创建该文件。
  '';

  age.secrets.attic-netrc = lib.mkIf hasNetrc {
    file = ../../secrets/attic-netrc.age;
    mode = "0400";
  };

  systemd.services.nix-daemon = lib.mkIf hasNetrc {
    restartTriggers = [ config.age.secrets.attic-netrc.file ];
  };

  nix.settings = {
    # Only import our private cache; project caches (including lantian) stay disabled.
    substituters = lib.mkForce (
      (if hasNetrc then baseCaches ++ [ privateCache.url ] else [ "https://cache.nixos.org" ])
      ++ desktopCaches
    );
    extra-substituters = lib.mkForce [ ];
    extra-trusted-public-keys = lib.mkForce (lib.optionals hasNetrc [ privateCache.key ] ++ desktopKeys);
    netrc-file = lib.mkIf hasNetrc config.age.secrets.attic-netrc.path;
  };
}
