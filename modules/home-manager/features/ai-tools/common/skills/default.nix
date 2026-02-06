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
#   - Directory name becomes skill name with profile prefix
#   - general/jq/ → general-jq
#   - work/foo/   → work-foo
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
  # Returns attrset: { "prefix-skillname" = ./prefix/skillname; }
  discoverSkills = profileDir: prefix: let
    # Get all directories in the profile directory
    dirs = myLib.dirsIn profileDir;

    # Filter out disabled skills and build attrset
    enabledDirs = lib.filterAttrs (name: _: !(lib.hasPrefix "disabled-" name)) dirs;

    # Convert to attrset with prefixed names
    skills =
      lib.mapAttrs' (name: _: {
        name = "${prefix}-${name}";
        value = profileDir + "/${name}";
      })
      enabledDirs;
  in
    skills;

  # Discover skills from each profile directory
  generalSkills = discoverSkills ./general "general";
  workSkills = discoverSkills ./work "work";
  personalSkills = discoverSkills ./personal "personal";

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
