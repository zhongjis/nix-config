{
  lib,
  config,
  ...
}: {
  imports = [
    ./xremap
    ./zshen-hyprland
  ];

  options = {
    linux-hm-modules.enable =
      lib.mkEnableOption "enable Linux specific hm modules";
  };

  config = lib.mkIf config.linux-hm-modules.enable {
    zshen-hyprland.enable = lib.mkDefault true;
    xremap.enable = lib.mkDefault true;
  };
}
