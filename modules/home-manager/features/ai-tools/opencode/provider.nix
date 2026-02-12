{
  config,
  lib,
  inputs,
  aiProfileHelpers,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  awsSecretPath = config.sops.secrets.aws_bearer_token_bedrock.path;
in {
  sops.secrets = {
    openrouter_api_key = {
      inherit sopsFile;
    };
    opencode_zen_api_key = {
      inherit sopsFile;
    };
    aws_bearer_token_bedrock = {
      inherit sopsFile;
    };
  };

  programs.opencode.settings.model = "opencode/glm-4.7";

  # NOTE: work profile
  programs.opencode.settings.enabled_providers =
    lib.mkIf aiProfileHelpers.isWork
    ["amazon-bedrock" "github-copilot"];

  programs.zsh.initContent =
    lib.mkOrder
    100 ''
      if [[ -r "${awsSecretPath}" ]]; then
        export AWS_BEARER_TOKEN_BEDROCK="$(<"${awsSecretPath}")"
      fi
    '';

  programs.opencode.settings.provider.amazon-bedrock =
    lib.mkIf aiProfileHelpers.isWork
    {
      options.region = "us-west-2";
    };

  # NOTE: work profile end

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
