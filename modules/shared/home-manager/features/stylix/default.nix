{inputs, ...}: {
  imports = [
    ./common.nix
    ./other.nix
    inputs.stylix.homeManagerModules.stylix
  ];
}
