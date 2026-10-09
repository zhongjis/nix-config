{
  config,
  inputs,
  pkgs,
  lib,
  commonInstructions,
  aiProfileHelpers,
  currentSystemName,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  cliproxyapiEnabled =
    currentSystemName
    == "framework-16"
    && aiProfileHelpers.isPersonal
    && lib.attrByPath ["myHomeManager" "services" "cliproxyapi" "enable"] false config;
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  selectedSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
    harness = "pi";
  };

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

  cliproxyapiModels = [
    {
      id = "gpt-5.6-luna";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    }
    {
      id = "gpt-5.6-sol";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    }
    {
      id = "gpt-5.6-terra";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    }
    {
      id = "gpt-6-astra";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    }
    {
      id = "gpt-6-luna";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    }
    {
      id = "gpt-6-sol";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    }
    {
      id = "gpt-6.1-sol";
      reasoning = true;
      thinkingLevelMap = {
        off = "low";
        minimal = "low";
        low = "low";
        medium = "medium";
        high = "high";
        xhigh = "xhigh";
        max = "max";
      };
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    }
  ];

  piModels = {
    providers =
      {
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
      }
      // lib.optionalAttrs cliproxyapiEnabled {
        cliproxyapi = {
          baseUrl = "http://127.0.0.1:8317/backend-api/codex";
          api = "openai-codex-responses";
          # ponytail: public placeholder satisfies today's account parser; signature validation needs a client/account option, never silently substitute a real token.
          apiKey = "eyJhbGciOiJub25lIn0.eyJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9hY2NvdW50X2lkIjoibG9jYWwtY2xpcHJveHlhcGkifX0.placeholder";
          headers."X-Api-Key" = "!cat ${config.xdg.stateHome}/cliproxyapi/api-key";
          models = cliproxyapiModels;
        };
      };
  };

  sharedSettings = {
    # UI & Display
    # The Stylix base16 theme comes from ./stylix-theme.nix.
    theme =
      if config.stylix.enable
      then "stylix"
      else "system";
    collapseChangelog = true;
    enableInstallTelemetry = false;
    treeFilterMode = "no-tools";
    editorPaddingX = 0;
    quietStartup = true;
    doubleEscapeAction = "tree";
    defaultProjectTrust = "always";
    tuiMode = "fullscreen";
    fullscreenExitOutput = "resume-hint";

    # Warnings
    warnings.anthropicExtraUsage = false;

    # Compaction
    compaction = {
      enabled = true;
      reserveTokens = 54400;
      keepRecentTokens = 20000;
    };

    # Branch Summary
    branchSummary.skipPrompt = false;

    # Retry
    retry = {
      enabled = true;
      maxRetries = 5;
      baseDelayMs = 2000;
      maxDelayMs = 60000;
    };

    # Message Delivery
    steeringMode = "all";
    followUpMode = "all";
    transport = "auto";
    httpIdleTimeoutMs = 30000;
    websocketConnectTimeoutMs = 10000;

    # Tools
    defaultTools = ["+codemode"];

    # Resources
    packages = [
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
    ];

    npmCommand = ["bash" "${config.home.homeDirectory}/.pi/agent/scripts/pi-package-npm.sh"];

    permissionLevel = "high";
  };

  workOverrides = {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-8";
    packages =
      sharedSettings.packages
      ++ [
        # "git:github.com/aliou/pi-guardrails@v0.15.0"
      ];
  };

  personalOverrides = {
    # defaultProvider = "llama-swap";
    # defaultModel = "qwen2.5-coder:14b";
    packages =
      sharedSettings.packages
      ++ [
        "git:github.com/Rahularya01/pi-antigravity"
      ];
  };

  piSettings = lib.recursiveUpdate sharedSettings (
    if aiProfileHelpers.isWork
    then workOverrides
    else personalOverrides
  );
in {
  imports = [
    ../../../../../custom-home-manager-options/pi
    ./lsp.nix
    ./stylix-theme.nix
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

  sops.secrets.opencode_zen_api_key = {
    inherit sopsFile;
  };

  programs.pi = {
    enable = true;
    package = llmAgentsPackages.pi;
    # ponytail: gates by "work" profile, not literally hostname. Today work==mac-m1-max 1:1,
    # so this deprovisions opencode/opencode-go for pi on mac only. A future second work-host
    # would also lose it; upgrade path = switch to hostname/currentSystemName if that happens.
    opencodeApiKeyFile =
      if aiProfileHelpers.isWork
      then null
      else config.sops.secrets.opencode_zen_api_key.path;
    rtk.enable = true;
    skills = selectedSkills;
    context = builtins.concatStringsSep "\n\n" (map builtins.readFile (commonInstructions ++ [./instructions/shell-tools.md]));
    models = piModels;
    settings = piSettings;
    enableMcpIntegration = true;
    # pi-config grants read-only agents (Fu Xi, Wenchang) only this server.
    mcpServers = lib.optionalAttrs (config.programs.mcp.servers ? linear) {
      linear-readonly = {
        inherit (config.programs.mcp.servers.linear) headers;
        url = "${config.programs.mcp.servers.linear.url}/readonly";
      };
    };
    keybindings."app.message.followUp" = "ctrl+shift+enter";
  };
}
