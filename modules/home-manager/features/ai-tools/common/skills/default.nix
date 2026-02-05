{pkgs, ...}: {
  home.packages = with pkgs; [
    python3
  ];

  # Skills are exported via _module.args for other modules to consume
  # This avoids directly setting programs.claude-code.skills which would
  # bypass the profile-based filtering in claude-code/default.nix
  _module.args.commonSkills = {
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
}
