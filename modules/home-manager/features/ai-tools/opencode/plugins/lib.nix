# OpenCode Plugins Library
#
# Provides helper functions for managing OpenCode plugins with profile-based filtering.
#
# Usage:
#   let
#     pluginLib = import ./lib.nix { inherit lib; };
#     plugins = pluginLib.mkOpenCodePluginList {
#       inherit (aiProfileHelpers) isWork isPersonal;
#       generalPlugins = [ "plugin-a@latest" ];
#       workPlugins = [ "work-plugin@latest" ];
#       personalPlugins = [ "personal-plugin@latest" ];
#     };
#   in plugins
{lib}: rec {
  # Extract the base plugin name from various formats
  # Examples:
  #   "plugin-name@latest" -> "plugin-name"
  #   "@scope/plugin@1.0.0" -> "@scope/plugin"
  #   "plugin-name" -> "plugin-name"
  #   "github:user/repo" -> "repo"
  #   "github:user/repo@ref" -> "repo"
  normalizePluginName = name: let
    # Handle github: prefix first
    withoutGithub =
      if lib.hasPrefix "github:" name
      then let
        # Remove "github:" prefix and extract repo name
        afterGithub = lib.removePrefix "github:" name;
        # Split by "/" to get user/repo, then by "@" to remove ref
        pathParts = lib.splitString "/" afterGithub;
        repoWithRef =
          if lib.length pathParts >= 2
          then lib.elemAt pathParts 1
          else afterGithub;
        # Remove @ref suffix if present
        repoParts = lib.splitString "@" repoWithRef;
      in
        lib.head repoParts
      else name;

    # Now handle @version suffix for non-github plugins
    parts = lib.splitString "@" withoutGithub;
  in
    if lib.hasPrefix "github:" name
    then withoutGithub
    else if lib.length parts > 1 && !(lib.hasPrefix "@" withoutGithub)
    then lib.head parts
    else if lib.length parts > 2
    then "@" + (lib.elemAt parts 1)
    else withoutGithub;

  # Backwards compatibility alias
  stripVersion = normalizePluginName;

  # Build the final plugin list based on profile
  # Args:
  #   isWork: boolean - true if current profile is "work"
  #   isPersonal: boolean - true if current profile is "personal"
  #   generalPlugins: list - plugins available to all profiles
  #   workPlugins: list - plugins only for work profile
  #   personalPlugins: list - plugins only for personal profile
  # Returns: list of plugin identifiers
  mkOpenCodePluginList = {
    isWork ? false,
    isPersonal ? false,
    generalPlugins ? [],
    workPlugins ? [],
    personalPlugins ? [],
  }:
    generalPlugins
    ++ lib.optionals isWork workPlugins
    ++ lib.optionals isPersonal personalPlugins;

  # Check if a plugin is in a given plugin list (version-agnostic)
  # Args:
  #   plugins: list - the plugin list to search
  #   pluginId: string - the plugin identifier to find
  # Returns: boolean
  hasPlugin = plugins: pluginId:
    lib.any (p: stripVersion p == stripVersion pluginId) plugins;
}
