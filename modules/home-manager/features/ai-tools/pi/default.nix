{
  config,
  inputs,
  pkgs,
  lib,
  commonSkills,
  ompLocalSkills,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  allSkills = commonSkills // ompLocalSkills;

  convertEnvPlaceholders = value:
    if builtins.isString value
    then let
      match = builtins.match "[{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" value;
    in
      if match != null
      then "$env:${builtins.elemAt match 0}"
      else value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: convertEnvPlaceholders) value
    else if builtins.isList value
    then map convertEnvPlaceholders value
    else value;

  normalizeMcporterServer = server: let
    converted = convertEnvPlaceholders server;
  in
    if converted ? url && !(converted ? baseUrl)
    then builtins.removeAttrs (converted // {baseUrl = converted.url;}) ["url"]
    else converted;

  mcporterConfig = {
    "$schema" = "https://raw.githubusercontent.com/steipete/mcporter/main/mcporter.schema.json";
    imports = [];
    mcpServers = lib.mapAttrs (_: normalizeMcporterServer) config.programs.mcp.servers;
  };

  piMcporterSettings = {
    configPath = "${config.home.homeDirectory}/.mcporter/mcporter.json";
    timeoutMs = 30000;
    mode = "lazy";
  };

  localLlamaModels = [
    {
      id = "qwen3-coder:30b-a3b";
      name = "Qwen 3 Coder 30B-A3B (powerful local orchestrator)";
      contextWindow = 131072;
      maxTokens = 8192;
    }
    {
      id = "deepseek-r1-qwen3:8b";
      name = "DeepSeek R1 0528 Qwen3 8B (local reasoning)";
      reasoning = true;
      contextWindow = 32768;
      maxTokens = 8192;
    }
    {
      id = "qwen2.5-coder:7b";
      name = "Qwen 2.5 Coder 7B (fast local worker)";
      contextWindow = 32768;
      maxTokens = 8192;
    }
    {
      id = "qwen2.5-coder:14b";
      name = "Qwen 2.5 Coder 14B (main local coding)";
      contextWindow = 32768;
      maxTokens = 8192;
    }
    {
      id = "gemma4:e4b";
      name = "Gemma 4 E4B (tiny offline fallback)";
      contextWindow = 32768;
      maxTokens = 8192;
    }
    {
      id = "qwen3:8b";
      name = "Qwen 3 8B (general planner fallback)";
      reasoning = true;
      contextWindow = 32768;
      maxTokens = 8192;
    }
    {
      id = "granite4.1:8b";
      name = "Granite 4.1 8B (structured fallback)";
      contextWindow = 32768;
      maxTokens = 8192;
    }
  ];

  piModels = {
    providers = {
      llama-swap = {
        baseUrl = "http://127.0.0.1:9292/v1";
        api = "openai-completions";
        apiKey = "llama-swap";
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
        models = localLlamaModels;
      };
    };
  };

  sharedSettings = {
    defaultThinkingLevel = "high";
    quietStartup = true;
    doubleEscapeAction = "tree";
    compaction = {
      enabled = true;
      reserveTokens = 16384;
      keepRecentTokens = 20000;
    };
    retry = {
      enabled = true;
      maxRetries = 3;
      baseDelayMs = 2000;
      maxDelayMs = 60000;
    };
    lastChangelogVersion = "0.74.0";
    collapseChangelog = true;
    treeFilterMode = "no-tools";
    transport = "websocket-cached";
    npmCommand = ["bash" "${config.home.homeDirectory}/.pi/agent/scripts/pi-package-npm.sh"];
    packages = [
      "git:github.com/mavam/pi-mcporter@v0.3.2"
      "git:github.com/RimuruW/pi-hashline-edit@v0.6.1"
      "git:github.com/aliou/pi-guardrails@v0.11.2"
      "git:github.com/fluxgear/pi-thinking-steps@v1.0.9"
      "git:github.com/davebcn87/pi-autoresearch@v1.4.0"
      {
        source = "git:github.com/backnotprop/plannotator@0.19.11";
        extensions = ["apps/pi-extension"];
        skills = ["apps/pi-extension/skills"];
      }
    ];
    permissionLevel = "high";
  };

  workOverrides = {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-7";
  };

  personalOverrides = {
    defaultProvider = "llama-swap";
    defaultModel = "qwen2.5-coder:14b";
    # Only read by openai-codex provider; ignored by others (no fallback).
    # Options: "sse" (default), "websocket", "websocket-cached", "auto".
    # "websocket-cached" = WS + cached prompt context, no SSE fallback on failure.
  };

  piSettings = lib.recursiveUpdate sharedSettings (
    if aiProfileHelpers.isWork
    then workOverrides
    else personalOverrides
  );
in {
  imports = [
    ../../../../../custom-home-manager-options/pi
  ];

  home.packages = [
    llmAgentsPackages.mcporter
  ];

  home.file = {
    ".mcporter/mcporter.json".text = builtins.toJSON mcporterConfig;
    ".pi/agent/mcporter.json".text = builtins.toJSON piMcporterSettings;
    ".pi/agent/models.json".text = builtins.toJSON piModels;
  };

  sops.secrets.opencode_zen_api_key = {
    inherit sopsFile;
  };

  programs.pi = {
    enable = true;
    package = llmAgentsPackages.pi;
    opencodeApiKeyFile = config.sops.secrets.opencode_zen_api_key.path;
    impeccable.enable = true;
    rtk.enable = true;
    skills = allSkills;
    instructions =
      commonInstructions
      ++ [
        "${./instructions/mcporter.md}"
        "${./instructions/shell-tools.md}"
      ];
    settings = piSettings;
  };
}
