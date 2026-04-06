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
  inputs,
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

  externalGeneralSkills = {
    adapt = inputs.impeccable + "/source/skills/adapt";
    animate = inputs.impeccable + "/source/skills/animate";
    arrange = inputs.impeccable + "/source/skills/arrange";
    audit = inputs.impeccable + "/source/skills/audit";
    bolder = inputs.impeccable + "/source/skills/bolder";
    clarify = inputs.impeccable + "/source/skills/clarify";
    colorize = inputs.impeccable + "/source/skills/colorize";
    critique = inputs.impeccable + "/source/skills/critique";
    delight = inputs.impeccable + "/source/skills/delight";
    distill = inputs.impeccable + "/source/skills/distill";
    extract = inputs.impeccable + "/source/skills/extract";
    frontend-design = inputs.impeccable + "/source/skills/frontend-design";
    harden = inputs.impeccable + "/source/skills/harden";
    normalize = inputs.impeccable + "/source/skills/normalize";
    onboard = inputs.impeccable + "/source/skills/onboard";
    optimize = inputs.impeccable + "/source/skills/optimize";
    overdrive = inputs.impeccable + "/source/skills/overdrive";
    polish = inputs.impeccable + "/source/skills/polish";
    quieter = inputs.impeccable + "/source/skills/quieter";
    teach-impeccable = inputs.impeccable + "/source/skills/teach-impeccable";
    typeset = inputs.impeccable + "/source/skills/typeset";
  };

  # Pre-filtered skills based on profile
  filteredSkills =
    (generalSkills // externalGeneralSkills)
    // lib.optionalAttrs aiProfileHelpers.isWork workSkills
    // lib.optionalAttrs aiProfileHelpers.isPersonal personalSkills;
in {
  # Expose pre-filtered skills via _module.args for other modules to consume
  _module.args.commonSkills = filteredSkills;

  # Python dependency required by some skills (e.g., skill-creator, mermaid-diagram-skill)
  home.packages = with pkgs; [
    python312
  ];
}
