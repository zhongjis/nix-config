{inputs, ...}: {
  imports = [
    ../../stylix_common.nix
    inputs.stylix.homeManagerModules.stylix
  ];

  stylix.targets = {
    yazi.enable = true;
    ghostty.enable = true;
  };
}
