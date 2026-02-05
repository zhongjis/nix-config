{
  lib,
  pkgs,
  aiProfileHelpers,
  sharedSkills,
  filterSkillsByProfile,
  ...
}: let
  # Filter shared skills based on profile
  filteredSharedSkills =
    filterSkillsByProfile {
      inherit (aiProfileHelpers) isWork isPersonal;
    }
    sharedSkills;

  # Import Claude Code-specific skills (supports general-*, work-*, personal-* prefixes)
  localSkillsResult = import ./skills {inherit pkgs lib;};
  localSkillsRaw = localSkillsResult.programs.claude-code.skills or {};

  # Filter local skills at Nix-time based on profile (same logic as shared skills)
  filteredLocalSkills =
    filterSkillsByProfile {
      inherit (aiProfileHelpers) isWork isPersonal;
    }
    localSkillsRaw;

  # Merge shared and local skills
  allSkills = filteredSharedSkills // filteredLocalSkills;
in {
  imports = [
    ../common/skills # Provides sharedSkills and filterSkillsByProfile via _module.args
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
