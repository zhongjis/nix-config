# Common Instructions Module
#
# This module auto-discovers instructions from profile directories and exposes them
# via `_module.args.commonInstructions`. Instructions are pre-filtered based on aiProfile.
#
# Directory structure:
#   - general/  : Instructions available to all profiles
#   - work/     : Instructions only for aiProfile = "work"
#   - personal/ : Instructions only for aiProfile = "personal"
#
# Instruction naming:
#   - Files must be .md (markdown) files
#   - Filename becomes instruction identifier (for reference only)
#
# Disabling instructions:
#   - Prefix file with "disabled-" to skip it
#   - general/disabled-foo.md → skipped
{
  lib,
  aiProfileHelpers,
  ...
}: let
  # Auto-discover instruction files from a profile directory
  # Returns list of file paths
  discoverInstructions = profileDir: let
    # Get all files in the directory
    files = builtins.readDir profileDir;

    # Filter for .md files that aren't disabled
    mdFiles =
      lib.filterAttrs (
        name: type:
          type
          == "regular"
          && lib.hasSuffix ".md" name
          && !(lib.hasPrefix "disabled-" name)
      )
      files;

    # Convert to list of paths
    paths = lib.mapAttrsToList (name: _: profileDir + "/${name}") mdFiles;
  in
    paths;

  # Discover instructions from each profile directory
  generalInstructions = discoverInstructions ./general;
  workInstructions = discoverInstructions ./work;
  personalInstructions = discoverInstructions ./personal;

  # Pre-filtered instructions based on profile
  filteredInstructions =
    generalInstructions
    ++ lib.optionals aiProfileHelpers.isWork workInstructions
    ++ lib.optionals aiProfileHelpers.isPersonal personalInstructions;
in {
  # Expose pre-filtered instructions via _module.args for other modules to consume
  _module.args.commonInstructions = filteredInstructions;
}
