# OpenCode-specific skills
# Skills defined here are ONLY available to OpenCode, not Claude Code.
#
# Uses the same prefix convention as common/skills/:
#   - general-*: Available on all profiles
#   - work-*: Only available when aiProfile = "work"
#   - personal-*: Only available when aiProfile = "personal"
#
# Filtering is handled via permission.skill patterns in the parent module.
#
# Example:
#   general-my-skill = ./general-my-skill;       # All profiles
#   work-my-skill = ./work-my-skill;             # Work profile only
#   personal-my-skill = ./personal-my-skill;     # Personal profile only
#
# Then create: ./<skill-name>/SKILL.md (and any supporting files)
{...}: {
  programs.opencode.skills = {
    # Add OpenCode-only skills here
    # general-example = ./general-example;
  };
}
