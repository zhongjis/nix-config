{
  pkgs,
  lib,
  commonSkills,
  claudeCodeLocalSkills,
  commonInstructions,
  ...
}: let
  # Merge pre-filtered common skills and Claude Code-specific skills (from ./skills)
  # Both are already profile-filtered via _module.args
  allSkills = commonSkills // claudeCodeLocalSkills;

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
    ../common/skills # Provides commonSkills via _module.args (already filtered by profile)
    ../common/mcp
    ../common/agents
    ./skills # Provides claudeCodeLocalSkills via _module.args (already filtered by profile)
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    package = pkgs.claude-code;

    skills = allSkills;

    # Use rules instead of settings.instructions so settings.json is not managed by HM
    rules = instructionRules;
  };
}
