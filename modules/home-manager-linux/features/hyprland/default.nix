{
  config,
  lib,
  pkgs,
  ...
}: let
  workspaceToMonitorSetup =
    lib.mapAttrsToList
    (id: workspace: "workspace = ${id},monitor:${workspace.monitorId}")
    config.myHomeManager.hyprland.workspaces;
in {
  imports = [
    ./startup.nix
    ./monitors.nix
    ./env.nix
    ./keymaps.nix
    ./settings.nix
    ./plugins.nix
  ];

  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    # NOTE: set the Hyprland and XDPH packages to null to use the ones from the NixOS module
    package = null;
    portalPackage = null;
    # See https://wiki.hyprland.org/Configuring/Monitors/
    settings.monitor =
      lib.mapAttrsToList
      (
        name: m: let
          resolution = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
          position = "${toString m.x}x${toString m.y}";
          scale = "${toString m.scale}";
          transform =
            if m.rotate == 0
            then ""
            else "transform,${toString m.rotate}";
        in "${name},${
          if m.enabled
          then "${resolution},${position},${scale},${transform},vrr,1"
          else "disable"
        }"
      )
      (config.myHomeManager.hyprland.monitors);

    extraConfig = with config.lib.stylix.colors;
    /*
    hyprlang
    */
      ''
        ##############################
        ### WINDOWS AND WORKSPACES ###
        ##############################

        ${lib.concatLines workspaceToMonitorSetup}

        windowrule = workspace special:default, match:class vesktop

        windowrule = workspace name:spotify, match:class spotify

        windowrule = workspace name:obsidian, match:class obsidian

        windowrule = workspace name:gaming, match:class steam
        windowrule = workspace name:gaming, match:class heroic
        windowrule = workspace name:gaming, match:class com\.usebottles\.bottles
        windowrule = workspace name:gaming, match:class steam_proton
        windowrule = workspace name:gaming, match:class gamescope

        windowrule = workspace name:zen, match:class zen-beta
        windowrule = workspace name:zen, match:class helium

        # Pavucontrol floating - combine effects in one line
        windowrule = float on, size 900 800, center on, pin on, match:class org\.pulseaudio\.pavucontrol

        # hide xwaylandvideobridge - combine effects
        windowrule = opacity 0.0 override, no_anim on, no_initial_focus on, max_size 1 1, no_blur on, no_focus on, match:class xwaylandvideobridge

        # for fcitx5
        windowrule = pseudo on, match:class fcitx, match:title ^()$

        exec-once = fcitx5 -d -r
        exec-once = fcitx5-remote -r

        # Browser Picture in Picture - combine effects
        windowrule = float on, pin on, move 69.5% 4%, match:title Picture-in-Picture
      '';
  };
}
