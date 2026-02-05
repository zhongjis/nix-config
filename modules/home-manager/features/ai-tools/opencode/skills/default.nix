# OpenCode Skills Module
#
# Consumes shared skills from common/skills/ and merges with OpenCode-specific skills.
#
# Uses the same prefix convention as common/skills/:
#   - general-*: Available on all profiles
#   - work-*: Only available when aiProfile = "work"
#   - personal-*: Only available when aiProfile = "personal"
#
# Filtering is handled via permission.skill patterns in the parent module at runtime.
#
# Example:
#   general-my-skill = ./general-my-skill;       # All profiles
#   work-my-skill = ./work-my-skill;             # Work profile only
#   personal-my-skill = ./personal-my-skill;     # Personal profile only
#
# Then create: ./<skill-name>/SKILL.md (and any supporting files)
{sharedSkills, ...}: let
  # OpenCode-specific skills (not shared with Claude Code)
  localSkills = {
    # Add OpenCode-only skills here
    # general-example = ./general-example;
  };
in {
  # Merge shared skills from common/skills with local OpenCode-specific skills
  # Local skills override shared skills if there are name conflicts
  programs.opencode.skills = sharedSkills // localSkills;
}
