{config, ...}: let
  sopsFile = ../../../../../secrets/ai-tokens.yaml;
in {
  sops.secrets = {
    # github - personal
    openai_api_key = {
      inherit sopsFile;
    };
    anthropic_api_key = {
      inherit sopsFile;
    };
    openrouter_api_key = {
      inherit sopsFile;
    };
  };

  programs.opencode.settings.provider = {
        openai = {
          options = {
            apiKey = "{file:${config.sops.secrets.openai_api_key.path}}";
          };
          models = {
            "gpt-4.1-2025-04-14".name = "GPT 4.1";
            "o4-mini-2025-04-16".name = "GPT o4 Mini";
            "gpt-4o-2024-11-20".name = "GPT 4o";
          };
        };
        anthropic = {
          options = {
            apiKey = "{file:${config.sops.secrets.anthropic_api_key.path}}";
          };
          models = {
            "claude-sonnet-4-20250514".name = "Claude 4 Sonnet";
            "claude-3-5-sonnet-latest".name = "Claude 3.5 Sonnet";
          };
        };
        openrouter = {
          options = {
            apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
          };
          models = {
            "google/gemini-2.5-flash".name = "Gemni 2.5 Flash";
            "google/gemini-2.5-flash-preview-05-20:thinking".name = "Gemni 2.5 Flash (Thinking) Preview";
            "google/gemini-2.5-pro".name = "Gemni 2.5 Pro";
            "deepseek/deepseek-r1-0528:free".name = "Deepseek R1 0528 (Free)";
            "deepseek/deepseek-r1:free".name = "Deepseek R1 (Free)";
          };
        };
    };
