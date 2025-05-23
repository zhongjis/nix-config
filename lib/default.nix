{
  inputs,
  nixpkgs,
  overlays,
  ...
}: let
  myLib = (import ./default.nix) {inherit inputs nixpkgs overlays;};
  outputs = inputs.self.outputs;
in rec {
  # ================================================================ #
  # =                            My Lib                            = #
  # ================================================================ #

  # ======================= Package Helpers ======================== #

  pkgsFor = sys: inputs.nixpkgs.legacyPackages.${sys};

  # ========================== Buildables ========================== #

  mkSystem = hostName: {
    system,
    user,
    hardware ? "",
    darwin ? false,
  }: let
    isDarwin = darwin;

    hostConfiguration = ../hosts/${hostName}/configuration.nix;
    systemFunc =
      if isDarwin
      then inputs.nix-darwin.lib.darwinSystem
      else nixpkgs.lib.nixosSystem;
    hardwareConfiguration =
      if hardware != ""
      then inputs.nixos-hardware.nixosModules.${hardware}
      else {};
    sopsModule =
      if isDarwin
      then inputs.sops-nix.darwinModules.sops
      else inputs.sops-nix.nixosModules.sops;
  in
    systemFunc {
      system = system;
      specialArgs = {
        inherit inputs outputs myLib;
      };

      modules = [
        hostConfiguration
        hardwareConfiguration
        sopsModule

        {
          nixpkgs.overlays = [
            inputs.nixpkgs-terraform.overlays.default
            overlays.modifications
            overlays.stable-packages
          ];
          nixpkgs.config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };
        }

        {
          config._module.args = {
            currentSystem = system;
            currentSystemName = hostName;
            currentSystemUser = user;
            inputs = inputs;
            isDarwin = darwin;
          };
        }
      ];
    };

  mkHome = systemName: {
    system,
    darwin ? false,
  }: let
    currentSystem = system;
    currentSystemName = systemName;
    isDarwin = darwin;

    homeConfiguration = ../hosts/${systemName}/home.nix;
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          inputs.nixpkgs-terraform.overlays.default
          overlays.modifications
          overlays.stable-packages
        ];
      };

      extraSpecialArgs = {
        inherit
          inputs
          outputs
          myLib
          currentSystem
          currentSystemName
          isDarwin
          ;
      };

      modules = [
        homeConfiguration
        inputs.sops-nix.homeManagerModules.sops
      ];
    };

  # =========================== Helpers ============================ #

  filesIn = dir: (map (fname: dir + "/${fname}")
    (builtins.attrNames (builtins.readDir dir)));

  dirsIn = dir:
    inputs.nixpkgs.lib.filterAttrs (name: value: value == "directory")
    (builtins.readDir dir);

  fileNameOf = path: (builtins.head (builtins.split "\\." (baseNameOf path)));

  # ========================== Extenders =========================== #

  # Evaluates nixos/home-manager module and extends it's options / config
  extendModule = {path, ...} @ args: {pkgs, ...} @ margs: let
    eval =
      if (builtins.isString path) || (builtins.isPath path)
      then import path margs
      else path margs;
    evalNoImports = builtins.removeAttrs eval ["imports" "options"];

    extra =
      if (builtins.hasAttr "extraOptions" args) || (builtins.hasAttr "extraConfig" args)
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

  # Applies extendModules to all modules
  # modules can be defined in the same way
  # as regular imports, or taken from "filesIn"
  extendModules = extension: modules:
    map
    (f: let
      name = fileNameOf f;
    in (extendModule ((extension name) // {path = f;})))
    modules;

  # ============================ Shell ============================= #
  forAllSystems = pkgs:
    inputs.nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ]
    (system: pkgs inputs.nixpkgs.legacyPackages.${system});
}
