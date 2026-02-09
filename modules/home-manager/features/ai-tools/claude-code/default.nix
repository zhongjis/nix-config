{
  commonSkills,
  claudeCodeLocalSkills,
  commonInstructions,
  ...
}: let
  # Merge pre-filtered common skills and Claude Code-specific skills (from ./skills)
  # Both are already profile-filtered via _module.args
  allSkills = commonSkills // claudeCodeLocalSkills;
in {
  imports = [
    ../common/skills # Provides commonSkills via _module.args (already filtered by profile)
    ../common/mcp
    ../common/agents
    ./skills # Provides claudeCodeLocalSkills via _module.args (already filtered by profile)
  ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    skills = allSkills;

    settings = {
      instructions = commonInstructions;
      model = "opus";
      includeCoAuthoredBy = false;

      extraKnownMarketplaces = {
        oh-my-claudecode = {
          source = {
            source = "github";
            repo = "Yeachan-Heo/oh-my-claudecode";
          };
        };
        claude-mem = {
          source = {
            source = "github";
            repo = "thedotmack/claude-mem";
          };
        };
      };
    };
  };
}
