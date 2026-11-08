{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  internalMonitor = "desc:BOE 0x0BC9";
  lgUntraWideMonitor = "desc:ASUSTek COMPUTER INC PG27UCDM T1LMAS019666";
  dellMonitor = "desc:Dell Inc. DELL P2419H 78NFR63";
in {
  imports = [
    ../../modules/home-manager
    ../../modules/home-manager-linux
  ];
  programs.icm.daemon.enable = true;
  # Capture one tool output per 12 calls (default 3). Read by the Claude Code
  # post hook and the Pi extension's native mode. icm 0.11.5 ignores
  # min_score/max_facts and [memory] prune_threshold, so they are not set.
  programs.icm.settings.extraction.extract_every = 12;

  # icm decays weights on recall but never prunes on its own. Unused medium
  # memories fall below 0.3 after ~23 days; high and critical are never pruned.
  systemd.user.services.icm-prune = {
    Unit.Description = "Prune decayed icm memories";
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe config.programs.icm.package} --no-embeddings prune --threshold 0.3";
    };
  };
  systemd.user.timers.icm-prune = {
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = ["timers.target"];
  };
  myHomeManager.aiProfile = "personal";
  myHomeManager.bundles.general.enable = true;
  myHomeManager.obsidian.enable = true;
  myHomeManager.services.cliproxyapi.enable = true;
  myHomeManager.hyprland.monitors = {
    "desc:BOE 0x0BC9" = {
      width = 2560;
      height = 1600;
      refreshRate = 165.0;
      x = 0;
      y = 0;
      scale = 1.0;
      # scale = 1.;
    };
    "desc:ASUSTek COMPUTER INC PG27UCDM T1LMAS019666" = {
      width = 3840;
      height = 2160;
      refreshRate = 240.0;
      scale = 1.5;
      # x = 2560
      x = 2560;
      y = 0;
    };
    "desc:Dell Inc. DELL P2419H 78NFR63" = {
      width = 1920;
      height = 1080;
      refreshRate = 60.0;
      # x = 6000;
      x = 5488;
      y = 0;
      rotate = 1;
    };
  };
  myHomeManager.hyprland.workspaces = {
    "name:spotify" = {
      monitorId = internalMonitor;
      autostart = with pkgs; [];
    };
    "name:gaming" = {
      monitorId = lgUntraWideMonitor;
      autostart = with pkgs; [];
    };
    "name:zen" = {
      monitorId = lgUntraWideMonitor;
      autostart = with pkgs; [];
    };
  };

  myHomeManager.bundles.linux.enable = true;
  myHomeManager.bundles.hyprland.enable = true;
  myHomeManager.bundles.office.enable = true;

  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.fincept-terminal
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.lark
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.lark-cli
  ];
}
