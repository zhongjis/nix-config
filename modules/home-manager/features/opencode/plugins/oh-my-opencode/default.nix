_: {
  programs.opencode.settings = {
    plugin = [
      "oh-my-opencode@latest"
    ];
  };

  xdg.configFile = {
    "opencode/oh-my-opencode.jsonc".source = ./v3-copilot-opencode-zen-poor.jsonc;
  };
}
