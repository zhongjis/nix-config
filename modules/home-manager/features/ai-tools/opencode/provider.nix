{
  config,
  lib,
  inputs,
  aiProfileHelpers,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
in {
  sops.secrets = {
    openrouter_api_key = {
      inherit sopsFile;
    };
    opencode_zen_api_key = {
      inherit sopsFile;
    };
  };

  programs.opencode.settings.model = "opencode/glm-4.7";

  programs.opencode.settings.enabled_providers =
    lib.mkIf aiProfileHelpers.isWork
    ["amazon-bedrock" "github-copilot"];

  programs.opencode.settings.provider = {
    # openrouter = {
    #   options = {
    #     apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
    #   };
    # };
    # ollama = {
    #   name = "Ollama (local)";
    #   options = {
    #     "baseURL" = "http://localhost:11434/v1";
    #   };
    #   models = {
    #     "qwen3:14b" = {
    #       "name" = "qwen2.5-coder:32b";
    #       "tools" = true;
    #     };
    #     "qwen3:32b" = {
    #       "name" = "qwen3:32b";
    #       "tools" = true;
    #     };
    #     "qwen2.5-coder:32b" = {
    #       "name" = "qwen2.5-coder:32b";
    #       "tools" = true;
    #     };
    #     "phi4:14b" = {
    #       "name" = "phi4:14b";
    #       "tools" = true;
    #     };
    #     "llava-llama3" = {
    #       "name" = "llava-llama3";
    #       "tools" = true;
    #     };
    #     "gemma3:12b" = {
    #       "name" = "gemma3:12b";
    #       "tools" = true;
    #     };
    #     "codestral" = {
    #       "name" = "codestral";
    #       "tools" = true;
    #     };
    #   };
    # };
  };
}
