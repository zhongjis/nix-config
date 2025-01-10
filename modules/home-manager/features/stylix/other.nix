{pkgs, ...}: let
in {
  stylix.targets = {
    waybar.enable = false;
    neovim.enable = false;
    swaync.enable = false;
    hyprlock.enable = false;
    kde.enable = false;
  };
}
