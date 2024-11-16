{
  lib,
  config,
  ...
}: {
  imports = [
    ./waybar
    ./rofi
    ./xremap
  ];

  options = {
    linux-hm-modules.enable =
      lib.mkEnableOption "enable Linux specific hm modules";
  };

  config = lib.mkIf config.linux-hm-modules.enable {
    waybar.enable = lib.mkDefault true;
    rofi.enable = lib.mkDefault true;
    xremap.enable = lib.mkDefault true;
  };
}
