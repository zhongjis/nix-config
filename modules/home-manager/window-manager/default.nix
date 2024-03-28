let
    hyprland = import ./hyprland.nix;
    waybar = import ./waybar.nix;
    rofi = import ./rofi.nix;
in
{
    windowManager.rofi = rofi;
}

