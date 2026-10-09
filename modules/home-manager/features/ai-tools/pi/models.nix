{
  config,
  lib,
  aiProfileHelpers,
  currentSystemName,
  ...
}: let
  cliproxyapiEnabled =
    currentSystemName
    == "framework-16"
    && aiProfileHelpers.isPersonal
    && lib.attrByPath ["myHomeManager" "services" "cliproxyapi" "enable"] false config;

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
in {
  programs.pi.models = {
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
}
