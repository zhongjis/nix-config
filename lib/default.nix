# Simplified Library for Nix-Config
#
# Contains helper functions that flake-parts doesn't provide:
# - File/directory discovery helpers
# - Module extension system for bundle/feature enable options
#
# Functions moved to flake-parts modules:
# - mkSystem -> modules/flake/nixos.nix and darwin.nix
# - mkHome -> modules/flake/home.nix
# - forAllSystems -> perSystem in flake.nix
#
{
  inputs,
  nixpkgs,
  overlays,
  ...
}: let
  # =========================== Helpers ============================ #

  # Get all files in a directory as absolute paths
  filesIn = dir:
    map (fname: dir + "/${fname}")
    (builtins.attrNames (builtins.readDir dir));

  # Get all subdirectories in a directory
  dirsIn = dir:
    nixpkgs.lib.filterAttrs (name: value: value == "directory")
    (builtins.readDir dir);

  # Get filename without extension
  fileNameOf = path:
    (builtins.head (builtins.split "\\." (baseNameOf path)));

  # ========================== Extenders =========================== #

  # Evaluates a module and extends its options/config
  # Used by the bundle/feature system to auto-create enable options
  extendModule = {path, ...} @ args: {pkgs, ...} @ margs: let
    eval =
      if (builtins.isString path) || (builtins.isPath path)
      then import path margs
      else path margs;
    evalNoImports = builtins.removeAttrs eval ["imports" "options"];

    extra =
      if (builtins.hasAttr "extraOptions" args) ||
         (builtins.hasAttr "extraConfig" args)
      then [
        ({...}: {
          options = args.extraOptions or {};
          config = args.extraConfig or {};
        })
      ]
      else [];
  in {
    imports =
      (eval.imports or [])
      ++ extra;

    options =
      if builtins.hasAttr "optionsExtension" args
      then (args.optionsExtension (eval.options or {}))
      else (eval.options or {});

    config =
      if builtins.hasAttr "configExtension" args
      then (args.configExtension (eval.config or evalNoImports))
      else (eval.config or evalNoImports);
  };

  # Applies extendModule to all modules in a list
  # modules can be file paths or taken from "filesIn"
  extendModules = extension: modules:
    map
    (f: let
      name = fileNameOf f;
    in (extendModule ((extension name) // {path = f;})))
    modules;
in {
  inherit filesIn dirsIn fileNameOf extendModule extendModules;
}
