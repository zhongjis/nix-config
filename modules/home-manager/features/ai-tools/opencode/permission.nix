# OpenCode permissions configuration module
# Defines permissions for bash commands and tools
{
  config,
  lib,
  ...
}: let
  aiCfg = config.myHomeManager.ai-tools;
in {
  config = lib.mkIf (aiCfg.enable && aiCfg.opencode.enable) {
    programs.opencode.settings.permission = "allow";
  };
}
