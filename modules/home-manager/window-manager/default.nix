{ lib, config, ... }:

{
  imports = [
    ./hyprland
    ./waybar
    ./rofi
    ./xremap.nix
  ];

  options = {
    window-manager.enable =
      lib.mkEnableOption "enable neovim";
  };

  config = lib.mkIf config.window-manager.enable {
    hyprland.enable = lib.mkDefault true;
    waybar.enable = lib.mkDefault true;
    rofi.enable = lib.mkDefault true;
    xremap.enable = lib.mkDefault true;
  };
}
