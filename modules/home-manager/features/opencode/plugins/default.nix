{
  lib,
  config,
  ...
}: let
  stripVersion = name: let
    parts = lib.splitString "@" name;
  in
    if lib.length parts > 1 && !(lib.hasPrefix "@" name)
    then lib.head parts
    else if lib.length parts > 2
    then "@" + (lib.elemAt parts 1)
    else name;

  plugins = [
    "opencode-antigravity-auth@latest"
    "oh-my-opencode@3.1.11"
    "@simonwjackson/opencode-direnv@latest"
    "@tarquinen/opencode-dcp@latest"
    "@franlol/opencode-md-table-formatter@latest"
  ];

  hasPlugin = pluginId:
    lib.any (p: stripVersion p == stripVersion pluginId) plugins;
in {
  imports = [
    ./oh-my-opencode
    ./antigravity-auth.nix
  ];

  _module.args.hasPlugin = hasPlugin;

  programs.opencode.settings = {
    plugin = plugins;
  };
}
