{pkgs, ...}: {
  imports = [
    ./instructions
    ./mcp
    ./lsp.nix
  ];

  # Python dependency required by skills with Python helpers.
  home.packages = with pkgs; [
    python312
  ];
}
