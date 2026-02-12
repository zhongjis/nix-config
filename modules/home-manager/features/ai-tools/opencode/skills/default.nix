{
  lib,
  aiProfileHelpers,
  commonSkills,
  myLib,
  ...
}: let
  # Auto-discover skills from directory structure
  # Each skill is a directory containing SKILL.md and optional templates/references
  # Supports disabled-* prefix to skip skills
  discoverSkills = profileDir: let
    dirs = myLib.dirsIn profileDir;
    enabledDirs = lib.filterAttrs (name: _: !(lib.hasPrefix "disabled-" name)) dirs;
    skills =
      lib.mapAttrs (name: _: profileDir + "/${name}")
      enabledDirs;
  in
    skills;

  # Discover OpenCode-only skills from subdirectories
  localGeneralSkills = discoverSkills ./general;
  localWorkSkills = discoverSkills ./work;
  localPersonalSkills = discoverSkills ./personal;

  # Apply profile-based filtering
  filteredLocalSkills =
    localGeneralSkills
    // lib.optionalAttrs aiProfileHelpers.isWork localWorkSkills
    // lib.optionalAttrs aiProfileHelpers.isPersonal localPersonalSkills;
in {
  # Merge common skills (from common/skills/) with OpenCode-only skills
  programs.opencode.skills = commonSkills // filteredLocalSkills;
}
