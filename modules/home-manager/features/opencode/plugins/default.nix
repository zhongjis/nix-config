{...}: {
  imports = [
    ./oh-my-opencode
    ./antigravity-auth.nix
  ];

  # Simple plugins without custom configurations
  programs.opencode.settings = {
    plugin = [
      "@simonwjackson/opencode-direnv@latest"
      "@tarquinen/opencode-dcp@latest"
      "@franlol/opencode-md-table-formatter@latest"
    ];
  };
}
