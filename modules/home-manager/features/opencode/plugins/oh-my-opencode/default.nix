{
  lib,
  hasPlugin,
  currentSystemName,
  ...
}: let
  configFile =
    if currentSystemName == "mac-m1-max"
    then ./copilot-work.jsonc
    else ./handoff-personal.jsonc;
in
  lib.mkIf (hasPlugin "oh-my-opencode") {
    xdg.configFile = {
      "opencode/oh-my-opencode.jsonc".source = configFile;
    };
  }
