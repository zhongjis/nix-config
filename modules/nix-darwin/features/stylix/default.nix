{inputs, ...}: {
  imports = [
    ./common.nix
    ./other.nix
    inputs.stylix.darwinModules.stylix
  ];
}
