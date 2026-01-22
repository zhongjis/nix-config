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
    plugins = with pkgs; [
      rofi-calc
    ];
    theme = "~/.config/rofi/themes/bibjaw_mini.rasi";
  };

  home.file.".config/rofi/themes" = {
    source =
      pkgs.fetchFromGitHub {
        owner = "bibjaw99";
        repo = "workstation";
        rev = "master";
        sha256 = "sha256-T43T13vQBHNgEonGN+nodN8Bi1+dEaiGLgYnGJZDnyM=";
      }
      + "/.config/rofi/themes";
    recursive = true;
  };

  home.file.".config/rofi/powermenu.rasi" = {
    source =
      pkgs.fetchFromGitHub {
        owner = "bibjaw99";
        repo = "workstation";
        rev = "master";
        sha256 = "sha256-T43T13vQBHNgEonGN+nodN8Bi1+dEaiGLgYnGJZDnyM=";
      }
      + "/.config/rofi/powermenu.rasi";
    recursive = true;
  };
}
