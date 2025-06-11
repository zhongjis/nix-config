{
  pkgs,
  lib,
  config,
  ...
}: let
  startScripts = {
    xdg = pkgs.writeShellScriptBin "xdg" ''
      systemctl --user import-environment PATH &
      systemctl --user restart xdg-desktop-portal.service &
    '';
    applications = pkgs.writeShellScriptBin "applications" ''
      solaar --window=hide&
      waybar &
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
    moveToMonitor =
      lib.mapAttrsToList
      (id: workspace: "hyprctl dispatch moveworkspacetomonitor ${id} ${workspace.monitorId}")
      config.myHomeManager.hyprland.workspaces;

    moveToMonitorScript = pkgs.writeShellScriptBin "script" ''
      ${lib.concatLines moveToMonitor}
    '';

    autostarts =
      lib.lists.flatten
      (lib.mapAttrsToList
        (
          id: workspace: (map (startentry: "[workspace ${id} silent] ${startentry}") workspace.autostart)
        )
        config.myHomeManager.hyprland.workspaces);

    monitorScript = pkgs.writeShellScriptBin "script" ''
      handle() {
        case $1 in monitoradded*)
          ${lib.getExe moveToMonitorScript}
        esac
      }

      ${lib.getExe pkgs.socat} - "UNIX-CONNECT:/tmp/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" | while read -r line; do handle "$line"; done
    '';
  in {
    exec-once =
      [
        (lib.getExe monitorScript)

        "nextcloud"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "wl-paste --type text --watch cliphist store" # Stores only text data
        "systemctl --user start hyprpolkitagent"
      ]
      ++ autostarts
      ++ map (s: lib.getExe s) startScriptList;
  };
}
