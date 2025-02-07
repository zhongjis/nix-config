{
  pkgs,
  config,
  inputs,
  currentSystem,
  ...
}: {
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
        owner = "adi1090x";
        repo = "rofi";
        rev = "master";
        sha256 = "sha256-TVZ7oTdgZ6d9JaGGa6kVkK7FMjNeuhVTPNj2d7zRWzM=";
      }
      + "/files";
    recursive = true;
  };
}
