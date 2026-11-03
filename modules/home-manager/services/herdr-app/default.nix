{
  config,
  lib,
  ...
}: {
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
      // lib.optionalAttrs (config.stylix.enable or false) {
        font = config.stylix.fonts.monospace.name;
      };
    keys = {
      global."ctrl-shift-f" = "mod.open:picker";
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
