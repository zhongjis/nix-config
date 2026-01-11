{
  config,
  inputs,
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
    package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
    enableMcpIntegration = true;

    settings = {
      autoshare = false;
      autoupdate = false;

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
