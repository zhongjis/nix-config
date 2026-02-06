# Common Skills Module
#
# This module defines skills that are shared between AI tools (Claude Code, OpenCode).
# Skills are pre-filtered based on aiProfile and exposed via `_module.args.commonSkills`.
#
# Uses prefix convention for profile-based filtering:
#   - general-*: Available on all profiles (defined in commonSkills)
#   - work-*: Only available when aiProfile = "work" (defined in workSkills)
#   - personal-*: Only available when aiProfile = "personal" (defined in personalSkills)
#
# Each tool module imports this and receives already-filtered skills.
{
  pkgs,
  lib,
  aiProfileHelpers,
  ...
}: let
  # Skills available to all profiles
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

  # Skills only for work profile
  workSkills = {
    # Add work-specific skills here
    # work-example = ./work-example;
  };

  # Skills only for personal profile
  personalSkills = {
    # Add personal-specific skills here
    # personal-example = ./personal-example;
  };

  # Pre-filtered skills based on profile
  filteredSkills =
    commonSkills
    // lib.optionalAttrs aiProfileHelpers.isWork workSkills
    // lib.optionalAttrs aiProfileHelpers.isPersonal personalSkills;
in {
  # Expose pre-filtered skills via _module.args for other modules to consume
  _module.args.commonSkills = filteredSkills;

  # Python dependency required by some skills (e.g., general-skill-creator, general-mermaid-diagram-skill)
  home.packages = with pkgs; [
    python3
  ];
}
