{inputs, ...}: let
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
}
