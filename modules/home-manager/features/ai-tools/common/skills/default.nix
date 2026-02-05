# Shared Skills Template
#
# This module defines skills that are shared between AI tools (Claude Code, OpenCode).
# Skills are exposed via `_module.args.sharedSkills` for consumption by tool-specific modules.
#
# Uses prefix convention for profile-based filtering:
#   - general-*: Available on all profiles
#   - work-*: Only available when aiProfile = "work"
#   - personal-*: Only available when aiProfile = "personal"
#
# Each tool module imports this and applies skills to its own `programs.*.skills` option.
{
  pkgs,
  lib,
  ...
}: let
  # Define all shared skills as a plain attribute set
  # Paths are relative to this file's directory
  sharedSkills = {
    general-skill-creator = ./general-skill-creator;
    general-agent-browser = ./general-agent-browser;
    general-jq = ./general-jq;
    general-mermaid-diagram-skill = ./general-mermaid-diagram-skill;
    general-find-skills = ./general-find-skills;

    general-gh = ./general-gh;

    # knoopx/pi skills - https://github.com/knoopx/pi
    general-ast-grep = ./general-ast-grep;
    general-bun = ./general-bun;
    general-jc = ./general-jc;
    general-jujutsu = ./general-jujutsu;
    general-nh = ./general-nh;
    general-nix = ./general-nix;
    general-nix-flakes = ./general-nix-flakes;
    general-podman = ./general-podman;
    general-python = ./general-python;
    general-scraping = ./general-scraping;
    general-typescript = ./general-typescript;
    general-uv = ./general-uv;
    general-vitest = ./general-vitest;
    general-yt-dlp = ./general-yt-dlp;

    # skills.sh skills
    general-recharts-patterns = ./general-recharts-patterns;

    # other
    general-playwright = ./general-playwright;
  };

  # Helper function to filter skills by profile
  # Usage: filterSkillsByProfile { isWork = true; isPersonal = false; } sharedSkills
  filterSkillsByProfile = {
    isWork ? false,
    isPersonal ? false,
  }: skills:
    lib.filterAttrs (
      name: _:
        lib.hasPrefix "general-" name
        || (isWork && lib.hasPrefix "work-" name)
        || (isPersonal && lib.hasPrefix "personal-" name)
    )
    skills;
in {
  # Expose shared skills and helper via _module.args for other modules to consume
  _module.args = {
    inherit sharedSkills filterSkillsByProfile;
  };

  # Python dependency required by some skills (e.g., general-skill-creator, general-mermaid-diagram-skill)
  home.packages = with pkgs; [
    python3
  ];
}
