{
  lib,
  pkgs,
  inputs,
  aiProfileHelpers,
  ...
}: let
  # Import plugin library
  pluginLib = import ./lib.nix {inherit lib;};

  # Nix-built plugins (for packages not on npm or with github: prefix issues)
  morphFastApplyPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-morph-fast-apply;
  ohMyOpenCodePkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.oh-my-opencode;

  # Plugins available to all profiles
  generalPlugins = [
    # Nix-pinned file:// entry registers oh-my-opencode as an OpenCode server
    # plugin (the CLI in home.packages alone does not activate it).
    "file://${ohMyOpenCodePkg}/lib/oh-my-opencode/dist/index.js"
    "@simonwjackson/opencode-direnv@latest"
    "@tarquinen/opencode-dcp@latest"
    "opencode-pty@latest"
    "@slkiser/opencode-quota@latest"
  ];

  # Plugins only for work profile
  workPlugins = [
    "@knikolov/opencode-plugin-simple-memory@latest"
    "@ex-machina/opencode-anthropic-auth"
  ];

  # Plugins only for personal profile
  # Use file:// for Nix-built packages to bypass OpenCode's broken github: handling
  personalPlugins = [
    "file://${morphFastApplyPkg}/lib/node_modules/opencode-morph-fast-apply/index.ts"
    "opencode-supermemory@latest"
    "@nick-vi/opencode-type-inject@latest"
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
    ./oh-my-opencode.nix
    ./morph-fast-apply.nix
    ./supermemory.nix
  ];

  _module.args.hasPlugin = hasPlugin;

  programs.opencode.settings = {
    plugin = plugins;
  };
}
