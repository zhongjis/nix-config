{
  lib,
  pkgs,
  aiProfileHelpers,
  ...
}: let
  # pi-web-access reads $XDG_CONFIG_HOME/pi/web-search.json first: Copilot-hosted
  # web_search on a GPT model, Exa when Copilot search is unavailable.
  # ponytail: fixed Copilot Business endpoint; another Copilot plan needs its host here.
  # Upgrade path: derive the Responses URL from Pi's Copilot base URL in pi-web-access.
  piWorkWebSearch = {
    openaiSearchProviders = ["github-copilot"];
    openaiResponsesUrl = "https://api.business.githubcopilot.com/responses";
    openaiSearchModel = "gpt-6-luna";
    searchRouting = {
      providers = ["openai" "exa"];
      fallbackOn = ["transient" "quota" "network" "invalid-response" "unsupported"];
    };
  };
in {
  programs.pi.settings.packages = lib.mkMerge [
    [
      "git:github.com/davebcn87/pi-autoresearch@v1.8.1"
      "git:github.com/nicobailon/pi-web-access@v0.35.0"
      "git:github.com/nicobailon/pi-interactive-shell@v0.17.0"
      "git:github.com/nicobailon/pi-intercom@v0.16.0"
      "git:github.com/chandra447/pi-hermes-memory@v0.9.10"
      "git:github.com/championswimmer/pi-context-usage@v2.1.0"
      "git:github.com/championswimmer/pi-cache-graph@v1.0.2"
      {
        source = "git:github.com/backnotprop/plannotator@v0.27.22";
        extensions = ["apps/pi-extension"];
        skills = ["apps/pi-extension/skills"];
      }
    ]
    (lib.mkIf aiProfileHelpers.isWork [
      # "git:github.com/aliou/pi-guardrails@v0.15.0"
    ])
    (lib.mkIf aiProfileHelpers.isPersonal [
      "git:github.com/Rahularya01/pi-antigravity"
    ])
  ];

  home.file = {
    ".pi/agent/intercom/config.json".text = builtins.toJSON {
      brokerCommand = lib.getExe pkgs.bun;
      brokerArgs = [];
    };
  };

  xdg.configFile = lib.optionalAttrs aiProfileHelpers.isWork {
    "pi/web-search.json".text = builtins.toJSON piWorkWebSearch;
  };
}
