{pkgs, ...}: {
  home.packages = with pkgs; [
    python3
  ];

  programs.claude-code.skills = {
    skill-creator = ./skill-creator;
    playwright = ./playwright;
    jq = ./jq;
    mermaid-diagram-skill = ./mermaid-diagram-skill;
  };
}
