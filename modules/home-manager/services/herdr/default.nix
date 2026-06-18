{
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  # herdr ships only the app (no home-manager module); the binary is already
  # provided by the llm-agents flake input, same source ai-tools consumes.
  herdrPkg = inputs.llm-agents.packages.${system}.herdr;
in {
  home.packages = [
    herdrPkg
    pkgs.jq # herdr-sessionizer parses `herdr workspace list` JSON
    (pkgs.writeScriptBin "herdr-sessionizer" ''
      ${builtins.readFile ./scripts/herdr-sessionizer.sh}
    '')
  ];

  xdg.configFile."herdr/config.toml".source = ./config.toml;
}
