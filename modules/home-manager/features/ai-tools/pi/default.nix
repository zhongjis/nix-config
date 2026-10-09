{
  config,
  inputs,
  pkgs,
  lib,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  selectedSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
    harness = "pi";
  };
in {
  imports = [
    ../../../../../custom-home-manager-options/pi
    ./lsp.nix
    ./models.nix
    ./packages.nix
    ./settings.nix
    ./stylix-theme.nix
  ];

  sops.secrets.opencode_zen_api_key = {
    inherit sopsFile;
  };

  programs.pi = {
    enable = true;
    package = llmAgentsPackages.pi;
    # ponytail: gates by "work" profile, not literally hostname. Today work==mac-m1-max 1:1,
    # so this deprovisions opencode/opencode-go for pi on mac only. A future second work-host
    # would also lose it; upgrade path = switch to hostname/currentSystemName if that happens.
    opencodeApiKeyFile =
      if aiProfileHelpers.isWork
      then null
      else config.sops.secrets.opencode_zen_api_key.path;
    rtk.enable = true;
    skills = selectedSkills;
    context = builtins.concatStringsSep "\n\n" (map builtins.readFile (commonInstructions ++ [./instructions/shell-tools.md]));
    enableMcpIntegration = true;
    # pi-config grants read-only agents (Fu Xi, Wenchang) only this server.
    mcpServers = lib.optionalAttrs (config.programs.mcp.servers ? linear) {
      linear-readonly = {
        inherit (config.programs.mcp.servers.linear) headers;
        url = "${config.programs.mcp.servers.linear.url}/readonly";
      };
    };
    keybindings."app.message.followUp" = "ctrl+shift+enter";
  };
}
