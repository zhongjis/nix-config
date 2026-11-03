{
  config,
  lib,
  ...
}: let
  stylixEnabled = config.stylix.enable or false;
in {
  imports = [
    ../../../../custom-home-manager-options/herdr-app
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
      global."ctrl-shift-f" = "mod.open:picker";
      # Herdr seeds its default keymap only into a new keys.json; one created by
      # activation first has none, so keep the terminal clipboard keys here.
      terminal = {
        "cmd-c" = "terminal.copy";
        "cmd-v" = "terminal.paste";
        "ctrl-v" = "terminal.paste_image";
      };
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
    };
  };
}
