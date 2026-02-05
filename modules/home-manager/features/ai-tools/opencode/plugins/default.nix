{
  lib,
  aiProfileHelpers,
  ...
}: let
  # Import plugin library
  pluginLib = import ./lib.nix {inherit lib;};

  # Plugins available to all profiles
  generalPlugins = [
    "opencode-antigravity-auth@latest"
    "oh-my-opencode@latest"
    "@simonwjackson/opencode-direnv@latest"
    "@tarquinen/opencode-dcp@latest"
    "@franlol/opencode-md-table-formatter@latest"
  ];

  # Plugins only for work profile
  workPlugins = [
  ];

  # Plugins only for personal profile
  personalPlugins = [
  ];

  # Build final plugin list based on profile
  plugins = pluginLib.mkOpenCodePluginList {
    inherit (aiProfileHelpers) isWork isPersonal;
    inherit generalPlugins workPlugins personalPlugins;
  };

  # Version-agnostic plugin lookup bound to current plugin list
  hasPlugin = pluginLib.hasPlugin plugins;
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
