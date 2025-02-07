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
        sha256 = "sha256-0yJdXP61HmQJz6QTxeJlHNVMtI1Wy+yVMLcGny7P9VU=";
      }
      + "/files";
    recursive = true;
  };
}
