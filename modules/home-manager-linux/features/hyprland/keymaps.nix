{
  pkgs,
  lib,
  ...
}: let
  close-application-sh =
    pkgs.writeShellScript "hyprland-close-application"
    (builtins.readFile ./scripts/close-application.sh);
  screenshot-sh =
    pkgs.writeShellScript "hyprland-screenshot"
    (builtins.readFile ./scripts/screenshot.sh);
  inherit (lib.generators) mkLuaInline;
  bind = key: dispatcher: {_args = [key (mkLuaInline dispatcher)];};
in {
  home.packages = with pkgs;
    lib.optionals stdenv.hostPlatform.isLinux [
      grimblast
    ];

  ####################
  ### KEYBINDINGS ###
  ####################
  wayland.windowManager.hyprland.settings.bind =
    [
      # Programs: ALT is the WM modifier, SUPER is the command modifier.
      (bind "ALT + T" ''hl.dsp.exec_cmd("kitty")'')
      (bind "SUPER + Q" ''hl.dsp.exec_cmd("${close-application-sh}")'')
      (bind "ALT + E" ''hl.dsp.exec_cmd("kitty --title yazi sh -c 'yazi'")'')
      (bind "ALT + V" ''hl.dsp.window.float({ action = "toggle" })'')
      (bind "SUPER + Space" ''hl.dsp.exec_cmd("rofi-toggle")'')
      (bind "ALT + Space" ''hl.dsp.exec_cmd("rofi-toggle-cliphist")'')
      # Dwindle: pseudo and togglesplit bindings intentionally disabled.
      (bind "ALT + RETURN" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
      (bind "ALT + SHIFT + RETURN" ''hl.dsp.window.fullscreen()'')

      # Screenshot
      (bind "SUPER + SHIFT + 4" ''hl.dsp.exec_cmd("${screenshot-sh}")'')

      # Resolve plugin dispatchers on use: --verify-config does not load plugins.
      # Move focus with WM modifier + H/J/K/L, using the hy3 layout.
      (bind "ALT + L" ''function() hl.plugin.hy3.move_focus("right")() end'')
      (bind "ALT + H" ''function() hl.plugin.hy3.move_focus("left")() end'')
      (bind "ALT + K" ''function() hl.plugin.hy3.move_focus("up")() end'')
      (bind "ALT + J" ''function() hl.plugin.hy3.move_focus("down")() end'')
    ]
    ++ lib.concatMap (workspace: [
      # Switch workspaces; SHIFT moves the active window instead.
      (bind "ALT + ${workspace.key}" ''hl.dsp.focus({ workspace = "${workspace.id}" })'')
      (bind "ALT + SHIFT + ${workspace.key}" ''hl.dsp.window.move({ workspace = "${workspace.id}" })'')
    ]) [
      {
        key = "1";
        id = "1";
      }
      {
        key = "2";
        id = "2";
      }
      {
        key = "3";
        id = "3";
      }
      {
        key = "4";
        id = "4";
      }
      {
        key = "5";
        id = "5";
      }
      {
        key = "O";
        id = "name:obsidian";
      }
      {
        key = "G";
        id = "name:gaming";
      }
      {
        key = "Z";
        id = "name:zen";
      }
    ]
    ++ [
      # Special workspace (scratchpad)
      (bind "ALT + S" ''hl.dsp.workspace.toggle_special("default")'')
      (bind "ALT + SHIFT + S" ''hl.dsp.window.move({ workspace = "special:default" })'')

      # ALT TAB: cycle focus, then raise the active window.
      (bind "ALT + Tab" ''hl.dsp.window.cycle_next()'')
      (bind "ALT + Tab" ''hl.dsp.window.bring_to_top()'')

      # Move/resize with WM modifier + SHIFT + LMB/RMB and dragging.
      {_args = ["ALT + SHIFT + mouse:272" (mkLuaInline "hl.dsp.window.drag()") {mouse = true;}];}
      {_args = ["ALT + SHIFT + mouse:273" (mkLuaInline "hl.dsp.window.resize()") {mouse = true;}];}
    ];
}
