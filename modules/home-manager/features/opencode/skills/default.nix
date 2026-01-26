{...}: {
  programs.claude-code.skills = {
    skill-creator = ./skill-creator;
    playwright = ./playwright;
    jq = ./jq;
  };
}
