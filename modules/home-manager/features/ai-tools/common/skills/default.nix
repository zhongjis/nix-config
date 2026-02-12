# Common Skills Module
#
# This module auto-discovers skills from profile directories and exposes them
# via `_module.args.commonSkills`. Skills are pre-filtered based on aiProfile.
#
# Directory structure:
#   - general/  : Skills available to all profiles
#   - work/     : Skills only for aiProfile = "work"
#   - personal/ : Skills only for aiProfile = "personal"
#
# Skill naming:
#   - Directory name becomes skill name as-is
#   - general/jq/ → jq
#   - work/foo/   → foo
#
# Disabling skills:
#   - Prefix directory with "disabled-" to skip it
#   - general/disabled-jq/ → skipped
{
  pkgs,
  lib,
  aiProfileHelpers,
  myLib,
  ...
}: let
  # Auto-discover skill directories from a profile directory
  # Returns attrset: { "skillname" = ./profileDir/skillname; }
  discoverSkills = profileDir: let
    # Get all directories in the profile directory
    dirs = myLib.dirsIn profileDir;

    # Filter out disabled skills and build attrset
    enabledDirs = lib.filterAttrs (name: _: !(lib.hasPrefix "disabled-" name)) dirs;

    # Convert to attrset with directory name as skill name
    skills =
      lib.mapAttrs (name: _: profileDir + "/${name}")
      enabledDirs;
  in
    skills;

  # Discover skills from each profile directory
  generalSkills = discoverSkills ./general;
  workSkills = discoverSkills ./work;
  personalSkills = discoverSkills ./personal;

  # Pre-filtered skills based on profile
  filteredSkills =
    generalSkills
    // lib.optionalAttrs aiProfileHelpers.isWork workSkills
    // lib.optionalAttrs aiProfileHelpers.isPersonal personalSkills;
in {
  # Expose pre-filtered skills via _module.args for other modules to consume
  _module.args.commonSkills = filteredSkills;

  # Python dependency required by some skills (e.g., skill-creator, mermaid-diagram-skill)
  home.packages = with pkgs; [
    python3
  ];
}
