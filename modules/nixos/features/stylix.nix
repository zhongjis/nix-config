{inputs, ...}: {
  imports = [
    ../../shared/stylix_common.nix
    inputs.stylix.nixosModules.stylix
  ];
  stylix.targets = {
    plymouth.enable = false;
  };
}
