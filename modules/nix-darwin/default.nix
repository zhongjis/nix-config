{lib, ...}: {
  imports = [
    ./skhd
    ./yabai
    ./sketchybar
    ./aerospace
  ];

  skhd.enable = lib.mkDefault true;
  yabai.enable = lib.mkDefault true;
  aerospace.enable = lib.mkDefault false;
  sketchybar.enable = lib.mkDefault true;
}
