{
  config,
  inputs,
  lib,
  ...
}: let
  aiCfg = config.myHomeManager.ai-tools;
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
in {
  config = lib.mkIf (aiCfg.enable && aiCfg.opencode.enable) {
    sops.secrets = {
      openrouter_api_key = {
        inherit sopsFile;
      };
      opencode_zen_api_key = {
        inherit sopsFile;
      };
    };
  };
}
