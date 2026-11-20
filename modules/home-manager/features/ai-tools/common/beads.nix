{
  config,
  lib,
  aiProfileHelpers,
  pkgs,
  ...
}: {
  config = lib.mkIf aiProfileHelpers.isPersonal {
    home.sessionVariables.LINEAR_TEAM_ID = "bfeea957-f57b-4c82-afd7-1b3eca55fd0e";
    home.sessionVariablesExtra = ''
      export LINEAR_API_KEY="$( ${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.linear_api_key.path} )"
    '';
    programs.beads.settings = {
      "linear.state_map.backlog" = "open";
      "linear.state_map.unstarted" = "open";
      "linear.state_map.started" = "open";
      "linear.state_map.completed" = "closed";
      "linear.state_map.canceled" = "closed";
    };
  };
}
