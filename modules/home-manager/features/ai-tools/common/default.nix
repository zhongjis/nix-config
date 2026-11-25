{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./instructions
    ./mcp
    ./lsp.nix
    ./beads.nix
  ];

  config = lib.mkIf config.myHomeManager.ai-tools.enable {
    # Shared runtimes required by skills, hooks, and MCP servers.
    home.packages = with pkgs; [
      python312
      nodejs_24
    ];
  };
}
