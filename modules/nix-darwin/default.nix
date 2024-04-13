{ lib, ... }:
{
  imports = [
    ./skhd
    ./yabai
  ];

  skhd.enable = lib.mkDefault true;
  yabai.enable = lib.mkDefault true;
}
