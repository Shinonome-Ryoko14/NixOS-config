{ osConfig, ... }:
let
  flake = if osConfig.my.configPath != null then osConfig.my.configPath else ".";
in
{
  programs.starship = {
    enable = true;
    presets = [ "catppuccin-powerline" ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      # 主题交给 starship，避免两套 prompt 冲突
      theme = "";
      plugins = [
        "git"
        "sudo"
        "extract"
        "colored-man-pages"
      ];
      extraConfig = ''
        DISABLE_AUTO_UPDATE=true
        DISABLE_UPDATE_PROMPT=true
      '';
    };

    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      grep = "rg";
      rebuild = "sudo nixos-rebuild switch --flake ${flake}#${osConfig.networking.hostName}";
      update = "sudo nixos-rebuild switch --upgrade --flake ${flake}#${osConfig.networking.hostName}";
    };

    initContent = ''
      HISTSIZE=10000
      SAVEHIST=10000
      HISTFILE="$HOME/.zsh_history"
      setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY AUTO_CD
    '';
  };
}
