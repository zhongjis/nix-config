{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./lsp.nix
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
