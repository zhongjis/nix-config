{
  lib,
  hasPlugin,
  aiProfileHelpers,
  ...
}: let
  configFile =
    if aiProfileHelpers.isWork
    then ./work-oh-my-opencode.jsonc
    else ./personal-oh-my-opencode.jsonc;
in
  lib.mkIf (hasPlugin "oh-my-opencode") {
    xdg.configFile = {
      "opencode/oh-my-opencode.jsonc".source = configFile;
    };
  }
