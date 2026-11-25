{ lib, pkgs, osConfig, ... }:
let
  cfg = osConfig.my.apps;
  # Application switch -> packages it installs.
  packages = with pkgs; {
    edge = [ microsoft-edge ];
    chrome = [ google-chrome ];
    wechat = [ wechat ];
    qq = [ qq ];
    neteaseMusic = [ netease-cloud-music-gtk ];
  };
in
{
  # Applications in daily use, each behind its own switch.
  home.packages = lib.concatLists
    (lib.mapAttrsToList (name: ps: lib.optionals cfg.${name}.enable ps) packages);

  xdg.mimeApps = lib.mkIf cfg.edge.enable {
    enable = true;
    defaultApplications = lib.genAttrs [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ]
      (_: [ "microsoft-edge.desktop" ]);
  };

  programs.vscode = lib.mkIf cfg.vscode.enable {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        myriad-dreamin.tinymist
        ms-ceintl.vscode-language-pack-zh-hans
        adpyke.codesnap
        james-yu.latex-workshop

        # Markdown reading: KaTeX math, mermaid diagrams, GitHub preview theme.
        yzhang.markdown-all-in-one
        bierner.markdown-mermaid
        bierner.markdown-preview-github-styles
        davidanson.vscode-markdownlint
        tomoki1207.pdf
      ];

      userSettings = {
        "markdown.math.enabled" = true;
        "markdown.preview.breaks" = true;
        "markdown.preview.fontSize" = 15;
        "markdown.preview.lineHeight" = 1.7;
        "[markdown]" = {
          "editor.wordWrap" = "on";
          "editor.quickSuggestions" = false;
        };
      };

      keybindings = [
        {
          key = "ctrl+shift+m";
          command = "markdown.showPreviewToSide";
          when = "editorLangId == markdown";
        }
      ];
    };
  };
}
