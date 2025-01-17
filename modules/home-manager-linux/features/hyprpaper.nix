{pkgs, ...}: let
  astronaunt = pkgs.fetchurl {
    url = "https://i.redd.it/mvev8aelh7zc1.png";
    hash = "sha256-lJjIq+3140a5OkNy/FAEOCoCcvQqOi73GWJGwR2zT9w";
  };
  saturn = pkgs.fetchurl {
    url = "https://github.com/DragonDev07/Wallpapers/blob/main/Catppuccin/Mocha/CatppuccinMocha-Saturn.png?raw=true";
    hash = "sha256-m4Nt+03H2YN7tQnzFt6KsgMh1v1excmJsaDL8bGBCxs=";
  };
  Interstellar-black-hole = pkgs.fetchurl {
    url = "https://i.redd.it/s54yr8groykd1.png";
    hash = "sha256-1lNAac39z8EfdgozvxH9SA8/ysZpOUlay3QzmbVOZ3A=";
  };
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      preload = [
        (builtins.toString saturn)
        (builtins.toString Interstellar-black-hole)
      ];

      wallpaper = [
        ",${builtins.toString saturn}"
        ",${builtins.toString Interstellar-black-hole}"
      ];
    };
  };
}
