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
    then "openai/gpt-5.5"
    else "openai/gpt-5.5";

  # NOTE: work profile
  programs.opencode.settings.enabled_providers =
    lib.mkIf aiProfileHelpers.isWork
    ["github-copilot" "anthropic" "amazon-bedrock"];

  # NOTE: work profile end

  programs.opencode.settings.provider =
    lib.mkIf aiProfileHelpers.isWork
    {
      amazon-bedrock = {
        options = {
          region = "us-east-1";
          profile = "ajob2b-int";
        };
      };
    };
}
