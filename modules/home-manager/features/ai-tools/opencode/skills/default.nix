# OpenCode Skills Module
#
# Consumes pre-filtered skills from common/skills/ and merges with OpenCode-specific skills.
#
# Uses the same prefix convention as common/skills/:
#   - general-*: Available on all profiles
#   - work-*: Only available when aiProfile = "work"
#   - personal-*: Only available when aiProfile = "personal"
#
# Profile filtering is already applied in common/skills/ based on aiProfile.
#
# Example:
#   general-my-skill = ./general-my-skill;       # All profiles
#   work-my-skill = ./work-my-skill;             # Work profile only
#   personal-my-skill = ./personal-my-skill;     # Personal profile only
#
# Then create: ./<skill-name>/SKILL.md (and any supporting files)
{
  lib,
  aiProfileHelpers,
  commonSkills,
  ...
}: let
  # OpenCode-specific skills (not shared with Claude Code)
  # Uses the same prefix convention - profile filtering applied below
  localSkills = {
    # Add OpenCode-only skills here
    # general-example = ./general-example;
    # work-example = ./work-example;
    # personal-example = ./personal-example;
  };

  # Split local skills by prefix for profile-based filtering
  localCommonSkills = lib.filterAttrs (n: _: lib.hasPrefix "general-" n) localSkills;
  localWorkSkills = lib.filterAttrs (n: _: lib.hasPrefix "work-" n) localSkills;
  localPersonalSkills = lib.filterAttrs (n: _: lib.hasPrefix "personal-" n) localSkills;

  # Filter local skills based on profile
  filteredLocalSkills =
    localCommonSkills
    // lib.optionalAttrs aiProfileHelpers.isWork localWorkSkills
    // lib.optionalAttrs aiProfileHelpers.isPersonal localPersonalSkills;
in {
  # Merge pre-filtered common skills with filtered local OpenCode-specific skills
  # Local skills override common skills if there are name conflicts
  programs.opencode.skills = commonSkills // filteredLocalSkills;
}
