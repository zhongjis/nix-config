# https://github.com/darrenhinde/OpenAgents
{
  config,
  pkgs,
  ...
}: let
  openAgentsRepo = fetchGit {
    url = "https://github.com/darrenhinde/OpenAgents.git";
    rev = "7e1a7e5775e3b88cd80e982650db27b9f900d142";
  };
in {
  home.file = {
    # ".opencode/agent".source = "${openAgentsRepo}/.opencode/agent";
    ".opencode/command".source = "${openAgentsRepo}/.opencode/command";
    # ".opencode/context".source = "${openAgentsRepo}/.opencode/context";
  };
}
