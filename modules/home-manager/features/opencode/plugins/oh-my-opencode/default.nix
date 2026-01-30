_: {
  programs.opencode.settings = {
    plugin = [
      "oh-my-opencode@latest"
    ];
  };

  xdg.configFile = {
    "opencode/oh-my-opencode.jsonc".source = ./copilot-work.jsonc;
  };
}
