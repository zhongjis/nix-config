{...}: {
  programs.opencode.settings = {
    plugin = [
      "opencode-websearch-cited"
      "@simonwjackson/opencode-direnv"
    ];

    provider.openrouter = {
      options = {
        websearch_cited = {
          model = "x-ai/grok-4.1-fast";
        };
      };
    };
  };
}
