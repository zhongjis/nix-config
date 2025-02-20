{pkgs, ...}: {
  home.packages = with pkgs; [
    (writeScriptBin "rofi-toggle" ''
      ${builtins.readFile ./rofi-toggle.sh}
    '')
    (writeScriptBin "rofi-toggle-cliphist" ''
      ${builtins.readFile ./rofi-toggle-cliphist.sh}
    '')
    (writeScriptBin "rofi-toggle-power-menu" ''
      ${builtins.readFile ./rofi-toggle-power-menu.sh}
    '')

    # fonts
    icomoon-feather
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
    dejavu_fonts
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = with pkgs; [
      rofi-power-menu
      rofi-calc
    ];
  };

  home.file.".config/rofi" = {
    source =
      pkgs.fetchFromGitHub {
        owner = "zhongjis";
        repo = "rofi";
        rev = "master";
        sha256 = "sha256-e2G3iw4w1KCBbCvzKIomQWfJFGm7fRzfTILz5at9bv4=";
      }
      + "/files";
    recursive = true;
  };

  home.file.".local/share/rofi/themes" = {
    source =
      pkgs.fetchFromGitHub {
        owner = "newmanls";
        repo = "rofi-themes-collection";
        rev = "master";
        sha256 = "sha256-pHPhqbRFNhs1Se2x/EhVe8Ggegt7/r9UZRocHlIUZKY=";
      }
      + "/themes";
    recursive = true;
  };
}
