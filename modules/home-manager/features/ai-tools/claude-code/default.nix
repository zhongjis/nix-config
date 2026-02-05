{
  lib,
  pkgs,
  aiProfileHelpers,
  commonSkills,
  ...
}: let
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
    commonSkills;

  # Strip profile prefixes from skill names for cleaner output
  # general-jq -> jq, work-foo -> foo, personal-bar -> bar
  stripPrefix = name:
    if lib.hasPrefix "general-" name
    then lib.removePrefix "general-" name
    else if lib.hasPrefix "work-" name
    then lib.removePrefix "work-" name
    else if lib.hasPrefix "personal-" name
    then lib.removePrefix "personal-" name
    else name;

  renamedSkills = lib.mapAttrs' (name: value: lib.nameValuePair (stripPrefix name) value) filteredSkills;
in {
  imports = [
    ../common/mcp
  ];

  # Include python3 dependency from skills module
  home.packages = with pkgs; [
    python3
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    skills = renamedSkills;

    settings = {
      instructions = [
        "${../common/instructions/nix-environment.md}"
      ];
    };
  };
}
