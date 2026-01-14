_: {
  programs.opencode.settings = {
    plugin = [
      "opencode-websearch-cited"
      "@simonwjackson/opencode-direnv"
      "oh-my-opencode"
    ];

    provider.openrouter = {
      options = {
        websearch_cited = {
          model = "x-ai/grok-4.1-fast";
        };
      };
    };

    home.file = {
      "opencode/oh-my-opencode.json".source = ./oh-my-opencode/v1-cheap-but-not-free.json;
    };
  };
}
