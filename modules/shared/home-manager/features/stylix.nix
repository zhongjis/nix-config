{inputs, ...}: {
  imports = [
    ../../stylix_common.nix
  ];

  stylix.targets = {
    waybar.enable = false;
    # neovim.enable = false;
    swaync.enable = false;
    hyprlock.enable = false;
    kde.enable = false;
    rofi.enable = false;
  };
}
