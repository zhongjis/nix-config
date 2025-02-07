{inputs, ...}: {
  imports = [
    ../../stylix_common.nix
    inputs.stylix.homeManagerModules.stylix
  ];

  stylix.targets = {
    waybar.enable = false;
    neovim.enable = false;
    swaync.enable = false;
    hyprlock.enable = false;
    kde.enable = false;
  };
}
