{
  lib,
  config,
  ...
}: {
  imports = [
    # ./hyprland
    # ./waybar
    # ./rofi
    ./xremap
  ];

  options = {
    linux-hm-modules.enable =
      lib.mkEnableOption "enable Linux specific hm modules";
  };

  config = lib.mkIf config.linux-hm-modules.enable {
    # hyprland.enable = lib.mkDefault false;
    # waybar.enable = lib.mkDefault false;
    # rofi.enable = lib.mkDefault false;
    xremap.enable = lib.mkDefault true;
  };
}
