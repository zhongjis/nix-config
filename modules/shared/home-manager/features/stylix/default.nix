{inputs, ...}: {
  imports = [
    ./other.nix
    ../../../shared/stylix/common.nix
    inputs.stylix.homeManagerModules.stylix
  ];
}
