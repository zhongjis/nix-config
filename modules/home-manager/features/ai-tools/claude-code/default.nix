{
  lib,
  pkgs,
  aiProfileHelpers,
  ...
}: let
  # Import skills module to get skill definitions
  # Call the module with required args to get the config attr set
  skillsModuleResult = import ../general/skills {inherit pkgs lib;};
  allSkills = skillsModuleResult.programs.claude-code.skills;

  # Filter skills at Nix-time based on profile
  # - Always include general-* skills
  # - Include work-* skills only for work profile
  # - Include personal-* skills only for personal profile
  filteredSkills =
    lib.filterAttrs (
      name: _:
        lib.hasPrefix "general-" name
        || (aiProfileHelpers.isWork && lib.hasPrefix "work-" name)
        || (aiProfileHelpers.isPersonal && lib.hasPrefix "personal-" name)
    )
    allSkills;
in {
  imports = [
    ../general/mcp
  ];

  # Include python3 dependency from skills module
  home.packages = with pkgs; [
    python3
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    skills = filteredSkills;

    settings = {
      instructions = [
        "${../general/instructions/nix-environment.md}"
      ];
    };
  };
}
