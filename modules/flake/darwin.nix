# Flake-Parts Darwin Helper
#
# Provides myFlake.darwin.createHost for creating Darwin configurations.
# Replaces the old mkSystem (with darwin=true) from lib/default.nix.
#
{ inputs, config, lib, ... }: {
  options = {
    myFlake.darwin = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Darwin configuration options";
    };
  };

  config = {
    myFlake.darwin.createHost = hostName: args:
      inputs.nix-darwin.lib.darwinSystem (args // {
        system = args.system or "aarch64-darwin";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ../hosts/${hostName}/configuration.nix
          inputs.sops-nix.darwinModules.sops
        ] ++ (args.modules or []);
      });
  };
}
