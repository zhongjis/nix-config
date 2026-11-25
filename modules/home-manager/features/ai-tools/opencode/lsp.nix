{
  config,
  lib,
  commonLsp,
  ...
}: let
  aiCfg = config.myHomeManager.ai-tools;
in {
  config = lib.mkIf (aiCfg.enable && aiCfg.opencode.enable) {
    programs.opencode.settings.lsp = commonLsp;
  };
}
