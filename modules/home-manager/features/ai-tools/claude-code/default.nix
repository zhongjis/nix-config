{
  inputs,
  pkgs,
  lib,
  commonSkills,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  externalSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
    harness = "claude-code";
  };

  # Tool-specific skills override shared skills on name collisions.
  allSkills = commonSkills // externalSkills;

  # Convert commonInstructions (list of paths) to an attrset for `rules`
  # e.g. /nix/store/...-nix-environment.md → { "nix-environment" = /nix/store/...; }
  instructionRules = builtins.listToAttrs (map (path: let
      filename = builtins.baseNameOf (toString path);
      # Strip .md extension for the rule name
      name = lib.removeSuffix ".md" filename;
    in {
      inherit name;
      value = path;
    })
    commonInstructions);
in {
  imports = [
    ../common/skills
    ../common/mcp
    ../common/agents
  ];

  home.packages = [
    llmAgentsPackages.oh-my-claudecode
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = false;
    package = llmAgentsPackages.claude-code;
    impeccable.enable = false;
    caveman = {
      enable = true;
      mode = "ultra";
    };
    skills = allSkills;

    # Use rules instead of settings.instructions so settings.json is not managed by HM
    rules = instructionRules;
  };
}
