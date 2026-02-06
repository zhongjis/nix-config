# Common Skills Module
#
# This module defines skills that are shared between AI tools (Claude Code, OpenCode).
# Skills are exposed via `_module.args.commonSkills` for consumption by tool-specific modules.
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
  # Define all common skills as a plain attribute set
  # Paths are relative to this file's directory
  commonSkills = {
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

    # skills.sh skills (document/media)
    general-algorithmic-art = ./general-algorithmic-art;
    general-canvas-design = ./general-canvas-design;
    general-docx = ./general-docx;
    general-frontend-design = ./general-frontend-design;
    general-pdf = ./general-pdf;
    general-pptx = ./general-pptx;
    general-theme-factory = ./general-theme-factory;
    general-webapp-testing = ./general-webapp-testing;
    general-xlsx = ./general-xlsx;
  };

  # Helper function to filter skills by profile
  # Usage: filterSkillsByProfile { isWork = true; isPersonal = false; } commonSkills
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
  # Expose common skills and helper via _module.args for other modules to consume
  _module.args = {
    inherit commonSkills filterSkillsByProfile;
  };

  # Python dependency required by some skills (e.g., general-skill-creator, general-mermaid-diagram-skill)
  home.packages = with pkgs; [
    python3
  ];
}
