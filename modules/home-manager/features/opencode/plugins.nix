_: {
  programs.opencode.settings = {
    plugin = [
      "@simonwjackson/opencode-direnv@latest"
      "oh-my-opencode@latest"
      "opencode-google-antigravity-auth@latest"
    ];
  };

  xdg.configFile = {
    # "opencode/oh-my-opencode.json".source = ./oh-my-opencode/cheap-but-not-free.json;
    "opencode/oh-my-opencode.json".source = ./oh-my-opencode/cheap-but-not-free.json;
  };
}
