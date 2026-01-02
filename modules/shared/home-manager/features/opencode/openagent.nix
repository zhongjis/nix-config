# https://github.com/darrenhinde/OpenAgents
{
  config,
  pkgs,
  ...
}: let
  openAgentsRepo = fetchGit {
    url = "https://github.com/darrenhinde/OpenAgents.git";
    rev = "5334df11a03a027d5a771730ce6f0a17e212a320";
  };
in {
  home.file = {
    ".opencode/agent".source = "${openAgentsRepo}/.opencode/agent";
    ".opencode/command".source = "${openAgentsRepo}/.opencode/command";
    ".opencode/context".source = "${openAgentsRepo}/.opencode/context";
  };
}
