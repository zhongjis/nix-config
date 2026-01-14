{config, ...}: let
  sopsFile = ../../../../../secrets/ai-tokens.yaml;
in {
  sops.secrets = {
    openrouter_api_key = {
      inherit sopsFile;
    };
    opencode_zen_api_key = {
      inherit sopsFile;
    };
  };

  programs.opencode.settings.provider = {
    openrouter = {
      options = {
        apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
      };
    };
  };
}
