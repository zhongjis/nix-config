_: {
  programs.opencode.settings = {
    plugin = [
      "oh-my-opencode@latest"
    ];
  };

  xdg.configFile = {
    # "opencode/oh-my-opencode.json".source = ../oh-my-opencode/cheap-but-not-free.json;
    "opencode/oh-my-opencode.json".source = ./v3-poorman-pretends-rich.json;
  };
}
