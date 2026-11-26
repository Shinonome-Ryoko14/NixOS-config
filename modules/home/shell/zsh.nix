{ ... }:
let
  # Powerline 胶囊字符用 JSON 转义，避免在 Nix 源文件里直接嵌 PUA 字符。
  # U+E0B6 左圆角 / U+E0B0 分隔箭头 / U+E0B4 右圆角
  plCapL = builtins.fromJSON ''"\ue0b6"'';
  plArrow = builtins.fromJSON ''"\ue0b0"'';
  plCapR = builtins.fromJSON ''"\ue0b4"'';
  # 单色 NixOS 图标（nf-linux-nixos），替代预设默认的彩色 emoji ❄️
  nixosIcon = builtins.fromJSON ''"\uf313"'';
in
{
  programs.starship = {
    enable = true;
    presets = [ "catppuccin-powerline" ];
    # 在预设之上覆盖几个影响观感的默认值。
    settings = {
      os.symbols.NixOS = nixosIcon;

      # conda 并入 time 的 lavender 段：conda 为空时不会留下青绿色碎片。
      conda.style = "bg:lavender fg:crust";

      format = "[${plCapL}](red)$os$username[${plArrow}](bg:peach fg:red)$directory[${plArrow}](bg:yellow fg:peach)$git_branch$git_status[${plArrow}](fg:yellow bg:green)$c$rust$golang$nodejs$bun$php$java$kotlin$haskell$python[${plArrow}](fg:green bg:lavender)$conda$time[${plCapR} ](fg:lavender)$cmd_duration$line_break$character";
    };
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
      rebuild = "ryoko apply";
      update = "ryoko update";
    };

    initContent = ''
      HISTSIZE=10000
      SAVEHIST=10000
      HISTFILE="$HOME/.zsh_history"
      setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY AUTO_CD

      _ryoko() {
        local -a cmds
        if (( CURRENT == 2 )); then
          cmds=(''${(f)"$(ryoko completions commands 2>/dev/null)"})
          _describe 'command' cmds
          return
        fi
        case $words[2] in
          enable|disable)
            local -a apps
            apps=(''${(f)"$(ryoko completions apps 2>/dev/null)"})
            _describe 'app' apps
            ;;
          add|remove)
            local -a packages
            packages=(''${(f)"$(ryoko completions packages 2>/dev/null)"})
            _describe 'package' packages
            ;;
        esac
      }
      if (( $+functions[compdef] )); then
        compdef _ryoko ryoko
      fi
    '';
  };
}
