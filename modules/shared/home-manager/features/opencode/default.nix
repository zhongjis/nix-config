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
      autoupdate = true;

      tui = {
        scroll_accelaeration = {
          enabled = true;
        };
      };

      # compaction = {
      #   auto = false;
      #   prune = true;
      # };
    };
  };
}
