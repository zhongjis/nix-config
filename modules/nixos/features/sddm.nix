{
  pkgs,
  config,
  lib,
  ...
}: {
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # package = lib.mkForce pkgs.kdePackages.sddm;
    # theme = lib.mkForce "catppuccin-mocha";
  };

  # environment.systemPackages = [
  #   (
  #     pkgs.catppuccin-sddm.override {
  #       flavor = "mocha";
  #       font = "Noto Sans";
  #       fontSize = "12";
  #       background = "${config.stylix.image}";
  #       loginBackground = true;
  #     }
  #   )
  # ];
}
