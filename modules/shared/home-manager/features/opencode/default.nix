{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./lsp.nix
    ./skills
    ./formatters.nix
    ./permission.nix
    ./provider.nix
    ./openagent.nix
    ./plugin.nix
  ];
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      autoshare = false;
      autoupdate = false;
    };
  };
}
