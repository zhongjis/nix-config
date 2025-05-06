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
  ];

  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    # NOTE: below two are defined in nixos module
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

        windowrule = workspace special:default,class:^(vesktop)$

        windowrule = workspace name:spotify,class:^(spotify)$

        windowrule = workspace name:obsidian,class:^(obsidian)$

        windowrule = workspace name:gaming,class:^(steam)$
        windowrule = workspace name:gaming,class:^(heroic)$
        windowrule = workspace name:gaming,class:^(com.usebottles.bottles)$
        windowrule = workspace name:gaming,class:^(steam_proton)$
        windowrule = workspace name:gaming,class:^(gamescope)$

        windowrule = workspace name:zen,class:^(vivaldi-stable)$

        # Pavucontrol floating
        windowrule = float,class:(.*org.pulseaudio.pavucontrol.*)
        windowrule = size 900 800,class:(.*org.pulseaudio.pavucontrol.*)
        windowrule = center,class:(.*org.pulseaudio.pavucontrol.*)
        windowrule = pin,class:(.*org.pulseaudio.pavucontrol.*)

        # hide xwaylandvideobridge, more detial see
        # https://wiki.hyprland.org/Useful-Utilities/Screen-Sharing/#xwayland
        windowrule = opacity 0.0 override, class:^(xwaylandvideobridge)$
        windowrule = noanim, class:^(xwaylandvideobridge)$
        windowrule = noinitialfocus, class:^(xwaylandvideobridge)$
        windowrule = maxsize 1 1, class:^(xwaylandvideobridge)$
        windowrule = noblur, class:^(xwaylandvideobridge)$
        windowrule = nofocus, class:^(xwaylandvideobridge)$

        # hope to fix some steam focus issue
        # NOTE: https://www.reddit.com/r/hyprland/comments/19c53ub/steam_on_hyprland_is_extremely_wonky/
        # windowrule = stayfocused, title:^()$,class:^(steam)$
        # windowrule = minsize 1 1, title:^()$,class:^(steam)$

        # for fcitx5
        # reference: https://discourse.nixos.org/t/pinyin-input-method-in-hyprland-wayland-for-simplified-chinese/49186
        windowrule = pseudo, title:^()$,class:^(fcitx)$
        exec-once=fcitx5 -d -r
        exec-once=fcitx5-remote -r

        # Browser Picture in Picture
        windowrule = float, title:^(Picture-in-Picture)$
        windowrule = pin, title:^(Picture-in-Picture)$
        windowrule = move 69.5% 4%, title:^(Picture-in-Picture)$
      '';
  };
}
