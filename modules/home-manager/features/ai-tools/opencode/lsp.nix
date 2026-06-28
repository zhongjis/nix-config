{
  config,
  lib,
  commonLsp,
  ...
}: {
  config = lib.mkIf config.programs.opencode.enable {
    programs.opencode.settings.lsp = commonLsp;
  };
}
