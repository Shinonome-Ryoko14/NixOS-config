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
      # GitHub is only reachable through the local Clash Verge (mihomo) proxy.
      # Change the port here if the proxy's mixed-port is configured differently.
      http."https://github.com/".proxy = "http://127.0.0.1:7897";
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
