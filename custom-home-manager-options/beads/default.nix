{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.programs.beads;
  anchor = "${config.xdg.dataHome}/beads/global";
  bd = "${cfg.package}/bin/bd";
  environment = {
    BEADS_DOLT_SHARED_SERVER = "1";
    BEADS_DIR = "${anchor}/.beads";
  };
  bootstrap = pkgs.writeShellScript "beads-start" ''
    set -eu
    export PATH=${lib.makeBinPath [cfg.package pkgs.dolt pkgs.coreutils]}:$PATH
    ${bd} -C ${lib.escapeShellArg anchor} dolt start
    ${bd} -C ${lib.escapeShellArg anchor} init --shared-server --init-if-missing --skip-agents --skip-hooks
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: "${bd} -C ${lib.escapeShellArg anchor} config set ${lib.escapeShellArg key} ${lib.escapeShellArg value}") cfg.settings)}
  '';
  launch = pkgs.writeShellScript "beads-launch" ''
    set -eu
    ${bootstrap}
    trap '${bd} -C ${lib.escapeShellArg anchor} dolt stop; exit' TERM INT
    ${pkgs.coreutils}/bin/sleep infinity &
    wait $!
  '';
in {
  options.programs.beads = {
    enable = lib.mkEnableOption "beads task tracking";
    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.beads;
      defaultText = lib.literalExpression "inputs.llm-agents.packages.\${pkgs.stdenv.hostPlatform.system}.beads";
      description = "Beads package used by the CLI and login service.";
    };
    server.enable = lib.mkEnableOption "the machine-wide shared beads server";
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Non-secret bd config values applied after each server start.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {home.packages = [cfg.package];}
    (lib.mkIf cfg.server.enable {
      home.sessionVariables = environment;
      # bd 1.3.4 reads the resolved BEADS_DIR/PRIME.md after the cwd override.
      home.file."beads-prime" = {
        target = "${anchor}/.beads/PRIME.md";
        source = ./PRIME.md;
      };
      systemd.user.services.beads = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        Unit.Description = "Global beads shared server";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = lib.mapAttrsToList (key: value: "${key}=${value}") environment;
          WorkingDirectory = anchor;
          ExecStart = bootstrap;
          ExecStop = "${bd} -C ${lib.escapeShellArg anchor} dolt stop";
        };
        Install.WantedBy = ["default.target"];
      };
      launchd.agents.beads = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        config = {
          Label = "org.nix-community.home.beads";
          ProgramArguments = ["${launch}"];
          EnvironmentVariables = environment;
          WorkingDirectory = anchor;
          RunAtLoad = true;
          KeepAlive = false;
        };
      };
    })
  ]);
}
