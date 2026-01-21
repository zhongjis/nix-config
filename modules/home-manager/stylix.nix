{lib, ...}: {
  imports = [
    ../shared/stylix_common.nix
  ];

  stylix.targets = {
    waybar.enable = false;
    # neovim.enable = false;
    swaync.enable = false;
    hyprlock.enable = false;
    # kde.enable = false;
    rofi.enable = false;
    zen-browser = {
      # enable = false;
      profileNames = lib.singleton "default";
    };
  };
}
