_: {
  programs.opencode.settings = {
    plugin = [
      "oh-my-opencode@latest"
    ];
  };

  xdg.configFile = {
    "opencode/oh-my-opencode.json".source = ./v3-gemini-opencode-zen-poor.jsonc;
  };
}
