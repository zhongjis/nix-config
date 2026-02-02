{pkgs, ...}: {
  home.packages = with pkgs; [
    python3
  ];

  programs.claude-code.skills = {
    skill-creator = ./skill-creator;
    # playwright = ./playwright;
    jq = ./jq;
    mermaid-diagram-skill = ./mermaid-diagram-skill;
    find-skills = ./find-skills;

    # knoopx/pi skills - https://github.com/knoopx/pi
    ast-grep = ./ast-grep;
    bun = ./bun;
    jc = ./jc;
    jujutsu = ./jujutsu;
    nh = ./nh;
    nix = ./nix;
    nix-flakes = ./nix-flakes;
    podman = ./podman;
    python = ./python;
    scraping = ./scraping;
    typescript = ./typescript;
    uv = ./uv;
    vitest = ./vitest;
    yt-dlp = ./yt-dlp;
  };
}
