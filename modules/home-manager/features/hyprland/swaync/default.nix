{
  lib,
  isDarwin,
  ...
}: {
  xdg.configFile."swaync/icons".source = ./icons;
  xdg.configFile."swaync/images".source = ./images;

  services.swaync = {
    enable =
      if isDarwin
      then false
      else true;
    settings = lib.importJSON ./config.json;
    style = ''
      ${builtins.readFile ./style.css}
    '';
  };
}
