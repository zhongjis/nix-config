{
  config,
  lib,
  commonLsp,
  ...
}: let
  aiCfg = config.myHomeManager.ai-tools;
in {
  config = lib.mkIf (aiCfg.enable && aiCfg.pi.enable) {
    home.file.".pi/agent/lsp.json".text = builtins.toJSON {
      lsp = commonLsp;
    };
  };
}
