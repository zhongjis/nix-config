{
  lib,
  pkgs,
  aiProfileHelpers,
  commonSkills,
  ...
}: let
  # Import Claude Code-specific skills (supports general-*, work-*, personal-* prefixes)
  localSkillsResult = import ./skills {inherit pkgs lib;};
  localSkillsRaw = localSkillsResult.programs.claude-code.skills or {};

  # Split local skills by prefix for profile-based filtering
  localCommonSkills = lib.filterAttrs (n: _: lib.hasPrefix "general-" n) localSkillsRaw;
  localWorkSkills = lib.filterAttrs (n: _: lib.hasPrefix "work-" n) localSkillsRaw;
  localPersonalSkills = lib.filterAttrs (n: _: lib.hasPrefix "personal-" n) localSkillsRaw;

  # Filter local skills based on profile
  filteredLocalSkills =
    localCommonSkills
    // lib.optionalAttrs aiProfileHelpers.isWork localWorkSkills
    // lib.optionalAttrs aiProfileHelpers.isPersonal localPersonalSkills;

  # Merge pre-filtered common skills and filtered local skills
  allSkills = commonSkills // filteredLocalSkills;
in {
  imports = [
    ../common/skills # Provides commonSkills via _module.args (already filtered by profile)
    ../common/mcp
    ../common/agents
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    skills = allSkills;

    settings = {
      instructions = [
        "${../common/instructions/nix-environment.md}"
      ];
    };
  };
}
