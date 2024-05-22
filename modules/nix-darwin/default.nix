{lib, ...}: {
  imports = [
    ./skhd
    ./yabai
    ./sketchybar.nix
  ];

  skhd.enable = lib.mkDefault true;
  yabai.enable = lib.mkDefault true;
  sketchybar.enable = lib.mkDefault false;
}
