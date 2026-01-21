_: {
  programs.opencode.settings = {
    plugin = [
      "@simonwjackson/opencode-direnv"
      "oh-my-opencode@v2.14.0"
    ];
  };

  xdg.configFile = {
    # "opencode/oh-my-opencode.json".source = ./oh-my-opencode/cheap-but-not-free.json;
    "opencode/oh-my-opencode.json".source = ./oh-my-opencode/cheap-but-not-free.json;
  };
}
