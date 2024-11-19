{
  lib,
  config,
  ...
}: {
  options = {
    swaync.enable =
      lib.mkEnableOption "enable sway notification center";
  };

  config = lib.mkIf config.swaync.enable {
    xdg.configFile."swaync/config.json".source = ./config.json;
    xdg.configFile."swaync/icons".source = ./icons;
    xdg.configFile."swaync/images".source = ./images;

    services.swaync = {
      enable = true;
      style = ''
        ${builtins.readFile ./style.css}
      '';
    };
  };
}
