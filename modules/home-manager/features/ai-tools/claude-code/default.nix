{
  lib,
  pkgs,
  aiProfileHelpers,
  ...
}: let
  # Import shared skills from common/skills (general-*, work-*, personal-* prefixed)
  sharedSkillsResult = import ../common/skills {inherit pkgs lib;};
  sharedSkills = sharedSkillsResult.programs.claude-code.skills;

  # Filter shared skills at Nix-time based on profile
  # - Always include general-* skills
  # - Include work-* skills only for work profile
  # - Include personal-* skills only for personal profile
  filteredSharedSkills =
    lib.filterAttrs (
      name: _:
        lib.hasPrefix "general-" name
        || (aiProfileHelpers.isWork && lib.hasPrefix "work-" name)
        || (aiProfileHelpers.isPersonal && lib.hasPrefix "personal-" name)
    )
    sharedSkills;

  # Import Claude Code-specific skills (supports general-*, work-*, personal-* prefixes)
  localSkillsResult = import ./skills {inherit pkgs lib;};
  localSkillsRaw = localSkillsResult.programs.claude-code.skills or {};

  # Filter local skills at Nix-time based on profile (same logic as shared skills)
  # - Always include general-* skills
  # - Include work-* skills only for work profile
  # - Include personal-* skills only for personal profile
  filteredLocalSkills =
    lib.filterAttrs (
      name: _:
        lib.hasPrefix "general-" name
        || (aiProfileHelpers.isWork && lib.hasPrefix "work-" name)
        || (aiProfileHelpers.isPersonal && lib.hasPrefix "personal-" name)
    )
    localSkillsRaw;

  # Merge shared and local skills
  allSkills = filteredSharedSkills // filteredLocalSkills;
in {
  imports = [
    ../common/mcp
    ../common/agents
  ];

  # Include python3 dependency from skills module
  home.packages = with pkgs; [
    python3
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
