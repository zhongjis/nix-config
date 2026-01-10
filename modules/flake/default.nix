# Flake-Parts Main Module
#
# Imports and configures flake-parts modules for nix-config.
# Provides centralized configuration for hosts and home profiles.
#
{ inputs, config, lib, ... }: {
  imports = [
    ./nixos.nix
    ./darwin.nix
    ./home.nix
  ];

  options = {
    myFlake = {
      hosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["framework-16" "mac-m1-max"];
        description = "List of host names";
      };

      homeProfiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "zshen@framework-16"
          "zshen@Zs-MacBook-Pro"
        ];
        description = "List of home profile names";
      };
    };
  };
}
