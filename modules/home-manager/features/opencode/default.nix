{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./lsp.nix
    ./skills
    ./agents
    ./formatters.nix
    ./permission.nix
    ./provider.nix
    # ./openagent.nix
    ./plugins.nix
  ];

  home.packages = with pkgs; [
    playwright-mcp
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
        diff_style = "stacked";
      };

      # compaction = {
      #   auto = false;
      #   prune = true;
      # };
    };
  };
}
