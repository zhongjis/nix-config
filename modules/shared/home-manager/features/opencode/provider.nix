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
    deepseek_api_key = {
      inherit sopsFile;
    };
  };

  programs.opencode.settings.provider = {
    openai = {
      options = {
        apiKey = "{file:${config.sops.secrets.openai_api_key.path}}";
      };
    };
    anthropic = {
      options = {
        apiKey = "{file:${config.sops.secrets.anthropic_api_key.path}}";
      };
    };
    openrouter = {
      options = {
        apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
      };
    };
    deepseek = {
      options = {
        apiKey = "{file:${config.sops.secrets.deepseek_api_key.path}}";
      };
    };
  };
}
