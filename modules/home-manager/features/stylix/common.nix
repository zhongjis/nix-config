{pkgs, ...}: let
  astronaunt = pkgs.fetchurl {
    url = "https://i.redd.it/mvev8aelh7zc1.png";
    hash = "sha256-lJjIq+3140a5OkNy/FAEOCoCcvQqOi73GWJGwR2zT9w";
  };
in {
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    image = astronaunt;

    fonts = {
      monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
  };

  stylix.cursor = {
    name = "catppuccin-mocha-light-cursors";
    package = pkgs.catppuccin-cursors.mochaLight;
    size = 32;
  };

  stylix.opacity = {
    applications = 1.0;
    terminal = 0.85;
    desktop = 1.0;
    popups = 1.0;
  };
}
