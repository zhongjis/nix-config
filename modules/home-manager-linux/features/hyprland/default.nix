{
  pkgs,
  config,
  ...
}: let
in {
  imports = [
    ./gtk.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpaper.nix
  ];

  myHomeManagerLinux.rofi.enable = true;
  myHomeManagerLinux.swaync.enable = true;
  myHomeManagerLinux.waybar.enable = true;
  myHomeManagerLinux.wlogout.enable = true;

  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      ${builtins.readFile ./hyprland.conf}
    '';
  };

  home.pointerCursor = {
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };
}
