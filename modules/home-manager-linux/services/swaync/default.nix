{lib, ...}: {
  xdg.configFile."swaync/icons".source = ./icons;
  xdg.configFile."swaync/images".source = ./images;

  services.swaync = {
    enable = true;
    settings = lib.importJSON ./config.json;
    style = ''
      ${builtins.readFile ./style.css}
    '';
  };
}
