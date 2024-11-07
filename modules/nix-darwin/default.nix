{lib, ...}: {
  imports = [
    ./skhd
    ./yabai
    ./sketchybar
    ./aerospace
  ];

  skhd.enable = lib.mkDefault false;
  yabai.enable = lib.mkDefault false;
  aerospace.enable = lib.mkDefault true;
  sketchybar.enable = lib.mkDefault false;
}
