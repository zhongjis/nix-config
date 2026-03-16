{
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

  programs.opencode.settings.model =
    if aiProfileHelpers.isWork
    then "openai/gpt-5.4"
    else "openai/gpt-5.4";

  # NOTE: work profile
  programs.opencode.settings.enabled_providers =
    lib.mkIf aiProfileHelpers.isWork
    ["github-copilot" "openai"];

  # NOTE: work profile end

  programs.opencode.settings.provider = {
    # openrouter = {
    #   options = {
    #     apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
    #   };
    # };
  };
}
