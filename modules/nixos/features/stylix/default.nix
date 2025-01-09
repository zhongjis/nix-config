{inputs, ...}: {
  imports = [
    ./common.nix
    ./other.nix
    inputs.stylix.nixosModules.stylix
  ];
}
