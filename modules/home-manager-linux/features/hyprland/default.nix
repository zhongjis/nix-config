{
  config,
  lib,
  ...
}: {
  imports = [
    ./startup.nix
    ./monitors.nix
    ./env.nix
    ./keymaps.nix
    ./settings.nix
    ./plugins.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    # Use the Hyprland and XDPH packages from the NixOS module.
    package = null;
    portalPackage = null;
    configType = "lua";
    importantPrefixes = ["config" "curve"];
    settings = {
      # See https://wiki.hypr.land/Configuring/Basics/Monitors/
      monitor = lib.mapAttrsToList (name: m:
        {output = name;}
        // (
          if m.enabled
          then {
            mode = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
            position = "${toString m.x}x${toString m.y}";
            scale = toString m.scale;
            transform = m.rotate;
            # fullscreen game/video content only: always-on VRR flickers dark
            # content on OLED, and fullscreen browsers should stay at fixed refresh
            vrr = 3;
          }
          else {disabled = true;}
        ))
      config.myHomeManager.hyprland.monitors;

      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################
      workspace_rule =
        lib.mapAttrsToList (id: workspace: {
          workspace = id;
          monitor = workspace.monitorId;
        })
        config.myHomeManager.hyprland.workspaces;

      window_rule =
        (map (rule: {
            match.class = rule.class;
            workspace = rule.workspace;
          }) [
            {
              class = "vesktop";
              workspace = "special:default";
            }
            {
              class = "spotify";
              workspace = "name:spotify";
            }
            {
              class = "obsidian";
              workspace = "name:obsidian";
            }
            {
              class = "steam";
              workspace = "name:gaming";
            }
            {
              class = "heroic";
              workspace = "name:gaming";
            }
            {
              class = ''com\.usebottles\.bottles'';
              workspace = "name:gaming";
            }
            {
              class = "steam_proton";
              workspace = "name:gaming";
            }
            {
              class = "gamescope";
              workspace = "name:gaming";
            }
            {
              class = "zen-beta";
              workspace = "name:zen";
            }
            {
              class = "helium";
              workspace = "name:zen";
            }
          ])
        ++ [
          # Games rarely send a content type; tag them so vrr = 3 triggers
          {
            match.class = ''^(steam_app_.*|steam_proton|gamescope)$'';
            content = "game";
          }
          # Pavucontrol floating - combine effects
          {
            match.class = ''org\.pulseaudio\.pavucontrol'';
            float = true;
            size = "900 800";
            center = true;
            pin = true;
          }
          # Hide xwaylandvideobridge - combine effects
          {
            match.class = "xwaylandvideobridge";
            opacity = "0.0 override";
            no_anim = true;
            no_initial_focus = true;
            max_size = "1 1";
            no_blur = true;
            no_focus = true;
          }
          # For fcitx5
          {
            match = {
              class = "fcitx";
              title = "^()$";
            };
            pseudo = true;
          }
          # Browser Picture in Picture - combine effects
          {
            match.title = "Picture-in-Picture";
            float = true;
            pin = true;
            move = "69.5% 4%";
          }
        ];
    };
  };
}
