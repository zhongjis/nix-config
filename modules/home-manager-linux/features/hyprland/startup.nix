{
  pkgs,
  lib,
  config,
  ...
}: let
  startScripts = {
    xdg = pkgs.writeShellScriptBin "xdg" ''
      if ! uwsm check is-active hyprland.desktop; then
        systemctl --user import-environment PATH
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        systemctl --user restart xdg-desktop-portal.service
      fi
    '';
    applications = pkgs.writeShellScriptBin "applications" ''
      solaar --window=hide&
      (sleep 2; ${lib.getExe config.programs.waybar.package}) &
      dunst &
      # swaync &
      # hyprswitch init --show-title &
    '';
  };
  startScriptList = builtins.attrValues startScripts;
in {
  home.packages = with pkgs; [
    hyprpolkitagent
  ];

  #################
  ### AUTOSTART ###
  #################

  # Autostart necessary processes (like notifications daemons, status bars, etc.)
  # Or execute your favorite apps at launch like this:
  wayland.windowManager.hyprland.settings = let
    autostarts =
      lib.lists.flatten
      (lib.mapAttrsToList
        (
          id: workspace: (map (command: {
              inherit command;
              rules.workspace = "${id} silent";
            })
            workspace.autostart)
        )
        config.myHomeManager.hyprland.workspaces);
  in {
    startupCommands._var =
      map (command: {inherit command;}) [
        # For fcitx5
        "fcitx5 -d -r"
        "fcitx5-remote -r"
        # TODO: need testing
        # "${lib.getExe pkgs.wlr-randr} --output 1 --primary"

        "wl-paste --type text --watch cliphist store" # Stores only text data
        "systemctl --user start hyprpolkitagent"
        "systemctl --user start hyprpaper"
      ]
      ++ autostarts
      ++ map (s: {command = lib.getExe s;}) startScriptList;
    on._args = [
      "hyprland.start"
      (lib.generators.mkLuaInline
        /*
        lua
        */
        ''
          function()
            for _, entry in ipairs(startupCommands) do
              hl.exec_cmd(entry.command, entry.rules)
            end
          end
        '')
    ];
  };
}
