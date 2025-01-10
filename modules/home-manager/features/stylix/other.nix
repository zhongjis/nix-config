{pkgs, ...}: let
in {
  # stylix.cursor = {
  #   name = "Bibata-Modern-Ice";
  #   package = pkgs.bibata-cursors;
  #   size = 32;
  # };

  stylix.cursor = {
    name = "catppuccin-mocha-light-cursors";
    package = pkgs.catppuccin-cursors.mochaLight;
    size = 32;
  };

  stylix.targets = {
    waybar.enable = false;
    neovim.enable = false;
    swaync.enable = false;
    hyprlock.enable = false;
    kde.enable = false;
  };
}
