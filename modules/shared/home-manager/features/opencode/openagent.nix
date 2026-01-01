{
  config,
  pkgs,
  ...
}: let
  openAgentsRepo = fetchGit {
    url = "https://github.com/darrenhinde/OpenAgents.git";
    # Optional: pin to a specific revision for reproducibility
    rev = "abc123def456";
  };
in {
  home.file = {
    ".opencode/agent".source = "${openAgentsRepo}/.opencode/agent";
    ".opencode/command".source = "${openAgentsRepo}/.opencode/command";
    ".opencode/context".source = "${openAgentsRepo}/.opencode/context";
  };
}
