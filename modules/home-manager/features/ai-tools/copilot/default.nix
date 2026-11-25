{
  config,
  inputs,
  lib,
  pkgs,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  aiCfg = config.myHomeManager.ai-tools;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  copilotContext = builtins.concatStringsSep "\n\n" (map builtins.readFile commonInstructions);
  selectedSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
  };
in {
  config = lib.mkIf (aiCfg.enable && aiCfg.copilot.enable) {
    programs.github-copilot-cli = {
      enable = true;
      package = llmAgentsPackages.copilot-cli;
      context = copilotContext;
      enableMcpIntegration = true;
      skills = selectedSkills;
      # Keep ~/.copilot/config.json mutable so Copilot can persist runtime state (e.g. trusted_folders).
      settings = {};
    };
  };
}
