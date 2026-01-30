{
  lib,
  hasPlugin,
  ...
}:
lib.mkIf (hasPlugin "oh-my-opencode") {
  xdg.configFile = {
    "opencode/oh-my-opencode.jsonc".source = ./copilot-work.jsonc;
  };
}
