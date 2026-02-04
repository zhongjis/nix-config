{
  lib,
  hasPlugin,
  currentSystemName,
  ...
}: let
  configFile =
    if currentSystemName == "mac-m1-max"
    then ../../../general/oh-my-opencode/work-oh-my-opencode.jsonc
    else ../../../general/oh-my-opencode/personal-oh-my-opencode.jsonc;
in
  lib.mkIf (hasPlugin "oh-my-opencode") {
    xdg.configFile = {
      "opencode/oh-my-opencode.jsonc".source = configFile;
    };
  }
