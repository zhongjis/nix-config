{
  config,
  lib,
  pkgs,
  ...
}: let
  stylixEnabled = config.stylix.enable or false;
in {
  imports = [
    ../../../../custom-home-manager-options/herdr-app
  ];

  home.packages = [
    (pkgs.writeShellScriptBin "sessionizer" ''
      export PATH=${lib.makeBinPath [pkgs.jq pkgs.fzf pkgs.findutils pkgs.coreutils pkgs.gnused config.programs.herdr-app.package]}:"$PATH"
      ${builtins.readFile ./scripts/herdr-sessionizer.sh}
    '')
  ];

  programs.herdr-app = {
    enable = true;
    settings =
      {
        telemetry = false;
        sounds.enabled = true;
      }
      // lib.optionalAttrs stylixEnabled ({
          font = config.stylix.fonts.monospace.name;
          theme = "stylix";
        }
        // lib.optionalAttrs (lib.elem config.stylix.polarity ["dark" "light"]) {
          appearance = config.stylix.polarity;
        });
    # Base16 palette in Herdr's theme format; the ANSI order matches Stylix's ghostty palette.
    themes = lib.optionalAttrs stylixEnabled {
      stylix = with config.lib.stylix.colors.withHashtag; {
        background = base00;
        foreground = base05;
        selection = base02;
        cursor = base05;
        ansi = [
          base00
          base08
          base0B
          base0A
          base0D
          base0E
          base0C
          base05
          base03
          base08
          base0B
          base0A
          base0D
          base0E
          base0C
          base07
        ];
        colors = {
          accent = base0D;
          working = base0A;
          blocked = base08;
          done = base0B;
          idle = base03;
        };
      };
    };
    keys = {
      global = {
        "ctrl-shift-f" = "mod.open:picker";
        "ctrl-b" = "mod.open:tmux-prefix";
      };
      # Herdr seeds its default keymap only into a new keys.json; one created by
      # activation first has none, so keep the terminal clipboard keys here.
      terminal = {
        "cmd-c" = "terminal.copy";
        "cmd-v" = "terminal.paste";
        "ctrl-v" = "terminal.paste_image";
        # tmux-style prefix (tmux-prefix mod); Ctrl+B twice sends a literal Ctrl+B.
        "ctrl-b" = "mod.open:tmux-prefix";
      };
      "mod:tmux-prefix"."ctrl-b" = "tmux-prefix.send-prefix";
      # Settle the focused agent in the herdr-tui sidebar (tui-focus mod).
      "layout:herdr-tui" = {
        "cmd-shift-s" = "tui-focus.settle";
        "ctrl-shift-s" = "tui-focus.settle";
      };
    };
    # Herdr's default `main` layout with the tui-focus agent cards in the sidebar.
    layouts.herdr-tui = lib.importJSON ./layouts/herdr-tui.json;
    mods = {
      tui-focus = ./mods/tui-focus;
      tui-subagents = ./mods/tui-subagents;
      # Herdr's `spaces` mod with the repo/branch on its own line.
      tui-spaces = ./mods/tui-spaces;
      # Herdr's `tabs` mod with icon-only Files/Changes/PR/CI panel buttons.
      tui-tabs = ./mods/tui-tabs;
      # Herdr's `workspace-chrome` footer (Settings, Add machine) with centered icons on the collapsed rail.
      herdr-tui-chrome = ./mods/herdr-tui-chrome;
      # herdr.dev/mods/herdrdev/tmux-prefix
      tmux-prefix = ./mods/tmux-prefix;
      # Vendored and customized (not pinned); upstream LICENSE kept in each folder.
      # github.com/cybertron288/herdr-mods filetree, without its Claude hook bridge.
      filetree = ./mods/filetree;
      # github.com/cybertron288/herdr-mods file-icons; filetree reads its icons/.
      file-icons = ./mods/file-icons;
      # github.com/jjangsky/herdr-pr-flow, fed by tui-spaces' PR list.
      pr-flow = ./mods/pr-flow;
      # github.com/cybertron288/herdr-mods ci-dash (GitHub Actions runs, dispatch, artifacts).
      ci-dash = ./mods/ci-dash;
      # github.com/DeevsDeevs/deevs-herdr-kit agent-browser.
      agent-browser = ./mods/agent-browser;
      # Jira + Linear issue popup; UI adapted from github.com/mrolafsson/herdr-linear.
      issues = ./mods/issues;
    };
  };
}
