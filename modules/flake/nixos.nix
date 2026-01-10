# Flake-Parts NixOS Helper
#
# Provides myFlake.nixos.createHost for creating NixOS configurations.
# Replaces the old mkSystem function from lib/default.nix.
#
{ inputs, config, lib, ... }: {
  options = {
    myFlake.nixos = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "NixOS configuration options";
    };
  };

  config = {
    myFlake.nixos.createHost = hostName: args:
      inputs.nixpkgs.lib.nixosSystem (args // {
        system = args.system or "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ../hosts/${hostName}/configuration.nix
          inputs.determinate.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          inputs.stylix.nixosModules.stylix
        ] ++ (args.modules or []);
      });
  };
}
