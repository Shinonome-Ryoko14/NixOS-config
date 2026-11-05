{ lib, pkgs, osConfig, ... }:
let
  # Commit identity shared by Git and Jujutsu.
  identity = {
    name = "ryoko";
    email = "w13949636385@gmail.com";
  };
in
{
  programs.git = {
    enable = true;
    settings = {
      user = identity;
      # GitHub 直连即可。不要把代理写死在这里:`http.proxy` 同时作用于 push,
      # 经 mihomo 转发时 GitHub 会返回 `remote: fatal error in commit_refs`。
      # 确实需要代理时,临时用 `HTTPS_PROXY=... git push` 或 `git -c http.proxy=...`。
      credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      credential."https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    enableJujutsuIntegration = true;
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = identity;
      ui = {
        default-command = "log";
      };
      merge-tools.difft = lib.mkIf (builtins.elem pkgs.difftastic osConfig.my.cli.packages) {
        diff-invocation-mode = "file-by-file";
      };
    };
  };

  home.packages = osConfig.my.cli.packages ++ (with pkgs; lib.optionals osConfig.my.cli.extra.enable [
    lazygit
    zellij
    tealdeer
    fastfetch
    btop
    ouch
    iperf
    jjui
    nh
    nix-search-tv
    nur.repos.lihaoze123.cloudflare-cli
    # tobi/try with the NixOS shebang fix.
    nur.repos.lihaoze123.try
  ] ++ lib.optionals osConfig.my.desktop.enable [
    satty
    grim
    slurp
  ]);
}
