# Flake-Parts Home Manager Helper
#
# Provides myFlake.home.createProfile for creating Home Manager configurations.
# Replaces the old mkHome function from lib/default.nix.
#
{ inputs, config, lib, ... }: {
  options = {
    myFlake.home = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Home Manager configuration options";
    };
  };

  config = {
    myFlake.home.createProfile = profileName: args:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = args.pkgs or
          (inputs.nixpkgs.legacyPackages.${args.system or "x86_64-linux"});
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ../hosts/${args.host}/home.nix
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeModules.stylix
        ] ++ (args.modules or []);
      };
  };
}
