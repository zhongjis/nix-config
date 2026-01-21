{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Bundles
    ./bundle-linux.nix
    ./bundle-hyprland.nix

    # Hyprland ecosystem
    ./hyprland
    ./waybar
    ./rofi
    ./hyprlock

    # Wayland desktop components
    ./hyprpaper.nix
    ./hyprsunset.nix
    ./hypridle.nix
    ./swaync
    ./dunst.nix

    # Linux system services
    ./pipewire-noise-cancelling-input.nix
    ./distrobox.nix
  ];
}
