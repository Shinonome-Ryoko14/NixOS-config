{ lib
, pkgs
, config
, osConfig
, inputs
, ...
}:
let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    filterAttrs
    mapAttrsToList
    max
    stringLength
    ;

  catalog = import ../../../app-catalog.nix;

  flake =
    if osConfig.my.configPath != null then
      osConfig.my.configPath
    else
      "${config.home.homeDirectory}/nixos-config";

  host = osConfig.networking.hostName;
  user = osConfig.my.user.name;

  version =
    if inputs.self ? shortRev then
      inputs.self.shortRev
    else if inputs.self ? dirtyShortRev then
      inputs.self.dirtyShortRev
    else
      "unknown";

  appsJson = builtins.toJSON (mapAttrsToList (name: description: { inherit name description; }) catalog);
  appNames = concatStringsSep " " (builtins.attrNames catalog);

  scriptPath = name: "${toString ./scripts}/${name}.sh";

  selection = pkgs.writeShellApplication {
    name = "ryoko-selection";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./scripts/selection.py} "$@"
    '';
  };

  baseInputs = with pkgs; [
    coreutils
    gnugrep
    gnused
    jq
    git
  ];

  baseEnv = {
    RYOKO_FLAKE = flake;
    RYOKO_HOST = host;
    RYOKO_USER = user;
    RYOKO_VERSION = version;
    RYOKO_APPS_JSON = appsJson;
    RYOKO_APP_NAMES = appNames;
    RYOKO_SELECTION = "${selection}/bin/ryoko-selection";
    RYOKO_CACHE = "${config.xdg.cacheHome}/ryoko";
    RYOKO_WALLPAPER_DIR = osConfig.my.desktop.wallpaperDir;
    RYOKO_XHUP_DIR = "${config.home.homeDirectory}/src/xhup-dicts";
    RYOKO_DESKTOP = if osConfig.my.desktop.enable then "1" else "0";
    RYOKO_ASSUME_YES = "0";
  };

  commandSpecs = {
    list = {
      description = "列出应用开关和受管软件包";
      inputs = with pkgs; [ fzf nix ];
    };
    enable = {
      description = "启用应用或软件包";
      inputs = with pkgs; [ nix nh ];
    };
    disable = {
      description = "禁用应用或软件包";
      inputs = with pkgs; [ nh ];
    };
    add = {
      description = "把软件包加入受管清单";
      inputs = with pkgs; [ nix nh ];
    };
    remove = {
      description = "从受管清单移除软件包";
      inputs = with pkgs; [ nh ];
    };
    search = {
      description = "在 nixpkgs 中搜索软件包";
      inputs = with pkgs; [ fzf nix-search-tv ];
    };
    try = {
      description = "临时进入包含软件包的 shell";
      inputs = with pkgs; [ nix ];
    };
    info = {
      description = "查看应用或软件包信息";
      inputs = with pkgs; [ nix ripgrep ];
    };
    where = {
      description = "在配置仓库中定位关键词";
      inputs = with pkgs; [ ripgrep ];
    };
    apply = {
      description = "构建并切换系统";
      inputs = with pkgs; [ nh ];
    };
    status = {
      description = "系统与仓库状态";
      inputs = with pkgs; [ nix procps ];
    };
    update = {
      description = "更新 flake 输入并构建";
      inputs = with pkgs; [ nix nh ];
    };
    gen = {
      description = "列出或切换系统代际";
      inputs = with pkgs; [ nix ];
    };
    gc = {
      description = "清理旧代际（默认 dry-run）";
      inputs = with pkgs; [ nix ];
    };
    ime = {
      description = "输入法状态、重启、加词与同步";
      inputs = with pkgs; [ fcitx5 ];
    };
    wall = {
      description = "切换壁纸";
      inputs = with pkgs; [ fzf findutils ];
    };
    timer = {
      description = "计时并在结束时通知";
      inputs = with pkgs; [ procps libnotify ];
    };
    power = {
      description = "锁屏、挂起、重启、关机菜单";
      inputs = with pkgs; [ fzf ];
    };
    lock = {
      description = "锁屏";
      file = ./scripts/power-wrapper.sh;
    };
    suspend = {
      description = "挂起";
      file = ./scripts/power-wrapper.sh;
    };
    reboot = {
      description = "重启";
      file = ./scripts/power-wrapper.sh;
    };
    shutdown = {
      description = "关机";
      file = ./scripts/power-wrapper.sh;
    };
    git = {
      description = "查看或提交配置仓库";
      inputs = with pkgs; [ fzf gh ];
    };
    upload = {
      description = "新建分支、提交并推送（可选 PR）";
      inputs = with pkgs; [ fzf gh ];
      file = ./scripts/git.sh;
      env.RYOKO_GIT_MODE = "upload";
    };
    dashboard = {
      description = "交互式操作面板";
      inputs = with pkgs; [ fzf ];
    };
    completions = {
      description = "输出补全数据";
      hidden = true;
    };
  };

  mkCommand =
    name: spec:
    let
      env = baseEnv // (spec.env or { });
      envText = concatStringsSep "" (
        mapAttrsToList (key: value: "export ${key}=${escapeShellArg (toString value)}\n") env
      );
    in
    pkgs.writeShellApplication {
      name = "ryoko-${name}";
      runtimeInputs = baseInputs ++ (spec.inputs or [ ]);
      # 每个脚本都会拼接 common.sh，未用到的 helper 会触发 SC2329；
      # timer 的后台子 shell 故意用单引号延迟展开，触发 SC2016。
      excludeShellChecks = [ "SC2329" "SC2016" ];
      text = ''
        ${envText}
        ${builtins.readFile ./scripts/common.sh}
        ${builtins.readFile (spec.file or (scriptPath name))}
      '';
    };

  commands = builtins.mapAttrs mkCommand commandSpecs;
  visibleSpecs = filterAttrs (_: spec: !(spec.hidden or false)) commandSpecs;
  nameWidth = lib.foldl' (acc: name: max acc (stringLength name)) 0 (builtins.attrNames visibleSpecs);
  padRight = value: value + concatStringsSep "" (lib.genList (_: " ") (nameWidth - stringLength value));
  helpText = concatStringsSep "\n" (
    mapAttrsToList
      (name: spec: "  ${padRight name}  ${spec.description}")
      visibleSpecs
  );

  dispatcher = pkgs.writeShellApplication {
    name = "ryoko";
    runtimeInputs = with pkgs; [ coreutils fzf ];
    text = ''
      version=${escapeShellArg version}
      app_names=${escapeShellArg appNames}

      usage() {
        cat <<'RYOKO_USAGE'
      ryoko ${version}

      用法: ryoko <命令> [参数]

      ${helpText}

      简写: ryoko <应用> on|off   （例如 ryoko qq off）
      RYOKO_USAGE
      }

      cmd=''${1:-}
      if [ -z "$cmd" ]; then
        if [ -t 1 ] && command -v ryoko-dashboard >/dev/null 2>&1; then
          exec ryoko-dashboard
        fi
        usage
        exit 0
      fi
      shift

      case "$cmd" in
        help|-h|--help) usage ;;
        version|-V|--version) echo "ryoko $version" ;;
        list|enable|disable|add|remove|search|try|info|where|apply|status|update|gen|gc|ime|wall|timer|lock|suspend|reboot|shutdown|power|git|upload|dashboard|completions)
          exec "ryoko-$cmd" "$@" ;;
        *)
          if [ $# -ge 1 ]; then
            case "$1" in
              on|true|1|enable|enabled)
                shift
                if [[ " $app_names " == *" $cmd "* ]]; then exec ryoko-enable "$cmd" "$@"; fi
                ;;
              off|false|0|disable|disabled)
                shift
                if [[ " $app_names " == *" $cmd "* ]]; then exec ryoko-disable "$cmd" "$@"; fi
                ;;
            esac
          fi
          echo "ryoko: 未知命令 $cmd" >&2
          echo >&2
          usage >&2
          exit 1
          ;;
      esac
    '';
  };

  cli = pkgs.buildEnv {
    name = "ryoko-cli";
    paths = [ dispatcher selection ] ++ builtins.attrValues commands;
    pathsToLink = [ "/bin" ];
  };
in
{
  home.packages = [ cli ];
}
