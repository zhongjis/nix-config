{lib, ...}: {
  imports = [
    ./alacritty.nix
    ./kitty.nix
  ];

  alacritty.enable = lib.mkDefault false;
  kitty.enable = lib.mkDefault true;
}
